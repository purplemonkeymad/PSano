function Edit-TextFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    
    begin {
    }
    
    process {

        $script:File = $Path

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
                    $script:BufferEditor.GetBuffer() | Set-Content -Path $script:File -ErrorAction Stop
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

        $filename = $path | Split-Path -Leaf
        $script:Header.Text = "PSano : $filename"
        if (Test-Path -Path $path){
            try {
                $BufferEditor.LoadBuffer( (Get-Content $path) )
            } catch {
                throw $_
                return
            }
        } else {
            $BufferEditor.LoadBuffer( [string[]]"" )
        }

        # "main loop"
        $ExitCursorTop = [Console]::CursorTop + [console]::WindowHeight
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