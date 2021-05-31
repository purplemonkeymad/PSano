class PSanoFile {

    [string[]]$FullPath

    PSanoFile([string]$FullPath) {
        $this.FullPath = $FullPath
    }

    [string[]] readFileContents() {
        if ($this.FullPath) {
            # pass issues to Get-Content
            return (Get-Content -LiteralPath $this.FullPath -ErrorAction Stop)
        } else {
            # we want to return something.
            return [string[]]@()
        }
    }

    [void] writeFileContents([string[]]$Content) {
        if ($this.FullPath) {
            # we will just let set-content hanle any issue with the file as it is.
            Set-Content -LiteralPath $this.FullPath -Value $Content -ErrorAction Stop
        } else {
            throw "Path not set, can't save file."
        }
    }

}