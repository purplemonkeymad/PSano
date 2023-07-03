<#
There is no path parser for PS paths (AFAICAS) so here is a path
class that can pull out providers and roots
#>
class PSPathParser {
    <# inital version provided by bing chat.#>
    [string]$ProviderName
    [string]$PsDriveName
    [string]$LocalPath

    [string]$OriginalString

    PSPathParser([string]$path) {

        # since values are string type we use empty instead of null
        $this.ProviderName = [string]::Empty
        $this.PsDriveName = [string]::Empty
        $this.LocalPath = [string]::Empty
        $this.OriginalString = $Path

        ## provider prefix
        if ($path -match "^([^:]+)::(.*)$") {
            $this.ProviderName = $matches[1]
            $path = $matches[2]
        }

        ## has drive designation
        if ($path -match "^([^:]+):(.*)$") {
            $this.PsDriveName = $matches[1]
            $path = $matches[2]
        }

        ## relative or local paths
        if ( ([string]::Empty -eq $this.ProviderName) -and ([string]::Empty -eq $this.PsDriveName) ) {
            if ($path -match "^\.(.*)$") {
                $path = $matches[1]
            }
            elseif ($path -match "^([^:\/;~.]+):(.*)$") {
                $this.PsDriveName = $matches[1]
                $path = $matches[2]
            }
            else {
                ## Use current location provider
                $this.ProviderName = (Get-Location).Provider.Name
            }
        }

        # upgrade drive info to provider

        if ( ([string]::Empty -ne $this.PsDriveName) -and ([string]::Empty -eq $this.ProviderName) ) {
            try {
                $this.ProviderName = (Get-PSDrive -Name $this.PsDriveName -ErrorAction Stop).Provider.Name
            } catch {
                # drive not found, same as null.
            }

        }

        # path conclutions

        if ($this.ProviderName -eq "FileSystem" -and $path.StartsWith("\\")) {
            # Assume remote path
            $this.LocalPath = $path
            return
        }
        else {
            # Use
            $this.LocalPath = $path
            
        }
    }
}