using namespace System.Collections.Generic

class TextUIPanel {

    [UIPoint]$WindowSize

    [List[decimal]]$RedrawLinesList = [List[decimal]]::new()
    [bool]$RedrawAll = $false

    TextUIPanel([decimal]$height){
        $this.WindowSize = [UIPoint]::new([console]::BufferWidth,$height)
    }

    [void] Draw ( [Canvas]$g ){
        #implmented by subclasses
    }

    [void] Draw ( [Canvas]$g, [decimal[]]$lineList ) {
        $this.Draw($g)
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