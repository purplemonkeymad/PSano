using namespace System.Collections.Generic

enum CursorDirection {
    Up
    Down
    Left
    Right
    Start
    End
}

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

    [void]RedrawLine([decimal]$line){
        $this.UpdateDisplayBuffer($line)
        $this.Display.Redraw($line)
    }

    [void]RedrawBelow([decimal]$line) {
        if ($this.EditorBuffer.count -eq $this.Display.DisplayBuffer.Count){
            $lastline = $this.EditorBuffer.Count
            for ($i = 0; $i -lt $lastline; $i++){
                $this.RedrawLine($i)
            }
        } else {
            $this.UpdateDisplayBuffer()
        }
    }

    [void]MoveCursor ([CursorDirection]$Dir) {
        $this.MoveCursor($Dir,1)
    }

    [void]MoveCursor ([CursorDirection]$Dir,[decimal]$Distance) {
        switch ($Dir) {
            #nav
            ([CursorDirection]::Up) {
                $this.CursorLocation.y = [Math]::Max(0, $this.CursorLocation.y -1 )
                $this.CursorLocation.x = [Math]::Min($this.CursorLocation.x,$this.EditorBuffer[$this.CursorLocation.y].count)
            }
            ([CursorDirection]::Down) {
                $this.CursorLocation.y = [Math]::Min($this.EditorBuffer.Count-1, $this.CursorLocation.y+1 )
                $this.CursorLocation.x = [Math]::Min($this.CursorLocation.x,$this.EditorBuffer[$this.CursorLocation.y].count)
            }
            ([CursorDirection]::Left) {
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
            ([CursorDirection]::Right) {
                $this.CursorLocation.x = $this.CursorLocation.x+1
                if ($this.CursorLocation.x -gt $this.EditorBuffer[$this.CursorLocation.y].Count) {
                    if ($this.CursorLocation.y -ne $this.EditorBuffer.Count-1){
                        $this.CursorLocation.y = [Math]::Max(0, $this.CursorLocation.y +1 )
                        $this.CursorLocation.x = 0
                    } else {
                        $this.CursorLocation.x = $this.EditorBuffer[$this.CursorLocation.y].Count
                    }
                }
            }
        }
        $this.Display.SetCursor($this.CursorLocation.x,$this.CursorLocation.y)
    }


    [void]HandleKey([System.ConsoleKeyInfo]$KeyEvent){
        if (-not $KeyEvent.Modifiers){
            # keys without modifiers
            switch ($keyEvent.Key) {
                #nav
                ([Consolekey]::UpArrow) {
                    $this.MoveCursor([CursorDirection]::Up)
                }
                ([Consolekey]::DownArrow) {
                    $this.MoveCursor([CursorDirection]::Down)
                }
                ([Consolekey]::LeftArrow) {
                    $this.MoveCursor([CursorDirection]::Left)
                }
                ([Consolekey]::RightArrow) {
                    $this.MoveCursor([CursorDirection]::Right)
                }
            }
        }

        #we don't care about modifiers.
        if ($KeyEvent.KeyChar) {
            # can by typed?
            switch ($keyEvent.Key) {
                # text control keys
                ([System.ConsoleKey]::Backspace) {
                    if ($this.CursorLocation.x -gt 0){
                        $this.EditorBuffer[$this.CursorLocation.y].RemoveAt($this.CursorLocation.x-1)
                        $this.MoveCursor([CursorDirection]::Left)
                        $this.RedrawLine($this.CursorLocation.y)
                    } elseif ($this.CursorLocation.y -gt 0) {
                        # remove line
                        [list[char]]$CutLine = $this.EditorBuffer[$this.CursorLocation.y]
                        $this.EditorBuffer.RemoveAt($this.CursorLocation.y)
                        $this.MoveCursor([CursorDirection]::Left)
                        # cursor shoud now be at previous line.
                        if ($CutLine.Count -gt 0) {
                            $this.EditorBuffer[$this.CursorLocation.y].AddRange($CutLine)
                        }
                    }
                }

                ([System.ConsoleKey]::Enter) {
                    if ($this.CursorLocation.x -eq $this.EditorBuffer[$this.CursorLocation.y].Count){
                        # end of line, easy
                        $this.EditorBuffer.Insert($this.CursorLocation.y+1,[List[char]]::new())
                        $this.MoveCursor([CursorDirection]::Down)
                        $this.RedrawBelow($this.CursorLocation.y)
                    } else {
                        # middle of line

                    }
                }

                # typing keys
                Default {
                    $this.EditorBuffer[$this.CursorLocation.y].Insert($this.CursorLocation.x,$KeyEvent.KeyChar)
                    $this.MoveCursor([CursorDirection]::Right)
                    $this.RedrawLine($this.CursorLocation.y)
                }
            }
        }
        
    }

}