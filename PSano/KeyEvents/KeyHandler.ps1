using namespace System.Collections.Generic

class KeyHandler {

    [Dictionary[ConsoleKey,KeyHandle]]$HandleCache
    [KeyHandle]$Default

    KeyHandler () {
        $this.HandleCache = [Dictionary[String,KeyHandle]]::new()
    }

    [void]Add([KeyHandle]$Handle) {
        $this.HandleCache.add($Handle.CacheValue(),$Handle)
    }

    [void]ReadKey() {
        # we are looking for all keys
        [console]::TreatControlCAsInput = $true

        $NextKey = [console]::ReadKey()
        $LookupKey = "$($nextKey.Modifiers)+$($nextKey.Key)"
        if ($this.HandleCache.containskey($LookupKey) ){
            ForEach-Object -Process $this.HandleCache[$LookupKey].Action -InputObject $NextKey
        } else {
            ForEach-Object -Process $this.Default.Action -InputObject $NextKey
        }

        # return to default setting.
        [console]::TreatControlCAsInput = $false 
    }

}