class UIPoint {
    
    # x is left -> right across screen
    [decimal]$x
    # y is top -> bottom down the screen.
    [decimal]$y

    UIPoint () {
        $this.x = 0
        $this.y = 0
    }

    UIPoint ($XValue,$YValue) {
        $this.x = $XValue
        $this.y = $YValue
    }

    [string] ToString () {
        return "($($this.x),$($this.y))"
    }

}