function Edit-TextFile {
    [CmdletBinding(DefaultParameterSetName="LocalFile")]
    param (
        [Parameter(Mandatory,ParameterSetName="LocalFile" ,Position=0)]
        [Parameter(Mandatory,ParameterSetName="RemoteFile" ,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory,ParameterSetName="RemoteFile",Position=1)]
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [Parameter(Mandatory,ParameterSetName="Variable",Position=0)]
        [string]$Variable
    )
    
    begin {
    }
    
    process {

        $File = switch ($PSCmdlet.ParameterSetName) {
            Default { [psanoFile]$path }
            "LocalFile" { [psanoFile]$path }
            "RemoteFile" {
                [PSanoFileInSession]::new($Path,$Session)
            }
            "Variable" {
                [PSanoVariable]::new($Variable)
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

                    $File.writeFileContents($script:BufferEditor.GetBuffer())

                    $script:Header.Notice = "Saved."
                    $script:Header.Redraw()
                } catch {
                    $script:Header.Notice = $_.Exception.Message
                    $script:Header.Redraw()
                }
            },"Save")
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

        # setup buffer to handle keys

        $MainKeyListener.Default = {
            $script:BufferEditor.HandleKey($_)
        }

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

        try {
            $BufferEditor.LoadBuffer( $File.readFileContents() )
        } catch {
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