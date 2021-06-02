<#

Function are accessible via the function: psdrive. this drive has
write access so we can just pretend that functions are files.

Unlike files, Get-Content won't split up the definitions on new
lines. So we have to do it ourself.

#>
class PSanoFunction : PSanoFile {

    PSanoFunction ([string]$FunctionName) : base ($FunctionName) {}

    <#
    
    Since we have a parameter, we are not going to ask the user to
    include the function drive. Lets just add it ourself.
    
    #>

    [string[]] readFileContents() {
        $realPath = Join-Path 'function:\' -ChildPath $this.FullPath
        $Contents = try {
            (Get-Content -LiteralPath $realPath -ErrorAction Stop) -split "\n"
        } catch {
            # if we get a new function we need to set the scope to global
            # so it can be seen after exiting psano.
            $this.FullPath = "global:" + $this.FullPath
            [string[]]''
        }
        return $Contents
    }

    <#
    
    I don't think i can figure out what line ending was used before.
    But unix style works in PS and it's not like the changes are
    persistant.
    
    #>

    [void] writeFileContents([string[]]$Content) {
        $realPath = Join-Path 'function:\' -ChildPath $this.FullPath
        Set-Content -LiteralPath $realPath -Value (
            $Content -join "`n"
        )
    }
}