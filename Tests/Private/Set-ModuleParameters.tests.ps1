Describe "Testing Set-Module Parameters" {

    BeforeAll {
        Backup-SRDSCState
    }

    AfterAll {
        Restore-SRDSCState
    }

    it "Should return an object with the correct properties" {

        #
        # Arrange

        $params = @{
            DatumModulePath = 'MOCK'
            ScriptRunnerModulePath = 'MOCK'
            ScriptRunnerServerPath = 'MOCK'
            PullServerRegistrationKey = 'MOCK'
            DSCPullServer = 'MOCK'
            DSCPullServerHTTP = 'https'
            ScriptRunnerURL = 'MOCK'
            CertificateThumbPrint = 'MOCK'   
        }

        #
        # Act
        Set-ModuleParameters @params
        
        #
        # Assert

        $Global:SRDSC.ScriptRunner.ScriptRunnerURL | Should -Not -BeNullOrEmpty
        $Global:SRDSC.ScriptRunner.ScriptRunnerDSCRepository | Should -Not -BeNullorEmpty
        $Global:SRDSC.ScriptRunner.NodeTemplateFile | Should -Not -BeNullorEmpty
        $Global:SRDSC.ScriptRunner.NodeRegistrationFile | Should -Not -BeNullorEmpty
        $Global:SRDSC.ScriptRunner.ScriptTemplates.NewVMTemplate | Should -Not -BeNullorEmpty

        $Global:SRDSC.DSCPullServer.DSCPullServerName | Should -Not -BeNullorEmpty
        $Global:SRDSC.DSCPullServer.DSCPullServerMOFPath | Should -Not -BeNullorEmpty
        $Global:SRDSC.DSCPullServer.DSCPullServerResourceModules | Should -Not -BeNullorEmpty
        $Global:SRDSC.DSCPullServer.DSCPullServerWebAddress | Should -Not -BeNullorEmpty
        $Global:SRDSC.DSCPullServer.PullServerRegistrationKey | Should -Not -BeNullorEmpty
        $Global:SRDSC.DSCPullServer.CertificateThumbPrint | Should -Not -BeNullOrEmpty

        $Global:SRDSC.DatumModule.DatumModulePath | Should -Not -BeNullOrEmpty
        $Global:SRDSC.DatumModule.DatumTemplates | Should -Not -BeNullOrEmpty
        $Global:SRDSC.DatumModule.NodeRegistrationFile | Should -Not -BeNullorEmpty
        $Global:SRDSC.DatumModule.ConfigurationPath | Should -Not -BeNullorEmpty
        $Global:SRDSC.DatumModule.RenamedMOFOutput | Should -Not -BeNullorEmpty
        $Global:SRDSC.DatumModule.SourcePath | Should -Not -BeNullorEmpty
        $Global:SRDSC.DatumModule.ConfigurationFile | Should -Not -BeNullorEmpty
        $Global:SRDSC.DatumModule.CompiledMOFOutput | Should -Not -BeNullorEmpty
        $Global:SRDSC.DatumModule.CompileCompressedModulesOutput | Should -Not -BeNullorEmpty
        $Global:SRDSC.DatumModule.BuildPath | Should -Not -BeNullorEmpty
        $Global:SRDSC.DatumModule.YAMLSortOrder | Should -Not -BeNullorEmpty

    }

}