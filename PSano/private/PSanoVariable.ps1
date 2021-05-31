class PSanoVariable : PSanoFile {

    [type]$varType
    $Scope

    PSanoVariable ([string]$VariableName) : base ($VariableName) {
        $this.Scope = 'Global'
        ## find type
        $this.varType  = (Get-Variable -Name $VariableName -Scope $this.Scope).Value.GetType()
    }

    PSanoVariable ([string]$VariableName,$scope) : base ($VariableName) {
        $this.Scope = $scope
        ## find type
        $this.varType  = (Get-Variable -Name $VariableName -Scope $this.Scope).Value.GetType()
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
        # " default " nothing found code
        # check if array/list type
        $varValue = (Get-Variable $this.Fullpath).Value
        if ($varValue -is [System.Collections.IEnumerable]) {
            return [string[]](Get-Variable $this.FullPath).Value
        } else {
            return (
                ([string](Get-Variable $this.FullPath).Value) -split "\r?\n"
                )
        }
    }

    [void] writeFileContents([string[]]$Content) {
        # complex assginment, use sub expression for clearer code
        $newValue = $(
            ## common conversions back to stored type:
            switch ($this.varType) {
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
                    if ($_.ImplementedInterfaces -contains [System.Collections.IEnumerable]) {
                        # is array like
                        $subtype = $_.GetElementType()
                        try {
                            foreach ($LineObject in $Content) {
                                [System.Convert]::ChangeType($LineObject,$subtype)
                            }
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
        )
        # scope 1 = parent scope
        Set-Variable -Name $this.FullPath -Scope $this.Scope -Value $newValue
    }

}