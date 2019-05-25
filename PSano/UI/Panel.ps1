class TextUIPanel {

    [UIPoint]$WindowSize

    #[TextUIForm]$Parent

    TextUIPanel([decimal]$height){
        $this.WindowSize = [UIPoint]::new([console]::BufferWidth,$height)
    }

    [void] Draw ( [Canvas]$g ){

    }

    [void] Draw ( [Canvas]$g, [decimal[]]$lines) {
        $this.Draw($g)
    }
    
}