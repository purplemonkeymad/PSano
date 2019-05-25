using namespace System.Collections.Generic

class TextUIForm {
    
    # this is the top left of the display area, typicaly the x coord is 0, but the y is probably cursorTop
    [UIPoint]$BufferOrigin
    # size that window is from bufferorigin.
    [UIPoint]$WindowSize

    [List[TextUIPanel]]$ChildPanelList = [List[TextUIPanel]]::new()

    [List[int]]$RedrawLinesList = [List[int]]::new()
    [bool]$RedrawAll

    TextUIForm() {
        $this.BufferOrigin = [UIPoint]::new([console]::CursorLeft,[console]::CursorTop)
        $this.WindowSize = [uipoint]::new([console]::BufferWidth,[Console]::WindowHeight)
    }

    [void]Draw() {
        $Canvas = [Canvas]::new($this.BufferOrigin.x,$this.BufferOrigin.y,$this.WindowSize.x,$this.WindowSize.y)
        $DrawTop = 0
        foreach ( $Panel in $this.ChildPanelList) {
            if ($DrawTop -gt $this.WindowSize.y){
                continue
            }
            $ValidHeight = [math]::min($Panel.WindowSize.y, $this.WindowSize.y - $DrawTop)
            $PanelCanvas = $Canvas.SubCanvas(0,$DrawTop,$Canvas.BufferSize.x,$ValidHeight)
            $Panel.Draw($PanelCanvas)
            $DrawTop += $Panel.WindowSize.y # update top
        }
    }

    [void]Draw([decimal[]]$lines){
        $DrawLines = Sort-Object -InputObject $lines
        $Canvas = [Canvas]::new($this.BufferOrigin.x,$this.BufferOrigin.y,$this.WindowSize.x,$this.WindowSize.y)
        $DrawTop = 0
        foreach ( $Panel in $this.ChildPanelList ) {
            if ($DrawTop -gt $this.WindowSize.y){
                continue
            }
            $DrawBottom = $DrawTop + $Panel.WindowSize.y

            $ValidHeight = [math]::min($Panel.WindowSize.y, $this.WindowSize.y - $DrawTop)
            $PanelCanvas = $Canvas.SubCanvas(0,$DrawTop,$Canvas.BufferSize.x,$ValidHeight)
            
            $Panel.Draw( $PanelCanvas, $DrawLines.Where({$_ -ge $DrawTop -and $_ -lt $DrawBottom }) )
            $DrawTop += $Panel.WindowSize.y # update top
        }
    }

}