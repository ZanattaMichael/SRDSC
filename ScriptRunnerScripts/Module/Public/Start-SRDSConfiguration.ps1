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

    . $Global:ScriptRunner.DatumModule.BuildPath @PSBoundParameters

    #
    # Once the build process has been completed, load the MOF Node Registration File
    $MOFNodeRegistrationFile = Import-Clixml -LiteralPath $Global:ScriptRunner.DSCPullServer.MOFNodeRegistrationFile

    # Create RenamedMOFOutput directory in the output directory.
    
    $MOFDestinationDir = $(
        if (Test-Path -LiteralPath $Global:ScriptRunner.DatumModule.RenamedMOFOutput) {
            Get-Item -LiteralPath $Global:ScriptRunner.DatumModule.RenamedMOFOutput
        } else {
            New-Item -Path $Global:ScriptRunner.DatumModule.RenamedMOFOutput -Type Directory -ErrorAction Stop
        }
    )   
    
    # This is where the compiled mof's will be copied to.

    #
    # Iterate through each of the mof files in 
    Get-ChildItem -LiteralPath $Global:ScriptRunner.DatumModule.CompiledMOFOutput -File -Recurse | ForEach-Object {
        
        # Get the Item
        $item = $_

        # Match the NodeName to the FileName.
        $matchedItem = $MOFNodeRegistrationFile | Where-Object { $_.NodeName -eq $item.Name.Split('.')[0] }

        # Don't copy any MOF files that arn't stored within the configuration file.
        if ($matchedItem.count -eq 0) { return }

        # Construct the destination file name.
        # This needs to include the .mof file and .mof.checksum file.
        $destinationFileName = "{0}\{1}.{2}" -f 
            $MOFDestinationDir.FullName
            $matchedItem.registrationId,
            $item.name.split('.')[1..$item.name.split('.').Length] -join '.'

        # Copy the file
        $null = Copy-Item $_.FullName -Destination $destinationFileName -Force

    }

    #
    # Once that's completed, copy MOFFiles and Resource Directories over to the DSCPullServer

    #TODO: Add logic to copy mof configurations to DSC pull server.

}