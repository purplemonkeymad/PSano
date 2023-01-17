class PSWindow : Terminal.Gui.Window {

    PSWindow(){
        $this.Title = "PSano - $([System.Diagnostics.Process]::GetCurrentProcess().id)"
    }
}