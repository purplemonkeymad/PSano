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

        if (Test-Path -Path $path){
            $filename = $path | Split-Path -Leaf
            $Header.Text = "PSano : $filename"
            $buffer.DisplayBuffer = Get-Content $path
        }

        # "main loop"
        while ($script:ShouldReadNextKey){
            $TextForm.Draw()
            $MainKeyListener.ReadKey()
        }
    }
    
    end {
    }
}