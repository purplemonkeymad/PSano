<#

Variables are a bit harder than the others.

If we use Json to edit we will always get a psobject
back, but we can edit any object type.

#>

class PSanoJsonVariable : PSanoFile {

    # Scope is typeless as the Scope can be either text or an integer. It's up to the user to select the right one.
    $Scope
    [int]$Depth = 10

    PSanoJsonVariable ([string]$VariableName) : base ($VariableName) {
        # the default is global will behave as expected for interative users.
        $this.Scope = 'Global'
    }

    PSanoJsonVariable ([string]$VariableName,$scope) : base ($VariableName) {
        $this.Scope = $scope
    }
    PSanoJsonVariable ([string]$VariableName,$scope,[int]$Depth) : base ($VariableName) {
        $this.Scope = $scope
    }

    # psano only edits strings, so we are going to convert to string anything we get
    # Since json is text this should be ok with convertto-json
    [string[]] readFileContents() {
        $VarObject = (Get-Variable -Name $this.FullPath -Scope $this.Scope -ErrorAction Ignore)
        $json = ConvertTo-Json -InputObject $VarObject.Value -Depth $this.Depth
        return ($json -split '\r?\n')
    }

    <#
    
    Everything is going back to pscustomobject, but not much i can do about that.

    #>
    [void] writeFileContents([string[]]$Content) {
        $newValue = ConvertFrom-Json -InputObject ($Content -join "`n")
        Set-Variable -Name $this.FullPath -Scope $this.Scope -Value $newValue -ErrorAction Stop
    }

}