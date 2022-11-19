function git() {

    Write-Host "[Git-Override] Invoked:"
    Write-Host "[Git-Override] Args: $Args"
    # Call git with splatting, redirect the output to warning
    # (FYI: Redirecting the output from error to success dosen't work `2>&1`)
    try { 
        & (Get-Command git -commandType Application) @args 2>&1
    }
    catch {
        # Redirect to warning output stream.
        Write-Warning $_ 
    }
}

if ($isModule) { Export-ModuleMember git }