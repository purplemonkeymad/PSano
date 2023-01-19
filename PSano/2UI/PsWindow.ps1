class PSWindow : Terminal.Gui.Window {

    [bool]$IncludePid = $true
    [string]$TitleSuffix__ = [string]::empty

    PSWindow(){
        $this.SetTitleSuffix("")
    }

    [void]SetTitleSuffix( [string]$Suffix ) {
        $this.TitleSuffix__ = $Suffix
        $newTitle = $(
            "PSano"
            if ($this.IncludePid) { "($([System.Diagnostics.Process]::GetCurrentProcess().id))" }
            if ($this.TitleSuffix__) { $this.TitleSuffix__ }
        ) -join ' - '

        $this.Title = $newTitle
    }
}