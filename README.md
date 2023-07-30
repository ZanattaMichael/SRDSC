# ScriptRunner DSC (SRDSC)

[![Current Dev Build](https://github.com/ZanattaMichael/SRDSC/actions/workflows/Current%20Dev%20Build.yml/badge.svg?event=status)](https://github.com/ZanattaMichael/SRDSC/actions/workflows/Current%20Dev%20Build.yml)
[![Master Build Tests](https://github.com/ZanattaMichael/SRDSC/actions/workflows/Master%20Build%20Tests.yml/badge.svg)](https://github.com/ZanattaMichael/SRDSC/actions/workflows/Master%20Build%20Tests.yml)

Introducing SRDSC - a PowerShell module that bridges the gap between Script Runner and Desired State Configuration (DSC) using the DSC Toolbox with Datum. With SRDSC, non-PowerShell users can create infrastructure services without having to understand the complexities of Configuration as Code (CaC). This allows infrastructure teams to retain control over key services while abstracting away the technical details for non-PowerShell users. So, let's introduce Script Runner to Desired State Configuration and make infrastructure management easier for everyone!

# About

+ The Script Runner Server will have DSC Pull Services deployed on it.
+ The PowerShell DSC Toolbox (with Datum) will be deployed.
+ Custom scripts will be added to the Script Runner Portal.

# Requirements

+ PowerShell 5.1
+ ScriptRunner Server (Previously installed).
+ Internet Connection (to download dependencies and DSC Resources).
+ Desired State Configuration (Windows Feature Installed)

_Please note that this Module is not supported on PowerShell Core._

# Quick Start Guide

1. Install SRDSC and Initialize (Refer to 'Quick Start Guide (Self-Signed Certificate)' or 'Quick Start Guide (BYO Certificate)')

    The initialization process includes the following actions:

    1. Establishes a local configuration storage for the Module Configuration components.
    1. Deploys the DSC Configuration to Setup by performing the following subtasks:
        1. Configures DSCPullServices.
        1. Copies key files to Datum Files Services.
        1. Copies key files to ScriptRunner Files Services.
    1. Downloads the DSC Toolbox (with Datum).
    1. Adds Execution Credentials/Execution Target (with linked Credential) and Scripts (with Schedules) onto the Script Runner Server.

1. After completion, create a DNS alias (CNAME) `dsc.domain.name` pointing to the Script Runner portal. This alias is vital for the proper functioning of DSC Pull Services and its absence will cause onboarding issues with the Pull Server.

## Quick Start Guide (Self-Signed Certificate)

_(On the ScriptRunner Server)_
1. `Install-Module PowerShell-YAML, xPSDesiredStateConfiguration`
1. `Install-Module SRDSC -AllowPrerelease`
1. `Initialize-SRDSC -DatumModulePath C:\Datum -PullWebServerPath C:\Inetpub -ScriptRunnerServerPath 'C:\ProgramData\ScriptRunner' -ScriptRunnerURL http://SCRIPTRUNNER01/ -UseSelfSignedCertificate -ScriptRunnerSACredential (Get-Credential)`

>Please Note: The self-signed certificate will need to be trusted at the endpoint.

Exporting the Self-Signed Certificate (public-key) from the Script Runner Server:

`(Get-ChildItem Cert:\LocalMachine\ -Recurse | Where-Object {$_.Subject -like ('*DSC.{0}*' -f $ENV:USERDNSDOMAIN)})[0] | Export-Certificate -Force -FilePath C:\your-file-path\cert.crt`

Copy the file to the endpoint node and importing the certificate:

`Import-Certificate -FilePath "C:\your-path\cert.crt" -CertStoreLocation 'Cert:\LocalMachine\Root'`

## Quick Start Guide (BYO Certificate)

_(On the ScriptRunner Server)_
1. `Install-Module SRDSC -AllowPrerelease`
1. `Initialize-SRDSC -DatumModulePath C:\Datum -PullWebServerPath C:\Inetpub -ScriptRunnerServerPath 'C:\ProgramData\ScriptRunner' -ScriptRunnerURL http://SCRIPTRUNNER01/ -ScriptRunnerSACredential (Get-Credential) -PFXCertificatePath "C:\MyCertificate.pfx" -PFXCertificatePassword $SecureString`

# Creating your own template

Within SRDSC, there is a preloaded template file called 'NodeTemplateConfiguration.yml' which can be found in the 'Datum\SRDSCTemplates' directory. The term 'Datum' refers to the location of the datum PowerShell module, which is defined by using `-DatumModulePath` in the `Initialize-SRDSC` command. Below is an example of how this template file may look like:

Sample Template File:
``` YAML
NodeName: '%%SR_PARAM_OVERRIDE%%'
Environment: '[x={ $File.Directory.BaseName } =]'
Role: '%%SR_PARAM%%'
Description: '[x= "$($Node.Role) in $($Node.Environment)" =]'
Location: '%%SR_PARAM%%'
Baseline: '%%SR_PARAM%%'

NetworkIpConfiguration:
  Interfaces:
    - InterfaceAlias: 0
      IpAddress: '%%SR_PARAM%%'
      Prefix: 24
      Gateway: '%%SR_PARAM&EXP=[ValidateSet(''192.168.1.254'',''192.168.2.254'')]%%'
      DnsServer:
        - '%%SR_PARAM%%'
        - '%%SR_PARAM%%'
      DisableNetbios: true
```

The template file contains two types of parameters that require customization:

%%SR_PARAM%% - This parameter specifies which DSC Resource parameters should be included as script parameters in New-SRDSCVirtualMachine. If the datum configuration elements such as Location or Baseline are present in the file structure, their corresponding values will be automatically filled in. It is important to note that the datum configuration takes precedence over other configurations. If no configuration is found, a static variable can be inputted.

%%SR_PARAM_OVERRIDE%% - This parameter allows the user to include a static script parameter for a DSC resource name or a specific datum configuration element. In case a matching datum configuration element is detected, this parameter will take precedence over it and permit the user to provide their custom value.

If you want to use custom PowerShell [parameter input validation](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/validating-parameter-input?view=powershell-7.3), you can do so by using `&EXP=` to interpolate the expression. In case no validation is specified, the default [ValidateIsNullOrEmpty()] will be used. For Example:

``` YAML
# SVR-EXCH-1, SVR-DC-2
NodeName: '%%SR_PARAM_OVERRIDE&EXP=[ValidatePattern(''^SVR-.+-[0-9]$'')]%%'
Environment: '[x={ $File.Directory.BaseName } =]'
```

# Onboarding a New Machine into SRDSC

Perform the following steps to onboard a Node into DSC using Script Runner Portal:

1. Open the Script Runner Portal.
1. Click on 'Actions'.
1. Enter the 'DSC' tag.
1. Run 'New-VirtualMachine' and provide the necessary parameters.
1. Execute the command.

The above steps will parse the parameters and associate them with the configuration, generate the YML configuration and store it within the datum configuration, and finally onboard the Node into DSC.

When you run Start-SRDSCConfiguration next time, the configuration will be pushed to the DSC Pull server. Once pushed, the machine will retrieve the configuration from the pull server.

# What happens if there are no parameter in New-VirtualMachine?

If there are no parameters provided in the New-VirtualMachine command, you can update its parameters by manually running Publish-SRAction in Script Runner. This will initiate the pre-parsing process and allow you to update the necessary parameters for New-VirtualMachine.

# Future Features

Here are some of the future features that can be implemented:

__Pull Server Self-Signed Certificate Export__

+ This feature will export the certificate from the Pull Server and add it to the node during onboarding, if the Pull Server is running with a self-signed certificate. This will ensure secure communication between the node and the Pull Server.

__Custom Parameter Validation for Static Entities__

+ The Validate* functionality can be added to `%%SR_PARAM_OVERRIDE%%` and `%%SR_PARAM%%` to enable custom parameter validation on static entities. This will ensure that only valid parameters are passed to the entities.

__DSC Invoke Resource Implementation__

+ The DSC Invoke Resource can be implemented to allow invoking PowerShell commands on managed nodes. This will provide greater flexibility in managing the configuration of nodes.

__DSC Credential Management__

+ This feature will enable credential management for DSC configurations. This will allow managing the credentials required for configuring nodes securely.

__Multi-Machine Provisioning__

+ Multi-machine provisioning will allow configuring multiple machines at once using a single DSC configuration. This will save time and effort in configuring multiple machines individually.

__Multiple Template Files__

+ The ability to use multiple template files will be added, allowing users to specify different templates for different nodes. This will provide greater flexibility in managing the configuration of nodes.

__Environment Provisioning__

+ This feature will enable environment provisioning, allowing users to configure nodes based on their environment. This will help in managing the configuration of nodes across different environments.

__Virtual Machine Removal__

+ The ability to remove virtual machines will be added to the tool, allowing users to remove virtual machines that are no longer required.

__Updated Datum Resolution Precedence Handling__

+ The handling of Datum's Resolution Precedence will be updated to improve its accuracy and efficiency.

__DSC Pull Server Reporting Services__

+ This feature will enable reporting services for the DSC Pull Server, providing insights into the configuration of nodes.

__Datum Git Pipeline Support__

+ This feature will enable support for Datum Git Pipeline, allowing users to manage their DSC configurations using Git.