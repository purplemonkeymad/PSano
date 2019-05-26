using namespace System.Collections.Generic

class BufferEditor {
    
    [BufferPanel]$Display

    [List[List[Char]]]$EditorBuffer

    [UIPoint]$CursorLocation

    # What page we are on.
    [int]$Page

    BufferEditor([BufferPanel]$DisplayPanel){
        $this.Display = $DisplayPanel
        $this.Page = 0
        $this.EditorBuffer = [List[List[Char]]]::new()
        $this.CursorLocation = [uipoint]::new(0,0)
    }

    [void]LoadBuffer([string[]]$Lines) {
        $this.EditorBuffer.Clear()
        foreach ($l in $lines) {
            $this.EditorBuffer.Add(
                [List[Char]]$l.ToCharArray()
            )
        }
        $this.UpdateDisplayBuffer()
    }

    [void]UpdateDisplayBuffer(){
        $index = 0
        $displayPage = foreach ($_ in $this.EditorBuffer) {
            if ($index -le $this.Display.WindowSize.y) {
                [string]::new( [char[]]$_ )
            }
            $index++
        }
        $this.Display.DisplayBuffer = $displayPage
        $this.Display.Redraw()
    }

    [void]UpdateDisplayBuffer([decimal]$Row) {
        if ($Row -le $this.Display.WindowSize.y) {
            $this.Display.DisplayBuffer[$row] = [string]::new( [Char[]] $this.EditorBuffer[$row] )
            $this.Display.Redraw($row)
        }
    }

    [void]HandleKey([System.ConsoleKeyInfo]$KeyEvent){
        if (-not $KeyEvent.Modifiers){
            # keys without modifiers
            switch ($keyEvent.Key) {
                #nav
                ([Consolekey]::UpArrow) {
                    $this.CursorLocation.y = [Math]::Max(0, $this.CursorLocation.y -1 )
                    $this.CursorLocation.x = [Math]::Min($this.CursorLocation.x,$this.EditorBuffer[$this.CursorLocation.y].count)
                }
                ([Consolekey]::DownArrow) {
                    $this.CursorLocation.y = [Math]::Min($this.EditorBuffer.Count-1, $this.CursorLocation.y+1 )
                    $this.CursorLocation.x = [Math]::Min($this.CursorLocation.x,$this.EditorBuffer[$this.CursorLocation.y].count)
                }
                ([Consolekey]::LeftArrow) {
                    $this.CursorLocation.x = $this.CursorLocation.x -1
                    if ($this.CursorLocation.x -lt 0 ){
                        if ($this.CursorLocation.y -ne 0){
                            $this.CursorLocation.y = [Math]::Max(0, $this.CursorLocation.y -1 )
                            $this.CursorLocation.x = $this.EditorBuffer[$this.CursorLocation.y].Count
                        } else {
                            $this.CursorLocation.x = 0
                        }
                    }
                }
                ([Consolekey]::RightArrow) {
                    $this.CursorLocation.x = $this.CursorLocation.x+1
                    if ($this.CursorLocation.x -gt $this.EditorBuffer[$this.CursorLocation.y].Count) {
                        if ($this.CursorLocation.y -ne $this.EditorBuffer.Count){
                            $this.CursorLocation.y = [Math]::Max(0, $this.CursorLocation.y +1 )
                            $this.CursorLocation.x = 0
                        } else {
                            $this.CursorLocation.x = $this.EditorBuffer[$this.CursorLocation.y].Count
                        }
                    }
                }

                #Default {}
            }
            # set cursor pos
            $this.Display.SetCursor($this.CursorLocation.x,$this.CursorLocation.y)
        }
        
    }

}