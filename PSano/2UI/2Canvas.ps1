class Canvas {
    
    [UIPoint]$BufferStart
    [UIPoint]$BufferSize

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

    [void]Write([decimal]$StartLeft,[decimal]$startTop,[string]$Text) {
        if ($StartLeft -ge $this.BufferSize.x -or
            $startTop -ge $this.BufferSize.y ) {
                return # we are outsize of draw area do nothing
            }

        #set the draw start
        [console]::CursorTop = $this.BufferStart.y + $StartTop
        [console]::CursorLeft = $this.BufferStart.x + $StartLeft

        # trim text
        $ValidText = $Text -replace "`n|`r",''
        $Validlength = [Math]::Min($ValidText.Length, $this.BufferSize.x - $StartLeft)
        $ValidText = $ValidText.Substring(0,$Validlength)

        [console]::Write($ValidText)
        
    }

}