using namespace Terminal.Gui

class PSanoTextEdit : TextView {

    PSanoTextEdit( [string]$StartingText ) : base() {
        $this.ClassInit( $StartingText, [dim]::fill(0), [dim]::fill(0))
    }

    PSanoTextEdit( [string]$StartingText, [dim]$Width, [dim]$height ) : base() {
        $this.ClassInit($StartingText,$Width,$height )
    }

    hidden [void] ClassInit( [string]$StartingText, [dim]$Width, [dim]$height ) {

        $this.Multiline = $true
        # enable editing style
        $this.ReadOnly = $false
        $this.AllowsReturn = $true
        $this.AllowsTab = $true

        # set size
        $this.width = $Width
        $this.height = $height

        # set text
        $this.Text = $StartingText
    }

}