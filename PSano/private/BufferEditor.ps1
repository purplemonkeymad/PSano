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

    <#
    Retiveing actual charaters from the buffer.
    #>

    [string]GetBuffer() {
        $AsLines = foreach ( $BufferLine in $this.EditorBuffer) {
            $BufferLine -join ''
        }
        return ($AsLines -join [System.Environment]::NewLine)
    }

    <#
    Retrive actual charters, as an array of lines instead of 
    as a whole block.
    #>

    [string[]]GetBufferLines() {
        $AsLines = foreach ( $BufferLine in $this.EditorBuffer) {
            $BufferLine -join ''
        }
        return $AsLines
    }

    [void]UpdateDisplayBuffer(){
        $index = 0
        $displayPage = foreach ($_ in $this.EditorBuffer) {
            [string]::new( [char[]]$_ )
            $index++
        }
        $this.Display.DisplayBuffer = $displayPage
        $this.Display.Redraw()
    }

    [void]UpdateDisplayBuffer([decimal]$Row) {
            $this.Display.DisplayBuffer[$row] = [string]::new( [Char[]] $this.EditorBuffer[$row] )
            $this.Display.Redraw($row)
    }

    [void]RedrawLine([decimal]$line){
        $this.UpdateDisplayBuffer()
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
                $this.CursorLocation.y = [Math]::Max(0, $this.CursorLocation.y - $Distance )
                $this.CursorLocation.x = [Math]::Min($this.CursorLocation.x,$this.EditorBuffer[$this.CursorLocation.y].count)
            }
            ([CursorDirection]::Down) {
                # we should set the current line to redraw as it might be shifted to the right
                $this.Display.Redraw($this.CursorLocation.y)
                $this.CursorLocation.y = [Math]::Min($this.EditorBuffer.Count-1, $this.CursorLocation.y+$Distance )
                $this.CursorLocation.x = [Math]::Min($this.CursorLocation.x,$this.EditorBuffer[$this.CursorLocation.y].count)
                
            }
            ([CursorDirection]::Left) {
                $this.CursorLocation.x = $this.CursorLocation.x -$Distance
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
                $this.CursorLocation.x = $this.CursorLocation.x+$Distance
                if ($this.CursorLocation.x -gt $this.EditorBuffer[$this.CursorLocation.y].Count) {
                    if ($this.CursorLocation.y -ne $this.EditorBuffer.Count-1){
                        $this.CursorLocation.y = [Math]::Max(0, $this.CursorLocation.y +1 )
                        $this.CursorLocation.x = 0
                    } else {
                        $this.CursorLocation.x = $this.EditorBuffer[$this.CursorLocation.y].Count
                    }
                }
            }
            ([CursorDirection]::End) {
                $this.CursorLocation.x = $this.EditorBuffer[$this.CursorLocation.y].count
            }
            ([CursorDirection]::Start) {
                $this.CursorLocation.x = 0
            }
        }
        $this.Display.SetCursor($this.CursorLocation.x,$this.CursorLocation.y)
    }


    [void]HandleKey([System.ConsoleKeyInfo]$KeyEvent){
        $handled = $false
        if (-not $KeyEvent.Modifiers){
            # keys without modifiers
            $handled = $true
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
                ([ConsoleKey]::End) {
                    $this.MoveCursor([CursorDirection]::End) 
                }
                ([ConsoleKey]::Home) {
                    $this.MoveCursor([CursorDirection]::Start )
                }
                ([ConsoleKey]::PageDown) {
                    $this.MoveCursor([CursorDirection]::Down, $this.Display.WindowSize.y )
                }
                ([ConsoleKey]::PageUp) {
                    $this.MoveCursor([CursorDirection]::Up, $this.Display.WindowSize.y )
                }
                Default {
                    $handled = $false
                }
            }
        }

        #we don't care about modifiers.
        if (-not $handled) { #$KeyEvent.KeyChar) {
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
                        $this.RedrawBelow($this.CursorLocation.y)
                    }
                }
                ([System.ConsoleKey]::Delete) {
                    # same as backspace but to the right
                    if ($this.CursorLocation.x -eq ($this.EditorBuffer[$this.CursorLocation.y].Count) ) {
                        if ( $this.CursorLocation.y -lt ($this.EditorBuffer.Count-1) ) { # if there is another line.
                            # remove line
                            [list[char]]$CutLine = $this.EditorBuffer[$this.CursorLocation.y+1]
                            $this.EditorBuffer.RemoveAt($this.CursorLocation.y+1)
                            #$this.MoveCursor([CursorDirection]::Left)
                            # cursor shoud now be at previous line.
                            if ($CutLine.Count -gt 0) {
                                $this.EditorBuffer[$this.CursorLocation.y].AddRange($CutLine)
                            }
                            $this.RedrawBelow($this.CursorLocation.y)
                        }
                    } else {
                        $this.EditorBuffer[$this.CursorLocation.y].RemoveAt($this.CursorLocation.x)
                        #$this.MoveCursor([CursorDirection]::Left)
                        $this.RedrawLine($this.CursorLocation.y)

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
                        $LineRemaning = $this.EditorBuffer[$this.CursorLocation.y].Count - $this.CursorLocation.x
                        $NewLine = [char[]]::new($LineRemaning)
                        $this.EditorBuffer[$this.CursorLocation.y].CopyTo($this.CursorLocation.x,$NewLine,0,$LineRemaning)
                        $this.EditorBuffer[$this.CursorLocation.y].RemoveRange($this.CursorLocation.x,$LineRemaning)
                        $this.EditorBuffer.Insert($this.CursorLocation.y+1,([list[char]]$NewLine))
                        $this.RedrawBelow($this.CursorLocation.y)
                        $this.MoveCursor([CursorDirection]::Right)
                    }
                }

                # typing keys
                Default {
                    if ($KeyEvent.KeyChar){
                        $this.EditorBuffer[$this.CursorLocation.y].Insert($this.CursorLocation.x,$KeyEvent.KeyChar)
                        $this.MoveCursor([CursorDirection]::Right)
                        $this.RedrawLine($this.CursorLocation.y)
                    }
                }
            }
        }
        
    }

}