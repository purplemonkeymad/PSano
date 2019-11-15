using namespace System.Collections.Generic

class BufferPanel : TextUIPanel {
    
    [String[]]$DisplayBuffer
    [UIPoint]$CursorPos = [UIPoint]::new(0,0)
    [bool]$SetCursorPosition = $false

    [decimal]$Page = 0
    [decimal]$ScreensRight = 0

    [UIPoint]$CachedOrigin = $null

    BufferPanel ([decimal]$height) : base ($height) {
        $this.DisplayBuffer = [list[string]]::new()
    }

    BufferPanel ([decimal]$height,[string[]]$Buffer) : base($height) {
        $this.DisplayBuffer = $Buffer
    }

    # overrides
    [void] Draw ( [Canvas]$g, [decimal[]]$lineList ) {
        $EmptyLine = " ~ ".PadRight($g.BufferSize.x)
        $CurrentPageTop = ($this.Page * $this.WindowSize.y)

        foreach ( $Line in $lineList ) {
            $BufferLine = $line + $CurrentPageTop
            if ($BufferLine -lt $this.DisplayBuffer.count){
                if ($BufferLine -eq $this.CursorPos.y -and $this.ScreensRight -gt 0) {
                    # if we are too long, then cut the section from the line we need.
                    $CurrentScreenLeft = ($this.ScreensRight * $this.WindowSize.x)
                    $DisplayLine = $this.DisplayBuffer[$BufferLine].Substring($CurrentScreenLeft).PadRight($g.BufferSize.x)
                } else {
                    # we also pad here as we need to clear any underlying text
                    $DisplayLine = $this.DisplayBuffer[$BufferLine].PadRight($g.BufferSize.x)
                }

                # some chars are an issue, such as tab so we should replace them on view but not back end
                $DisplayLine = $DisplayLine -replace "`t",([char]16)

                $g.write( 0,$line, $DisplayLine )
            } else {
                $g.write( 0,$line, $EmptyLine)
            }
        }
        $this.CachedOrigin = [uipoint]::new($g.BufferStart.x,$g.BufferStart.y)
    }

    # overrides
    [void] Redraw ([decimal[]]$LinesToRedraw) {
        $CurrentPageTop = ($this.Page * $this.WindowSize.y)
        ([TextUIPanel]$this).Redraw( ($LinesToRedraw | Foreach-Object {$_ - $CurrentPageTop}) )
    }

    [void] SetCursor ([decimal]$Left,[decimal]$Top) {
        $this.CursorPos = [uipoint]::new($Left,$Top)
        $this.UpdateCursor()
    }

    [void] UpdateCursor () {
        if ($this.SetCursorPosition -and $this.CachedOrigin) {

            # translate actual cursor positions to our internal buffer area

            $CurrentPageTop = ($this.Page * $this.WindowSize.y)
            $CurrentPageBottom = ( $CurrentPageTop +  $this.WindowSize.y) -1

            $CurrentScreenLeft = ($this.ScreensRight * $this.WindowSize.x)
            $CurrentScreenRight = ( $CurrentScreenLeft +  $this.WindowSize.x) -1

            # check if new position is out of the current "page"

            if ($this.CursorPos.y -lt $CurrentPageTop) {
                $this.page = [Math]::Floor( ($this.CursorPos.y / $this.WindowSize.y) )
                $this.Redraw()
            }
            if ($this.CursorPos.y -gt $CurrentPageBottom) {
                $this.page = [Math]::Floor( ($this.CursorPos.y / $this.WindowSize.y) )
                $this.Redraw()
            }

            [console]::CursorTop  = ($this.CursorPos.y - $CurrentPageTop) + $this.CachedOrigin.y

            # check if new position is out of the current "screen"

            if ($this.CursorPos.x -lt $CurrentScreenLeft) {
                $this.ScreensRight = [Math]::Floor( ($this.CursorPos.x / $this.WindowSize.x) )
                $this.Redraw($this.CursorPos.y)
            }
            if ($this.CursorPos.x -gt $CurrentScreenRight) {
                $this.ScreensRight = [Math]::Floor( ($this.CursorPos.x / $this.WindowSize.x) )
                $this.Redraw($this.CursorPos.y)
            }

            $CurrentScreenLeft = ($this.ScreensRight * $this.WindowSize.x)
            $CurrentScreenRight = ( $CurrentScreenLeft +  $this.WindowSize.x) -1

            [console]::CursorLeft = ($this.CursorPos.x - $CurrentScreenLeft ) + $this.CachedOrigin.x

        }
    }

    [void] RemoveFocus () {
        $this.SetCursorPosition=$false
    }

    [void] SetFocus () {
        $this.SetCursorPosition=$true
        $this.UpdateCursor()
    }
}