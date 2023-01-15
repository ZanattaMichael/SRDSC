#
# Reads the node configuration to get the GUID

function Start-SRDSConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Switch]
        $ResolveDependency
    )

    #
    # This process will compile the Datum Configuration and Push the configuration to the Pull Server
    #
    Write-Host "[Start-SRDSCConfiguration] Starting Build."

    #
    #  Start the Build Process

    . $Global:SRDSC.DatumModule.BuildPath @PSBoundParameters

    #
    # Write Message
    Write-Host "[Start-SRDSCConfiguration] Build Completed. Processing Exportable MOF Files."

    #
    # If the CLIXML file is not present, not to worry! Skip it!
    if (Test-Path -LiteralPath $Global:SRDSC.DatumModule.NodeRegistrationFile) {

        #
        # Once the build process has been completed, load the MOF Node Registration File
        $NodeRegistrationFile = Import-Clixml -LiteralPath $Global:SRDSC.DatumModule.NodeRegistrationFile

    }

    # Create RenamedMOFOutput directory in the output directory.    
    $MOFDestinationDir = $(
        if (Test-Path -LiteralPath $Global:SRDSC.DatumModule.RenamedMOFOutput) {
            Get-Item -LiteralPath $Global:SRDSC.DatumModule.RenamedMOFOutput
        } else {
            New-Item -Path $Global:SRDSC.DatumModule.RenamedMOFOutput -Type Directory -ErrorAction Stop
        }
    )

    #
    # Clear out all existing MOF files to prevent existing configuration from existing
    Write-Host "[Start-SRDSCConfiguration] Clearing out existing MOF files."
    Write-Host "[Start-SRDSCConfiguration] $MOFDestinationDir"
    $MOFDestinationDir | Get-ChildItem -File | Remove-Item -Force -Confirm:$false    

    #
    # If the DSC Pull Server is using Registration ID's, it just needs to perform a normal copy.
    # Copy the mof files and their checksums into the DSCService Directory
    #

    Write-Host "[Start-SRDSCConfiguration] Copying MOF Files to: $($MOFDestinationDir.FullName)"
    Get-ChildItem -LiteralPath $Global:SRDSC.DatumModule.CompiledMOFOutput -File -Recurse | Copy-Item -Destination $MOFDestinationDir.FullName -Force

    #
    # If the DSC Pull Server is Using Configuration Id's, this process will rename them into their respective GUIDS
    #

    # This is where the compiled mof's will be copied to.

    #
    # Iterate through each of the mof files in the output
    Get-ChildItem -LiteralPath $Global:SRDSC.DatumModule.CompiledMOFOutput -File -Recurse | Where-Object {
        $_.Extension -ne '.checksum'
    } | ForEach-Object {
        
        # Get the Item
        $item = $_

        # Match the NodeName to the FileName.
        $matchedItem = $NodeRegistrationFile | Where-Object { $_.NodeName -eq $item.Name.Split('.')[0] }

        # Don't copy any MOF files that arn't stored within the configuration file.
        if ($matchedItem.count -eq 0) { return }

        # If the configuration ID isan't a secure string. Skip
        if ($matchedItem.ConfigurationID -isnot [SecureString]) { return }

        # Construct the destination file name.
        # This needs to include the .mof file and .mof.checksum file.
        $copyMOFParams = @{
            Path = $_.FullName
            Destination = "{0}\{1}.mof" -f `
                $MOFDestinationDir.FullName,
                ($matchedItem.ConfigurationID | ConvertTo-PlainText)
            Force = $true
        }

        # Copy the file
        $null = Copy-Item @copyMOFParams

        $copyChecksumParams = @{
            Path = "{0}.checksum" -f $_.FullName
            Destination = "{0}\{1}.mof.checksum" -f `
                $MOFDestinationDir.FullName,
                ($matchedItem.ConfigurationID | ConvertTo-PlainText)
            Force = $true
        }

        # Copy the Checksum File
        $null = Copy-Item @copyChecksumParams
    }

    #
    # Once that's completed, copy the MOFFiles and Resource Directories over to the DSCPullServer

    Write-Host "[Start-SRDSCConfiguration] Copying MOF Files Resource Directories to the PullServer: $($MOFDestinationDir.FullName)"

    $MOFFileCopyParams = @{
        Destination = "\\{0}\{1}" -f 
            $ENV:COMPUTERNAME, 
            $Global:SRDSC.DSCPullServer.DSCPullServerMOFPath
        Force = $true
    }

    Get-ChildItem -LiteralPath $MOFDestinationDir.FullName -File | Copy-Item @MOFFileCopyParams

    #
    # Now copy the resouce modules to the DSCPullServer

    $MOFResourceCopyParams = @{
        Destination = "\\{0}\{1}" -f 
            $ENV:COMPUTERNAME, 
            $Global:SRDSC.DSCPullServer.DSCPullServerResourceModules
        Force = $true
    }

    Get-ChildItem -LiteralPath $Global:SRDSC.DatumModule.CompileCompressedModulesOutput | Copy-Item @MOFResourceCopyParams

    #
    # Complete

    Write-Host "[Start-SRDSCConfiguration] Completed."

}

if ($isModule) { Export-ModuleMember -Function Start-SRDSConfiguration }