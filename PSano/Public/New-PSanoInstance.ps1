function Edit-TextFile {
    [CmdletBinding(DefaultParameterSetName="LocalFile")]
    param (
        [Parameter(Mandatory,ParameterSetName="LocalFile" ,Position=0)]
        [Parameter(Mandatory,ParameterSetName="RemoteFile" ,Position=0)]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            if ($FakeBoundParams.Session){
                return (Invoke-Command -Session $FakeBoundParams.Session -ScriptBlock {
                    Param($word)
                    (Get-Item "$Word*").Fullname
                } -ArgumentList ($WordToComplete -replace '"')).foreach({
                    if ($_ -match '\s') { "`"$_`"" } else { $_ }
                })
                #above line is a bit long, but we strip and add double quotes on this side
                # so less is done by the remote server. The less done on remote the better,
                # but also the less xfered the better.
            }
            return
        })]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(ParameterSetName="LocalFile")]
        [switch]
        $LocalFile,

        [Parameter(Mandatory,ParameterSetName="RemoteFile",Position=1)]
        [System.Management.Automation.Runspaces.PSSession]$Session,

        [parameter(ParameterSetName="LocalFile")]
        [parameter(ParameterSetName="RemoteFile")]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            $GetContentCommand = Get-Command Get-Content
            if ($GetContentCommand.Parameters.Encoding.ParameterType.fullName -eq 'Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding'){
                # 5.1
                return ([enum]::GetNames([Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding])).Where({$_ -like "$wordToComplete*"})
            } elseif ($GetContentCommand.Parameters.Encoding.ParameterType -eq [System.Text.Encoding]) {
                #6+
                return [System.Text.Encoding]::GetEncodings().Name.Where({$_ -like "$wordToComplete*"})
            }
            
        })]
        [object]$Encoding,

        [Parameter(Mandatory,ParameterSetName="Variable",Position=0)]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            return (Get-Variable -Scope Global -Name "$WordToComplete*").where({ 
                # not a constant or readonly
                -not (
                    $_.Options -band ([System.Management.Automation.ScopedItemOptions]::Constant -bor [System.Management.Automation.ScopedItemOptions]::ReadOnly )
                )
             }).Name
        })]
        [string]$Variable,

        [Parameter(Mandatory=0,ParameterSetName="Variable",Position=1)]
        [ValidateSet("String","Json")]
        [string]$EditMode = "String",

        [Parameter(Mandatory=0,ParameterSetName="Variable",Position=2)]
        [int]$Depth,

        [Parameter(Mandatory,ParameterSetName="Function",Position=0)]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            return (Get-ChildItem -Path "function:$WordToComplete*").Name | Sort-Object
        })]
        [string]$Function,

        [Parameter(Mandatory,ParameterSetName="Clipboard",Position=0)]
        [switch]$Clipboard
    )
    
    begin {
        # boiler plate for terminal.gui
        [Terminal.Gui.Application]::Init()
    }
    
    process {

        if (-not $Encoding){
            $Encoding = "Default"
        } else {
            $GetContentCommand = Get-Command Get-Content
            # have to use string for this comparison as ps7+ does not have this
            # class and the comparison would cause an exception instead.
            if ($GetContentCommand.Parameters.Encoding.ParameterType.fullName -eq 'Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding'){
                # 5.1
                $Encoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$Encoding
            } elseif ($GetContentCommand.Parameters.Encoding.ParameterType -eq [System.Text.Encoding]) {
                #6+
                $Encoding = [System.Text.Encoding]::GetEncoding($Encoding)
            }
        }
        $File = switch ($PSCmdlet.ParameterSetName) {
            Default { 
                if ($LocalFile) {
                    [PSanoTextFile]::new($Path, $Encoding)
                } else {
                    # try to use auto resolve.
                    $temp = [PSanoFile]::findReaderForPath($Path)
                    if (-not $temp) {
                        Write-Error -Message "Unable to determine path type for $Path, please use the specific parameters or -Localfile for files." -ErrorId Psano.NoCompatibleReaders -Category InvalidType -ErrorAction Stop
                    }
                    if ($temp.Encoding) { $temp.Encoding = $Encoding }
                    $temp
                }
            }
            "LocalFile" {
                if ($LocalFile) {
                    [PSanoTextFile]::new($Path, $Encoding)
                } else {
                    # try to use auto resolve.
                    $temp = [PSanoFile]::findReaderForPath($Path)
                    if (-not $temp) {
                        Write-Error -Message "Unable to determine path type for $Path, please use the specific parameters or -Localfile for files." -ErrorId Psano.NoCompatibleReaders -Category InvalidType -ErrorAction Stop
                    }
                    if ($temp.Encoding) { $temp.Encoding = $Encoding }
                    $temp
                } 
            }
            "RemoteFile" {
                [PSanoFileInSession]::new($Path,$Session,$Encoding)
            }
            "Variable" {
                switch ($EditMode) {
                    "Json"   { 
                        if ($Depth) {
                            [PSanoJsonVariable]::new($Variable,'Global',$Depth)
                        } else {
                            [PSanoJsonVariable]::new($Variable)
                        }
                    }
                    "String" { [PSanoVariable]::new($Variable) }
                    Default  { [PSanoVariable]::new($Variable) }
                }
            }
            "Function" {
                [PSanoFunction]::new($Function)
            }
            "Clipboard" {
                [PSanoClipboard]::new()
            }
        }

        $GlobalKeyActions = @(
            [Terminal.Gui.StatusItem]::new(
                [Terminal.Gui.Key]'ctrlmask, o',
                'C+o : Save',
                { 
                    try {    
                        # editing pane uses nstack's ustrings, explicit to string needed here
                        $File.writeFileContents( ($editingPane.Text.toString()) )
                        $TopWindow.SetTitleSuffix("File Saved. " + (get-date).tostring())
                    } catch {
                        $TopWindow.SetTitleSuffix( ([string]$_.categoryinfo.category + ': ' + [string]$_.Exception.Message) )
                    }
                }
            )
            # k  or cut is closest to "cutline"
            [Terminal.Gui.StatusItem]::new(
                [Terminal.Gui.Key]'ctrlmask, k',
                'C+k : CutLine',
                {
                    $line = $editingPane.RemoveLineAt($editingPane.CurrentRow)

                    if (-not [string]::IsNullOrEmpty($line)) {
                        Set-Clipboard -Value $line
                    }
                }
            )
            # U or uncut is the closest to "paste"
            [Terminal.Gui.StatusItem]::new(
                [Terminal.Gui.Key]'ctrlmask, u',
                'C+U : PasteLine',
                {
                    $Clip = Get-Clipboard -raw
                    $editingPane.InsertLineAt($editingPane.CurrentRow,$Clip)
                }
            )
            # Copy all lines to clipboard
            [Terminal.Gui.StatusItem]::new(
                [Terminal.Gui.Key]'ctrlmask, a',
                'C+a : CopyAll',
                {
                    [string]$Contents = $editingPane.Text.toString()
                    try {
                        $Contents | Set-Clipboard -ErrorAction Stop
                    } catch {}
                }
            )
        )

        <#
        The return here should kick us back to the console. The error would
        appear after the last draw, the repeat of the finally block should
        mean it appears *below* the ghost interface.
        #>
        try {
            $LoadedText = $File.readFileContents() -join "`n"
        } catch {
            throw $_
            return
        }


        # "main loop"

        try {

            # setup a window
            $TopWindow = [PSWindow]::new()
            $TopStatus = [BasicStatus]::new()

            $GlobalKeyActions | ForEach-Object {
                $TopStatus.AdditemAt(
                    $TopStatus.Items.Count,$_
                )
            }

            $width = [Terminal.Gui.Dim]::Fill(0)
            $height = [Terminal.Gui.Dim]::Fill(1)
            $editingPane = [PSanoTextEdit]::new("",$width,$height)

            $TopWindow.SetTitleSuffix($File.FullPath)
            $editingPane.Text = $LoadedText

            $TopWindow.Add($editingPane)
            $TopWindow.Add($TopStatus)

            # start program
            [Terminal.Gui.Application]::Run($TopWindow)

        } finally {
            [Terminal.Gui.Application]::Shutdown()
        }

    }
    
    end {
    }
}