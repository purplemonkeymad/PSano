using namespace System.Management.Automation.Runspaces

<#

Basically a re-implimentation of the base class, but putting
everything inside an Invoke-Command.

#>


class PSanoFileInSession : PSanoFile {

    [PSSession]$session

    PSanoFileInSession ([string]$RemotePath, [PSSession]$PSSession) : base ($RemotePath) {
        ## Need to store the session.
        $this.session = $PSSession
    }

    # we need to do the same as the local class but in a remote session
    [string[]] readFileContents() {
        $Content = Invoke-Command -Session $this.Session -ScriptBlock {
            Param($Path)
            # we are just going to support litterals for now.
            Get-Content -LiteralPath $path
        } -ArgumentList $this.FullPath
        if ($content.count -eq 0){
            $Content = [string[]]""
        }
        return $Content
    }

    [void] writeFileContents([string[]]$Content) {
        Invoke-Command -Session $this.Session -ScriptBlock {
            Param($Path,$Content)
            Set-Content -Path $Path -Value $Content 
        } -ArgumentList $this.FullPath,$Content
    }
}