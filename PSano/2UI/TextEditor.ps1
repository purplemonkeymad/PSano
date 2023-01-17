using namespace Terminal.Gui

class PSanoTextEdit : TextView {

    PSanoTextEdit( [string]$StartingText ) : base() {

        $this.Multiline = $true
        # enable editing style
        $this.ReadOnly = $false
        $this.AllowsReturn = $true
        $this.AllowsTab = $true

        $this.width = [console]::WindowWidth - 2
        $this.height = [Console]::WindowHeight - 3
    }

}