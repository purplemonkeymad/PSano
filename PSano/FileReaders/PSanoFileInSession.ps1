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
        $this.Encoding = "Default"
    }

    PSanoFileInSession ([string]$RemotePath, [PSSession]$PSSession, [object]$Encoding) : base ($RemotePath) {
        ## Need to store the session.
        $this.session = $PSSession
        $this.Encoding = $Encoding
    }

    # we need to do the same as the local class but in a remote session
    [string[]] readFileContents() {
        <#
        ICM does not pass stop errors back to this session, we need to 
        capture any errors and throw them in this session.        
        #>
        $RemoteErrors = @()
        Clear-Variable -Force -Name RemoteErrors -ErrorAction Ignore
        $Content = Invoke-Command -Session $this.Session -ScriptBlock {
            Param($Path,$Encoding)
            # we are just going to support litterals for now.
            Get-Content -LiteralPath $path -Encoding $Encoding
        } -ArgumentList $this.FullPath,$this.Encoding -ErrorVariable RemoteErrors -ErrorAction SilentlyContinue

        if ($RemoteErrors.count -gt 0) {
            #errors found
            # ignore file not found errors
            if ($RemoteErrors[0].categoryinfo.category -notlike 'ObjectNotFound'){
                throw $RemoteErrors[0] # can only throw one error.
            }
        }
        # empty doc if files does not exist
        if ($content.count -eq 0){
            $Content = [string[]]""
        }
        return $Content
    }

    [void] writeFileContents([string[]]$Content) {
        <#
        ICM does not pass stop errors back to this session, we need to 
        capture any errors and throw them in this session.        
        #>
        $RemoteErrors = @()
        Clear-Variable -Force -Name RemoteErrors -ErrorAction Ignore
        Invoke-Command -Session $this.Session -ScriptBlock {
            Param($Path,$Content,$Encoding)
            Set-Content -Path $Path -Value $Content -Encoding $Encoding -ErrorAction Stop
        } -ArgumentList $this.FullPath,$Content,$this.Encoding -ErrorVariable RemoteErrors -ErrorAction Stop
        if ($RemoteErrors.count -gt 0) {
            #errors found
            throw $RemoteErrors[0] # can only throw one error.
        }
    }
}