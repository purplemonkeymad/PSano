function Edit-TextFile {
    [CmdletBinding(DefaultParameterSetName="LocalFile")]
    param (
        [Parameter(Mandatory,ParameterSetName="LocalFile" ,Position=0)]
        [Parameter(Mandatory,ParameterSetName="RemoteFile" ,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
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
        [string]$Variable,
        [Parameter(Mandatory=0,ParameterSetName="Variable",Position=1)]
        [ValidateSet("String","Json")]
        [string]$EditMode = "String",
        [Parameter(Mandatory=0,ParameterSetName="Variable",Position=2)]
        [int]$Depth,
        [Parameter(Mandatory,ParameterSetName="Function",Position=0)]
        [string]$Function,
        [Parameter(Mandatory,ParameterSetName="Clipboard",Position=0)]
        [switch]$Clipboard
    )
    
    begin {
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
            Default { [psanoFile]::new($Path, $Encoding) }
            "LocalFile" { [psanoFile]::new($Path, $Encoding) }
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

        $script:ShouldReadNextKey = $true

        $script:TextForm = [TextUIForm]::new()
        $script:Header = [HeaderPanel]::new("PSano")
        $TextForm.ChildPanelList.add($script:Header)

        # header panel is 1 line
        # menu panel is 2 lines
        # total 3 lines

        $bufferheight = [console]::WindowHeight - 3

        $Buffer = [BufferPanel]::new($bufferheight)
        $buffer.SetFocus()
        $script:TextForm.ChildPanelList.Add($Buffer)

        $GlobalKeyActions = @(
            # quit option, this should break the read key loop and let the function exit.
            [MenuHandle]::new([ConsoleKey]::X,[ConsoleModifiers]::Control,{
                $script:ShouldReadNextKey = $false
            },"Quit")
            [MenuHandle]::new([ConsoleKey]::O,[ConsoleModifiers]::Control,{
                try {
                    $Script:Header.Notice = "Saving..."
                    $script:Header.Redraw()

                    $File.writeFileContents($script:BufferEditor.GetBufferLines())

                    $script:Header.Notice = "Saved."
                    $script:Header.Redraw()
                } catch {
                    $script:Header.Notice = [string]$_.categoryinfo.category + ': ' + [string]$_.Exception.Message
                    $script:Header.Redraw()
                }
            },"Save")
            # k  or cut is closest to "cutline"
            [MenuHandle]::new([consoleKey]::K,[consoleModifiers]::Control,{
                $line = $script:BufferEditor.popCurrentLine()
                if (-not [string]::IsNullOrEmpty($line)) {
                    Set-Clipboard -Value $line
                }
            },"CutLine")
            # U or uncut is the closest to "paste"
            [MenuHandle]::new([ConsoleKey]::U,[ConsoleModifiers]::Control,{
                [string[]]$Clip = Get-Clipboard
                if ($clip.count -gt 0) {
                    # if there is more that one line, we need to paste
                    # the last line first so that the lines before
                    # appear above.

                    [array]::Reverse($clip)

                    $Clip.foreach({
                        $script:BufferEditor.insertLine($_)
                    })
                } else {
                    # -eq 0
                    $script:BufferEditor.insertLine("")
                }
            },"PasteLine")
<#
            [MenuHandle]::new([System.ConsoleKey]::R,[System.ConsoleModifiers]::Control,{
                $script:TextForm.Redraw()
            },"Refresh Screen")
#>
        )

        $script:TextForm.ChildPanelList.Add([MenuPanel]::new($GlobalKeyActions))

        # key handles

        $MainKeyListener = [KeyHandler]::new()
        $GlobalKeyActions | ForEach-Object { $MainKeyListener.Add( $_) }

        #editor object

        $script:BufferEditor = [BufferEditor]::new($Buffer)

        # The default action should be hanled by the editor pane. As if it is
        #  not a menu key, then it's probably a charater.

        $MainKeyListener.Default = {
            $script:BufferEditor.HandleKey($_)
        }

        <#
        We need to get all this information before the first draw, otherwise
        we end up having the wrong exit location by the final draw position.
        #>
        $ExitCursorTop = [Console]::CursorTop + [console]::WindowHeight
        # extend buffer size now so we can be sure exit location is correct:
        if ([console]::BufferHeight -lt $ExitCursorTop){
            [console]::BufferHeight = $ExitCursorTop + 1
        }
        $script:TextForm.Draw()

        $filename = $File.FullPath | Split-Path -Leaf
        $script:Header.Text = "PSano : $filename"
        # need to pull from remote session 
        $script:Header.Notice = "Loading file..."
        $script:Header.Redraw()

        <#
        The return here should kick us back to the console. The error would
        appear after the last draw, the repeat of the finally block should
        mean it appears *below* the ghost interface.
        #>
        try {
            $BufferEditor.LoadBuffer( $File.readFileContents() )
        } catch {

            #clean up if we are inturrpted.
            [console]::CursorVisible = $true
            [console]::CursorTop = $ExitCursorTop
            [console]::CursorLeft = 0

            throw $_
            return
        }

        $script:Header.Notice = $null
        $script:Header.Redraw()

        # "main loop"

        try{
            while ($script:ShouldReadNextKey){
                $script:TextForm.Draw()
                $script:Header.Notice = $null
                $script:Header.Redraw()
                $Buffer.UpdateCursor()
                $MainKeyListener.ReadKey()
            }
        } finally {
            #clean up if we are inturrpted.
            [console]::CursorVisible = $true
            [console]::CursorTop = $ExitCursorTop
            [console]::CursorLeft = 0
        }
    }
    
    end {
    }
}