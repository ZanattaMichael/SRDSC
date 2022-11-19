Import-Module SRDSC
Publish-SRActionScript -OutputFilePath ("{0}/New-VirtualMachine.ps1" -f $Global:SRDSC.ScriptRunner.ScriptRunnerDSCRepository)
