$OnRemove = {
    Write-Warning "Module PSano includes classes, removal of module will not clear classes and can cause undefined behavour. It is recomended to restart the powershell process before attempting to import module again."
}

$ExecutionContext.SessionState.Module.OnRemove += $OnRemove