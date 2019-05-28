class HeaderPanel : TextUIPanel {
    
    [string]$Text
    [string]$Notice

    HeaderPanel () : base (1) {
        $this.Text = ""
    }

    HeaderPanel ([string]$Header) : base (1) {
        $this.Text = $Header
    }

    [void]Draw( [Canvas]$g  ){

        $DrawText = " $($this.Text)"
        if ($this.Notice){
            $DrawText = "$DrawText - $($this.Notice)"
        }
        $DrawText = $DrawText.PadRight($g.BufferSize.x)

        # invert colours
        [console]::BackgroundColor,[console]::ForegroundColor = [console]::ForegroundColor,[console]::BackgroundColor
        $g.Write(0,0,$DrawText)
        # invert colours
        [console]::BackgroundColor,[console]::ForegroundColor = [console]::ForegroundColor,[console]::BackgroundColor
    }

}