class KeyHandle {

    [ConsoleKey]$Key
    [System.ConsoleModifiers]$Modifier
    [scriptblock]$Action

    KeyHandle ([ConsoleKey]$key,[scriptblock]$Action) {
        $this.Key = $key
        $this.Action = $Action
    }

    KeyHandle ([ConsoleKey]$key,[ConsoleModifiers]$Modifier,[scriptblock]$Action) {
        $this.Key = $key
        $this.Modifier = $Modifier
        $this.Action = $Action
    }

    [string]CacheValue() {
        return "$($this.Modifier)+$($this.Key)"
    }

}