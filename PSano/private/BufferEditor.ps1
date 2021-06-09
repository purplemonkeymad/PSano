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
        $this.updateCursorDisplayPosition()
    }

    [void]updateCursorDisplayPosition() {
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

                        $CutLine = $this.popLine($this.CursorLocation.y)
                        $this.MoveCursor([CursorDirection]::Left)
                        # cursor shoud now be at previous line.
                        if ($CutLine.Length -gt 0) {
                            $this.EditorBuffer[$this.CursorLocation.y].AddRange([list[char]]$CutLine)
                        }
                        $this.RedrawBelow($this.CursorLocation.y)
                    }
                }
                ([System.ConsoleKey]::Delete) {
                    # same as backspace but to the right
                    if ($this.CursorLocation.x -eq ($this.EditorBuffer[$this.CursorLocation.y].Count) ) {
                        if ( $this.CursorLocation.y -lt ($this.EditorBuffer.Count-1) ) { # if there is another line.
                            # remove line
                            $CutLine = $this.popLine($this.CursorLocation.y+1)
                            if ($CutLine.Length -gt 0) {
                                $this.EditorBuffer[$this.CursorLocation.y].AddRange([list[char]]$CutLine)
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
                        $NewLine = $this.EditorBuffer[$this.CursorLocation.y][$this.CursorLocation.x..$this.EditorBuffer[$this.CursorLocation.y].Count] -join ''
                        $this.EditorBuffer[$this.CursorLocation.y].RemoveRange($this.CursorLocation.x,$LineRemaning)
                        $this.insertLine($this.CursorLocation.y+1,$NewLine)
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

    <#
    
    Pop a line out of the current buffer, and return it's current charaters as a string.

    lines are 0 indexed from the start of the document.

    @Param DocumentLine Document line to pop.

    #>

    [string]popLine([int]$DocumentLine){
        if ($DocumentLine -lt 0 -or $DocumentLine -ge $this.EditorBuffer.count) {
            throw "Attempt to pop line: $DocumentLine, is out of Range."
        }

        $ReturnValue = $this.EditorBuffer[$DocumentLine] -join ''

        # remove the line from the current buffer
        $this.EditorBuffer.RemoveAt($DocumentLine)
        if ($this.EditorBuffer.count -eq 0) {
            $this.EditorBuffer.Add([List[char]]::new())
        }
        $this.RedrawBelow($DocumentLine)
        $this.updateInvalidCursorPosition()

        return $ReturnValue
    }
    <#
    pop line at current cursor position.
    #>

    [string]popCurrentLine() {
        return $this.popLine($this.CursorLocation.y)
    }

    <#
    Inserts a new line with given content, pushing down the given line. 
    Ie the given line will be the line data and existing line indexes
    will be increased.

    @Param DocumentLine Line to push down for insert.
    @Param LineData String to set line to.
    #>

    [void]insertLine([int]$DocumentLine,[string]$lineData) {
        if ($DocumentLine -lt 0 -or $DocumentLine -ge $this.EditorBuffer.count) {
            throw "Attempt to insert line: $DocumentLine, is out of Range."
        }

        $this.EditorBuffer.Insert($DocumentLine,[List[Char]]$lineData)
        $this.RedrawBelow($DocumentLine)
        $this.updateInvalidCursorPosition()
    }

    <#
    Inserts a new line with data, at the current cursor position.
    #>
    [void]insertLine([string]$lineData) {
        $this.insertLine($this.CursorLocation.y,$lineData)
    }

    <#
    It's possible that the cursor position will end up moving outside of
    the current buffer. This method should correct this when if it happens.
    #>

    [void]updateInvalidCursorPosition() {
        # move y back in bounds
        $this.CursorLocation.y = [Math]::Min($this.CursorLocation.y,$this.EditorBuffer.Count-1)
        $this.CursorLocation.y = [Math]::Max($this.CursorLocation.y,0)

        # move x back in bounds on current line

        $this.CursorLocation.x = [Math]::Min($this.CursorLocation.x,$this.EditorBuffer[$this.CursorLocation.y].Count)
        $this.CursorLocation.x = [Math]::Max($this.CursorLocation.x,0)

        $this.updateCursorDisplayPosition()
    }

}