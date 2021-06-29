<#

This provides a "virtual" buffer to write to that means the using
class does not need to know the actual details of buffer co-ordinates.
The classes only need to care about their relative positions.

#>

class Canvas {
    
    # virtual 0,0 point
    [UIPoint]$BufferStart
    # virtual size
    [UIPoint]$BufferSize

    <#
    
    The default position should be the while visible window. We
    take the current scroll line as the start of our window.

    #>

    Canvas () {
        $this.BufferStart = [UIPoint]::new(0,[console]::CursorTop)
        $this.BufferSize = [UIPoint]::new([console]::BufferWdith,[console]::WindowHeight)
    }

    Canvas ([decimal]$StartTop){
        $this.BufferStart = [UIPoint]::new(0,$StartTop)
        $this.BufferSize = [UIPoint]::new([console]::BufferWdith,[console]::WindowHeight)
    }

    Canvas ( [decimal]$StartLeft, [decimal]$StartTop ) {
        $this.BufferStart = [UIPoint]::new($StartLeft,$StartTop)
        $this.BufferSize = [UIPoint]::new( ([console]::BufferWdith - $StartLeft ),[console]::WindowHeight)
    }

    Canvas ( [decimal]$StartLeft, [decimal]$StartTop,[decimal]$Width,[decimal]$Height) {
        $this.BufferStart = [UIPoint]::new($StartLeft,$StartTop)
        $this.BufferSize = [UIPoint]::new( $Width,$Height)
    }

    <#
    
    Important part of creating a windowing system, delagate drawing of a restricted area
    to a another class.

    #>

    [Canvas]SubCanvas ([decimal]$StartLeft,[decimal]$StartTop,[decimal]$Width,[decimal]$Height) {
        # limit max area
        $ValidWidth = [Math]::Min( $Width , $this.BufferSize.x - $StartLeft )
        $ValidHeight = [Math]::Min( $Height , $this.BufferSize.y - $StartTop )
        # inputs are relative
        return [Canvas]::new(
            #left
            $this.BufferStart.x + $StartLeft,
            #top
            $this.BufferStart.y + $StartTop,
            #width
            $ValidWidth,
            #height
            $ValidHeight
        )
    }

    <#
    
    Write to the virtual buffer. It only supports single line writes
    as new lines do not mean that the left position will need to be updated.

    TODO: A new method that allows multi-line writes, either via arrays
        or newline chars.
    
    #>

    [void]Write([decimal]$StartLeft,[decimal]$startTop,[string]$Text) {
        if ($StartLeft -ge $this.BufferSize.x -or
            $startTop -ge $this.BufferSize.y ) {
                return # we are outsize of draw area do nothing
            }

        $thishost = Get-Host
        $BufferLength = $thishost.ui.RawUI.LengthInBufferCells($Text)
        $maxLength = ($this.BufferSize.x - $StartLeft)
        if ($BufferLength -gt $maxLength){
            # need to crop to length, so it should be exactly the right length
            $newText = $Text.Substring(0,$maxLength)
            if ($thishost.ui.RawUI.LengthInBufferCells($newText) -lt $maxLength) {
                $TexttoFill = [System.Collections.Generic.Queue[char]][char[]]$Text.Substring($maxLength)
                do {
                    $newText = $newText + $TexttoFill.Dequeue()
                } while ($thishost.ui.RawUI.LengthInBufferCells($newText) -lt $maxLength)
            }
            
            $text = $newText
        }

        $thishost.ui.RawUI.SetBufferContents(
            [System.Management.Automation.Host.Coordinates]::new(
                ($this.BufferStart.x + $StartLeft),
                ($this.BufferStart.y + $StartTop)
            ),
            $thishost.ui.RawUI.NewBufferCellArray(
                $Text,
                [console]::ForegroundColor,
                [console]::BackgroundColor
            )
        )
       
    }

}