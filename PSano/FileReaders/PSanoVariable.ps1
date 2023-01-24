<#

Variables are a bit harder than the others. Variables can have any
type. So we can't be sure were are only getting strings. So we should
save the type and try to convert back to it after editing.

We can't get every type right, but what can you expect editing a variable
with a text editor?

#>

class PSanoVariable : PSanoFile {

    # Scope is typeless as the Scope can be either text or an integer. It's up to the user to select the right one.
    [type]$varType
    $Scope

    PSanoVariable ([string]$VariableName) : base ($VariableName) {
        # the default is global will behave as expected for interative users.
        $this.Scope = 'Global'
        ## find type
        $VarObject = (Get-Variable -Name $VariableName -Scope $this.Scope -ErrorAction Ignore)
        if ($VarObject) {
            $this.varType  = $VarObject.Value.GetType()
        } else {
            $this.varType = [string[]]
        }
    }

    PSanoVariable ([string]$VariableName,$scope) : base ($VariableName) {
        $this.Scope = $scope
        ## find type
        $VarObject = (Get-Variable -Name $VariableName -Scope $this.Scope -ErrorAction Ignore)
        if ($VarObject) {
            $this.varType  = $VarObject.Value.GetType()
        } else {
            $this.varType = [string[]]
        }
    }

    # psano only edits strings, so we are going to convert to string anything we get
    # Really is user error otherwise.
    [string[]] readFileContents() {
        ## need to check type
        switch ($this.varType) {
            [string[]] {
                # if string array already probably one per line.
                return (Get-Variable $this.FullPath).Value
            }
            [string] {
                # might have line breaks let's split on them
                return ((Get-Variable $this.FullPath).Value -split "\r?\n")
            }
            [object[]] {
                #who knows, we are just going to guess string
                return [string[]](Get-Variable $this.FullPath).Value
            }
        }

        <# 
        " default " nothing found code
        It seams cleaner to keep it away from the switch statement, but will be
        functionaly the same.
        #>
        # check if array/list type, split on new line if it is not.
        $varValue = (Get-Variable $this.Fullpath).Value
        if ($varValue -is [System.Collections.IEnumerable]) {
            return [string[]](Get-Variable $this.FullPath).Value
        } else {
            return (
                ([string](Get-Variable $this.FullPath).Value) -split "\r?\n"
                )
        }
    }

    <#
    
    If we were crap shooting before with the types, here we
    are shoveling shit.

    If we know the type then we can *try* to call a string
    constructor. Some objects won't be able to support this,
    but for the types that do it will look magic.

    Right now it will always try to succeed. But should I
    be throwing exceptions back to the user?

    #>
    [void] writeFileContents([string[]]$Content) {
        # complex assginment, use sub expression for clearer code
        $newValue = switch ($this.varType) {
            [string[]] {
                # not much to do
                $Content
            }
            [string] {
                # new lines should be added to string
                $Content -join "`n"
            }
            [object[]] {
                # who knows, lets just use string array
                $Content
            }
            Default {
                # test if is array type or not
                # there appears not to be a way to do this with `-is [type]` like you
                # can if you have the object.
                if ($_.ImplementedInterfaces -contains [System.Collections.IEnumerable]) {
                    # is array like
                    $subtype = $_.GetElementType()
                    try {

                        <# 
                        [T[]] cast might work, but I feel if we do each object
                        at least the valid ones could possibly be saved in the
                        future. for now just bail.
                        #>

                        $tempValue = foreach ($LineObject in $Content) {
                            $LineObject -as $subtype
                        }
                        Set-Variable -Name $this.FullPath -Scope $this.Scope -Value ($tempValue -as $this.varType)
                        return # jump out of the method (this is bad!)
                    } catch {
                        # give up and just output a string[]
                        $Content 
                    }
                } else {
                    # single type, we should concat lines with newline and try the old type
                    try {
                        [System.Convert]::ChangeType(
                            ($Content -join "`n"),
                            $_
                        )
                    } catch {
                        # create single string value
                        $Content -join "`n"
                    }

                }
            }
        }
        Set-Variable -Name $this.FullPath -Scope $this.Scope -Value $newValue
    }

}