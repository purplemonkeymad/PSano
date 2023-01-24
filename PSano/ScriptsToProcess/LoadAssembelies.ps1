# this runs in caller context so plan is no variables

@(
        [pscustomobject]@{File = 'lib\netstandard1.0\System.ValueTuple.dll'; Package = 'System.ValueTuple'}
        [pscustomobject]@{File = 'lib\netstandard2.0\NStack.dll'; Package = 'NStack.Core'}
        [pscustomobject]@{File = 'lib\netstandard2.0\Terminal.Gui.dll'; Package = 'Terminal.Gui'}
) | ForEach-Object {
        # nested join-path as 5.1 does not support additional child path param
        try{ 
                Add-Type -Path (Join-Path $PSScriptRoot (Join-Path ".." $_.File ) ) -ErrorAction Stop
                return #sucess
        } catch {
                Write-Warning "Import of library $($_.TargetObject) failed. Looking for installed packages instead."
        }
        Get-Package $_.Package | 
                Add-Member -MemberType NoteProperty -Name file -Value $_.File -PassThru |
                Sort-Object Version -Descending | 
                Select-Object -First 1 | ForEach-Object {

                # package is installed so we can use that instead.
                Join-Path -Path (
                        Split-Path $_.Source -Parent
                ) -ChildPath $_.File
        } | ForEach-Object {
                Add-Type -Path $_ -ErrorAction Stop
        }

}