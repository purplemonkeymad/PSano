<#

Common interface for writting and reading a "file" that psano can edit.

There is no partial load on this, it loads the whole file in to memory.
Since this is not a serious endevor, I'm ok with this.

The base implimentation is for local files.

#>

class PSanoFile {

    [string]$FullPath

    # PSano has and had no idea of a memory only file, all files have a save location before they are opened.
    PSanoFile([string]$FullPath) {
        $this.FullPath = $FullPath
    }

    <#
    
    should return an array of strings. Each string represents a line.
    Implimentations should ensure that newline chars are not in the
    strings. Mainly as I don't have a way to deal with new lines in 
    the editor yet.

    @return array of file lines.

    #>
    [string[]] readFileContents() {
        Write-Error "readFileContents not implimented on this class." -ErrorAction Stop -ErrorId "psano.FileReaders.NotImplimented" -TargetObject $this -Category NotImplemented
        return [string[]]""
    }

    <#
    
    Should convert the string array back to whatever that back end
    format. This base format probably needs a way to save if the file
    endings were windows/unix/oldmacOS.

    @param Content String Array where each string is a line in the file.

    #>

    [void] writeFileContents([string[]]$Content) {
        Write-Error "writeFileContents not implimented on this class." -ErrorAction Stop -ErrorId "psano.FileReaders.NotImplimented" -TargetObject $this -Category NotImplemented
    }

}