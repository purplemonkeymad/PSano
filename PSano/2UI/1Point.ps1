<#

This class is just so that 2d points can be passed around as a
single object, rather than having two parameters on everything.

#>

class UIPoint {
    
    # x is left -> right across screen
    [decimal]$x
    # y is top -> bottom down the screen.
    [decimal]$y

    <#
    
    The best default origin for a point is probably 0,0

    #>

    UIPoint () {
        $this.x = 0
        $this.y = 0
    }

    UIPoint ($XValue,$YValue) {
        $this.x = $XValue
        $this.y = $YValue
    }

    static [UIPoint] op_Addition ([UIPoint]$left, [UIPoint]$right) {
        return [UIPoint]@{
            x = $left.x+$right.x
            y = $left.y+$right.y
        }
    }

    <#
    
    Tuple like string, since this is a glorified tuple.
    
    #>

    [string] ToString () {
        return "($($this.x),$($this.y))"
    }

}