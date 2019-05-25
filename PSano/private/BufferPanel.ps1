using namespace System.Collections.Generic

class BufferPanel : TextUIPanel {
    
    [List[String]]$DisplayBuffer

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
    }
}