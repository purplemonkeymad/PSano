using namespace System.Collections.Generic

class TextUIForm {
    
    # this is the top left of the display area, typicaly the x coord is 0, but the y is probably cursorTop
    [UIPoint]$BufferOrigin
    # size that window is from bufferorigin.
    [UIPoint]$WindowSize

    [List[TextUIPanel]]$ChildPanelList = [List[TextUIPanel]]::new()

    [List[decimal]]$RedrawLinesList = [List[decimal]]::new()
    [bool]$RedrawAll = $false

    TextUIForm() {
        $this.BufferOrigin = [UIPoint]::new([console]::CursorLeft,[console]::CursorTop)
        $this.WindowSize = [uipoint]::new([console]::BufferWidth,[Console]::WindowHeight)
        $this.RedrawAll = $true

        ## ensure we have enough height to render the form.

        $NeededTop = [Console]::CursorTop + [Console]::WindowHeight
        if ($NeededTop -ge [Console]::BufferHeight) {
            [Console]::BufferHeight = $NeededTop + 2 # for next prompt line.
        }
    }

    [void]Redraw() {
        $this.RedrawAll = $true
    }

    [void]Redraw ([decimal[]]$LinesToRedraw) {
        $this.RedrawLinesList.AddRange($LinesToRedraw)
    }

    [void]Draw() {
        if ($this.RedrawAll){
            $this.Draw(0..$this.WindowSize.y)
            $this.RedrawAll = $false
            return
        }
        $PanelFirstLine = 0
        foreach ($Panel in $this.ChildPanelList){
            if ($Panel.RedrawAll -eq $true){
                $this.Draw($PanelFirstLine..($PanelFirstLine + ($Panel.WindowSize.y-1)))
                $Panel.RedrawAll = $false
            }
            $PanelFirstLine = $PanelFirstLine + $Panel.WindowSize.y
        }
        if ($this.ChildPanelList.RedrawLinesList.count -gt 0 -or $this.RedrawLinesList.count -gt 0){
            [int]$i = 0
            [decimal[]]$LinesToDraw = foreach ($_ in $this.ChildPanelList) {
                foreach ($ChildLine in  $_.RedrawLinesList) {
                    $ChildLine+$i
                } # rebase lines to the top of the form from the top of the panel
                $_.ClearRedrawList()
                $i += $_.WindowSize.y
            }
            [list[decimal]]$linelist = [list[decimal]]::new()
            if ($LinesToDraw.count -gt 0){
                $linelist.AddRange($LinesToDraw)
            }
            if ($this.RedrawLinesList.count -gt 0) {
                $linelist.AddRange($this.RedrawLinesList)
                $this.RedrawLinesList.Clear()
            }
            $this.Draw($linelist)
            return
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
            
            # the where here must be betwen 0 and bottom-top as we have shifted all number down by top
            $Panel.Draw( $PanelCanvas, $DrawLines.foreach({$_ - $DrawTop}).Where({$_ -ge 0 -and $_ -lt ($DrawBottom-$DrawTop) }) )
            $DrawTop += $Panel.WindowSize.y # update top
        }
    }

}