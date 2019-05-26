using namespace System.Collections.Generic

class BufferPanel : TextUIPanel {
    
    [String[]]$DisplayBuffer
    [UIPoint]$CursorPos = [UIPoint]::new(0,0)
    [bool]$SetCursorPosition = $false

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
        foreach ( $Line in $lineList ) {
            if ($line -lt $this.DisplayBuffer.count){
                # we also pad here as we need to clear any underlying text
                $g.write( 0,$line, $this.DisplayBuffer[$line].PadRight($g.BufferSize.x) )
            } else {
                $g.write( 0,$line, $EmptyLine)
            }
        }
        $this.CachedOrigin = [uipoint]::new($g.BufferStart.x,$g.BufferStart.y)
    }

    [void] SetCursor ([decimal]$Left,[decimal]$Top) {
        $this.CursorPos = [uipoint]::new($Left,$Top)
        $this.UpdateCursor()
    }

    [void] UpdateCursor () {
        if ($this.SetCursorPosition -and $this.CachedOrigin) {
            [console]::CursorLeft = $this.CursorPos.x + $this.CachedOrigin.x
            [console]::CursorTop  = $this.CursorPos.y + $this.CachedOrigin.y
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