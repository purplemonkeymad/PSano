using namespace System.Collections.Generic

class FocusSwitchingHandle : KeyHandle {
    
    [Dictionary[string,KeyHandeler]]$ContextCache

    FocusSwitchingHandle () : base ($null,{
        $this.Action($_)
    }) {

    }

    [void]Action([consolekey]$Key){

    }
}