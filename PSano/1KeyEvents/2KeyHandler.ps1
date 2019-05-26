using namespace System.Collections.Generic

class KeyHandler {

    [Dictionary[String,KeyHandle]]$HandleCache
    [scriptblock]$Default

    KeyHandler () {
        $this.HandleCache = [Dictionary[String,KeyHandle]]::new()
    }

    [void]Add([KeyHandle]$Handle) {
        $this.HandleCache.add([KeyHandler]::GetLookUpKey($Handle),$Handle)
    }

    static [String]GetLookUpKey([KeyHandle]$Handle){
        return "$($Handle.Modifier)+$($Handle.Key)"
    }

    static [String]GetLookUpKey([ConsoleKeyInfo]$ConsoleKey){
        return "$($ConsoleKey.Modifiers)+$($ConsoleKey.Key)"
    }

    [void]ReadKey() {
        # we are looking for all keys
        [console]::TreatControlCAsInput = $true

        $NextKey = [console]::ReadKey($true)
        $LookupKey = [KeyHandler]::GetLookUpKey($NextKey)
        if ($this.HandleCache.containskey($LookupKey) ){
            ForEach-Object -Process $this.HandleCache[$LookupKey].Action -InputObject $NextKey
        } elseif ($this.Default) {
            ForEach-Object -Process $this.Default -InputObject $NextKey
        }

        # return to default setting.
        [console]::TreatControlCAsInput = $false 
    }

}