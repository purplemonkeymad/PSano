using namespace Terminal.Gui

class PSanoTextEdit : TextView {

    PSanoTextEdit( [string]$StartingText ) : base() {
        $this.ClassInit( $StartingText, ([console]::WindowWidth - 2), ([Console]::WindowHeight - 3 ))
    }

    PSanoTextEdit( [string]$StartingText, [int]$Width, [int]$height ) : base() {
        $this.ClassInit($StartingText,$Width,$height )
    }

    hidden [void] ClassInit( [string]$StartingText, [int]$Width, [int]$height ) {

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