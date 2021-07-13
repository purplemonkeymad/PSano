

class PSanoClipboard : PSanoFile {

    PSanoClipboard() : base("clip://") {
        <#
        path and encoding are not used here as
        clipboards are already converted to
        utf-16
        #>
    }

    [string[]] readFileContents() {
        return ( (Get-Clipboard) -split '\r?\n' )
    }

    [void] writeFileContents([string[]]$Content) {
        $Content | Set-Clipboard -ErrorAction Stop
    }
}