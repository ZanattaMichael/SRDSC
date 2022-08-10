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
    #  Start the Build Process

    . $Global:SRDSC.DatumModule.BuildPath @PSBoundParameters

    # If the MOF Registration File is missing, datum nodes aren't being deployed.
    if (-Not(Test-Path -LiteralPath $Global:SRDSC.ScriptRunner.NodeRegistrationFile)) {
        Throw "Missing NodeRegistrationFile"
    }

    #
    # Once the build process has been completed, load the MOF Node Registration File

    $NodeRegistrationFile = Import-Clixml -LiteralPath $Global:SRDSC.ScriptRunner.NodeRegistrationFile

    # Create RenamedMOFOutput directory in the output directory.
    
    $MOFDestinationDir = $(
        if (Test-Path -LiteralPath $Global:SRDSC.DatumModule.RenamedMOFOutput) {
            Get-Item -LiteralPath $Global:SRDSC.DatumModule.RenamedMOFOutput
        } else {
            New-Item -Path $Global:SRDSC.DatumModule.RenamedMOFOutput -Type Directory -ErrorAction Stop
        }
    )   
    
    # This is where the compiled mof's will be copied to.

    #
    # Iterate through each of the mof files in 
    Get-ChildItem -LiteralPath $Global:SRDSC.DatumModule.CompiledMOFOutput -File -Recurse | ForEach-Object {
        
        # Get the Item
        $item = $_

        # Match the NodeName to the FileName.
        $matchedItem = $NodeRegistrationFile | Where-Object { $_.NodeName -eq $item.Name.Split('.')[0] }

        # Don't copy any MOF files that arn't stored within the configuration file.
        if ($matchedItem.count -eq 0) { return }

        # Construct the destination file name.
        # This needs to include the .mof file and .mof.checksum file.
        $destinationFileName = "{0}\{1}.{2}" -f 
            $MOFDestinationDir.FullName
            $matchedItem.ConfigurationID,
            $item.name.split('.')[1..$item.name.split('.').Length] -join '.'

        # Copy the file
        $null = Copy-Item $_.FullName -Destination $destinationFileName -Force

    }

    #
    # Once that's completed, copy the MOFFiles and Resource Directories over to the DSCPullServer

    Get-ChildItem -LiteralPath $MOFDestinationDir.FullName -File | Copy-Item -Destination $Global:SRDSC.DSCPullServer.DSCPullServerMOFPath -Force

    #
    # Now copy the resouce modules to the DSCPullServer

    Get-ChildItem -LiteralPath $Global:SRDSC.DatumModule.CompileCompressedModulesOutput | Copy-Item -Destination $Global:SRDSC.DSCPullServer.DSCPullServerResourceModules -Force

    #
    # Complete

}