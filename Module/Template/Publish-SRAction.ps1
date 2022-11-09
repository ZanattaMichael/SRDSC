Import-Module SRDSC
Publish-SRActionScript -OutputFilePath ("{0}/New-VirutalMachine.ps1" -f $Global:SRDSC.ScriptRunner.ScriptRunnerDSCRepository)
