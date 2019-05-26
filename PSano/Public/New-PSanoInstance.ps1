function New-PSanoInstance {
    [CmdletBinding()]
    param (
        [string]$path
    )
    
    begin {
    }
    
    process {

        $script:ShouldReadNextKey = $true

        $TextForm = [TextUIForm]::new()
        $Header = [HeaderPanel]::new("PSano")
        $TextForm.ChildPanelList.add($Header)

        # header panel is 1 line
        # menu panel is 2 lines
        # total 3 lines

        $bufferheight = [console]::WindowHeight - 3

        $Buffer = [BufferPanel]::new($bufferheight)
        $buffer.SetFocus()
        $TextForm.ChildPanelList.Add($Buffer)

        $GlobalKeyActions = @(
            # quit option, this should break the read key loop and let the function exit.
            [MenuHandle]::new([ConsoleKey]::X,[ConsoleModifiers]::Control,{
                $script:ShouldReadNextKey = $false
            },"Quit")
            [MenuHandle]::new([ConsoleKey]::S,[ConsoleModifiers]::Control,{
                # do nothing
            },"not implimented")
        )

        $TextForm.ChildPanelList.Add([MenuPanel]::new($GlobalKeyActions))

        # key handles

        $MainKeyListener = [KeyHandler]::new()
        $GlobalKeyActions | ForEach-Object { $MainKeyListener.Add( $_) }

        #editor object

        $script:BufferEditor = [BufferEditor]::new($Buffer)

        # setup buffer to handle keys

        $MainKeyListener.Default = {
            $script:BufferEditor.HandleKey($_)
        }

        if (Test-Path -Path $path){
            $filename = $path | Split-Path -Leaf
            $Header.Text = "PSano : $filename"
            $BufferEditor.LoadBuffer( (Get-Content $path) )
        }

        # "main loop"
        $ExitCursorTop = [Console]::CursorTop + [console]::WindowHeight
        try{
            while ($script:ShouldReadNextKey){
                $TextForm.Draw()
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