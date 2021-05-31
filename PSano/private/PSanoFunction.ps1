class PSanoFunction : PSanoFile {

    PSanoFunction ([string]$FunctionName) : base ($FunctionName) {

    }
    [string[]] readFileContents() {
        $realPath = Join-Path 'function:\' -ChildPath $this.FullPath
        return (
            Get-Content -LiteralPath $realPath -ErrorAction Stop
        ) -split "\n"
    }

    [void] writeFileContents([string[]]$Content) {
        $realPath = Join-Path 'function:\' -ChildPath $this.FullPath
        Set-Content -LiteralPath $realPath -Value (
            $Content -join "`n"
        )
    }
}