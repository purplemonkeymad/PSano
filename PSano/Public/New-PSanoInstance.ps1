function Edit-TextFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    
    begin {
    }
    
    process {

        $script:File = [psanoFile]$path

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
                    if ($script:File.Session){
                        Invoke-Command -Session $script:File.Session -ScriptBlock {
                            Param($Path,$Content)
                            Set-Content -Path $Path -Value $Content 
                        } -ArgumentList $script:File.Path,$script:BufferEditor.GetBuffer()
                    } else {
                        $script:File.writeFileContents($script:BufferEditor.GetBuffer())
                    }
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

        $filename = $script:File.FullPath | Split-Path -Leaf
        $script:Header.Text = "PSano : $filename"
        # need to pull from remote session 
        $script:Header.Notice = "Loading file..."
        $script:Header.Redraw()
        if ($script:File.Session){
            try {
                $Content = Invoke-Command -Session $script:File.Session -ScriptBlock {
                    Param($Path)
                    # we are just going to support litterals for now.
                    Get-Content -LiteralPath $path
                } -ArgumentList $script:File.Path
                if ($content.count -eq 0){
                    $Content = [string[]]""
                }
                $BufferEditor.LoadBuffer( [string[]]$Content )
            } catch {
                throw $_
                return
            }
        } elseif (Test-Path -Path $script:File.FullPath){
            try {
                $BufferEditor.LoadBuffer( $script:File.readFileContents() )
            } catch {
                throw $_
                return
            }
        } else {
            $BufferEditor.LoadBuffer( [string[]]"" )
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