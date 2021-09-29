using namespace System.Collections.Generic

class TextUIPanel {

    [UIPoint]$WindowSize

    [List[decimal]]$RedrawLinesList = [List[decimal]]::new()
    [bool]$RedrawAll = $false

    TextUIPanel([decimal]$height){
        $this.WindowSize = [UIPoint]::new([console]::BufferWidth,$height)
    }

    [void] Draw ( [Canvas]$g ){
        if ($this.RedrawAll){
            $this.Draw($g, 0..($this.WindowSize.y -1))
        } else {
            $this.Draw($g, $this.RedrawLinesList)
            $this.ClearRedrawList()
        }
    }

    [void] Draw ( [Canvas]$g, [decimal[]]$lineList ) {
        # implemented by subclasses.
    }

    [void] Redraw () {
        $this.RedrawAll=$true
    }

    [void] Redraw ([decimal[]]$LinesToRedraw) {
        $this.RedrawLinesList.AddRange($LinesToRedraw)
    }

    [void] ClearRedrawList () {
        $this.RedrawLinesList.Clear()
    }
    
}