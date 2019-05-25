class HeaderPanel : TextUIPanel {
    
    [string]$Text

    HeaderPanel () : base (1) {
        $this.Text = ""
    }

    HeaderPanel ([string]$Header) : base (1) {
        $this.Text = $Header
    }

    [void]Draw( [Canvas]$g  ){

        $DrawText = " $($this.Text)".PadRight($g.BufferSize.x)

        # invert colours
        [console]::BackgroundColor,[console]::ForegroundColor = [console]::ForegroundColor,[console]::BackgroundColor
        $g.Write(0,0,$DrawText)
        # invert colours
        [console]::BackgroundColor,[console]::ForegroundColor = [console]::ForegroundColor,[console]::BackgroundColor
    }

}