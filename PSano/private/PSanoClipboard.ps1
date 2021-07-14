<#

Class to edit the clipboard contents.
Since we only support text, and Ps can
see the clipboard as a string[], this
is a small modification on the normal
file writter.

#>

class PSanoClipboard : PSanoFile {

    <# a colon seams the best way to indicated it's not a file.#>
    PSanoClipboard() : base("clipboard:") {
        <#
        path and encoding are not used here as
        clipboards are already converted to
        utf-16
        #>
    }

    <#
    Since the clipboard can be set from a varity of locations,
    It might have been set from another platform and thus
    line ending might not be identified by the command.
    #>

    [string[]] readFileContents() {
        return ( (Get-Clipboard) -split '\r?\n' )
    }

    [void] writeFileContents([string[]]$Content) {
        $Content | Set-Clipboard -ErrorAction Stop
    }
}