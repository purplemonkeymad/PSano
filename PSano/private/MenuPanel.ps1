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
        if (-not $this.CachedKeys) {
            [Queue[string]]$KeyStringList = $this.MenuKeys.foreach({
                "$(if ($_.Modifier) {$_.Modifier.tostring()[0]+'+'})$($_.Key): $($_.name) "
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

        $g.Draw(0,0,$this.CachedKeys[0])
        $g.Draw(0,1,$this.CachedKeys[1])
    }

}