class PSanoTextFile : PSanoFile {

    # must use object here as ps5&7 have different types for get-content parameters.
    [object]$Encoding = "Default"

    # PSano has and had no idea of a memory only file, all files have a save location before they are opened.
    PSanoTextFile([string]$FullPath) : base($FullPath) {

    }

    PSanoTextFile([string]$FullPath, [object]$Encoding) : base($FullPath) {
        $this.Encoding = $Encoding
    }

    <#
    
    should return an array of strings. Each string represents a line.
    Implimentations should ensure that newline chars are not in the
    strings. Mainly as I don't have a way to deal with new lines in 
    the editor yet.

    @return array of file lines.

    #>
    [string[]] readFileContents() {
        if ($this.FullPath) {
            # pass issues to Get-Content
            if (Test-Path -LiteralPath $this.FullPath) {
                return (Get-Content -LiteralPath $this.FullPath -ErrorAction Stop -Encoding $this.Encoding)
            } else {
                return [string[]]''
            }
        } else {
            # we want to return something.
            return [string[]]''
        }
    }

    <#
    
    Should convert the string array back to whatever that back end
    format. This base format probably needs a way to save if the file
    endings were windows/unix/oldmacOS.

    @param Content String Array where each string is a line in the file.

    #>

    [void] writeFileContents([string[]]$Content) {
        if ($this.FullPath) {
            # we will just let set-content hanle any issue with the file as it is.
            Set-Content -LiteralPath $this.FullPath -Value $Content -ErrorAction Stop -Encoding $this.Encoding
        } else {
            throw "Path not set, can't save file."
        }
    }

    static [bool] canReadPath( [System.Management.Automation.ProviderInfo]$FileSystemProvider, [string]$PSPath ){
        if ($FileSystemProvider.Name -eq "FileSystem"){
            return $true
        }

        return $false
    }

}