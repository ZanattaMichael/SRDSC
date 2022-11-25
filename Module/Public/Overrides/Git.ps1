function git() {
<#
.Description
Git.exe has issues with STDOUT to the PowerShell pipeline, causing exceptions to be
raised. This proxy function handles all git requests within a try/catch redirecting
errors into the warning stream. (Git's not required in this implementation).

.SYNOPSIS
Proxy function to handle git's redirect streams.
#> 

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