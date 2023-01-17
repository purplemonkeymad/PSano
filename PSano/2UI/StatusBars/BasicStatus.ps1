class BasicStatus : Terminal.Gui.StatusBar {

    static [Terminal.Gui.StatusItem[]] $CommonItems = @(
        [Terminal.Gui.StatusItem]::new(
            [Terminal.Gui.Key]'ctrlmask, q',
            'C+q : Quit',
            { [Terminal.Gui.Application]::RequestStop() }
        )
    )

    BasicStatus() : base([BasicStatus]::CommonItems) {

    }

}