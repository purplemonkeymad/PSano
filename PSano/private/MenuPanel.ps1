using namespace System.Collections.Generic

class MenuHandle : KeyHandle {

    [string]$Name

    MenuHandle ([ConsoleKey]$key,[scriptblock]$Action,[string]$name) : base ($key,$Action) {
        $this.name = $name
    }

    MenuHandle ([ConsoleKey]$key,[ConsoleModifiers]$Modifier,[scriptblock]$Action,[string]$name) : base ($key,$Modifier,$Action) {
        $this.name = $name
    }

}

class MenuPanel : TextUIPanel {

    [list[MenuHandle]]$MenuKeys
    
    MenuPanel ([MenuHandle[]]$MenuKeys) : base (2) {
        $this.MenuKeys = $MenuKeys
    }

    [string[]]$CachedKeys

    [void] Draw ( [Canvas]$g ){
        if ($this.CachedKeys.count -eq 0) {
            [Queue[string]]$KeyStringList = @()
            $this.MenuKeys.foreach({
                # as this is a loop on a generic list we need to use $args[0] instead of $_
                $keyStringList.Enqueue("$(if ($args[0].Modifier) {$args[0].Modifier.tostring()[0]+'+'})$($args[0].Key): $($args[0].name) ")
            })
            $line1 = ""
            while ($keyStringList.Count -gt 0 -and $line1.Length + $KeyStringList.Peek().Length -lt $g.BufferSize.x){
                $line1 += $KeyStringList.Dequeue()
            }
            $line2 = ""
            while ($keyStringList.Count -gt 0 -and $line2.Length + $KeyStringList.Peek().Length -lt $g.BufferSize.x){
                $line2 += $KeyStringList.Dequeue()
            }
            $this.CachedKeys = $line1.PadRight($g.BufferSize.x),$line2.PadRight($g.BufferSize.x)
        }

        $g.Write(0,0,$this.CachedKeys[0])
        $g.Write(0,1,$this.CachedKeys[1])
    }

}