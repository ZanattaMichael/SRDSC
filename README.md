# ScriptRunner DSC (SRDSC)

[![Current Dev Build](https://github.com/ZanattaMichael/SRDSC/actions/workflows/Current%20Dev%20Build.yml/badge.svg?event=status)](https://github.com/ZanattaMichael/SRDSC/actions/workflows/Current%20Dev%20Build.yml)
[![Master Build Tests](https://github.com/ZanattaMichael/SRDSC/actions/workflows/Master%20Build%20Tests.yml/badge.svg)](https://github.com/ZanattaMichael/SRDSC/actions/workflows/Master%20Build%20Tests.yml)

Script Runner meet Desired State Configuration! Desired State Configuration meet Script Runner!
SRDSC is a PowerShell Module that integrates Script Runner's portal with Desired State Configuration (using the DSC Toolbox with Datum). It's intention is to enable non-PowerShell users to create infrastructure services, abstracting away the complexities of understanding CaC (Configuration as Code) while Infrastructure teams retain control over key services.

# About

+ Deploys DSC Pull Services on Script Runner Server.
+ Deploys PowerShell DSC Toolbox (with Datum).
+ Add's custom scripts to Script Runner Portal.

# Requirements

+ PowerShell 5.1
+ ScriptRunner Server (Previously installed).
+ Internet Connection (to download dependencies and DSC Resources).
+ Desired State Configuration (Windows Feature Installed)

_Please note that this Module is not supported on PowerShell Core._

# Quick Start Guide

The initialization process performs the following tasks:

1. Creates local configuration store for the Module Configuration elements.
1. Deploys DSC Configuration to Setup:

    1. DSCPullServices.
    1. Files Services for Datum (copying key files).
    1. Files Services for ScriptRunner (copying key files).

1. Downloading the DSC Toolbox (with Datum).
1. Adds Execution Credentials/ Execution Target (with linked Credential) and Scripts (with Schedules) onto the Script Runner Server.

## Quick Start Guide (Self-Signed Certificate)

_(On the ScriptRunner Server)_
1. `Install-Module SRDSC`
1. `Initialize-SRDSC -DatumModulePath C:\Datum -PullWebServerPath C:\Inetpub -ScriptRunnerServerPath 'C:\ProgramData\ScriptRunner' -ScriptRunnerURL http://SCRIPTRUNNER01/ -UseSelfSignedCertificate -ScriptRunnerSACredential (Get-Credential)`

## Quick Start Guide (BYO Certificate)

_(On the ScriptRunner Server)_
1. `Install-Module SRDSC`
1. `Initialize-SRDSC -DatumModulePath C:\Datum -PullWebServerPath C:\Inetpub -ScriptRunnerServerPath 'C:\ProgramData\ScriptRunner' -ScriptRunnerURL http://SCRIPTRUNNER01/ -ScriptRunnerSACredential (Get-Credential) -PFXCertificatePath "C:\MyCertificate.pfx" -PFXCertificatePassword $SecureString`

# Adding a New Virtual Machine



# Future Features

+ DSC Credential Management.
+ Multi-Machine Provisioning.
+ Environment Provisioning.
+ Remove Virtual Machine.
+ Updated handling of Datum's Resolution Precedence.
+ DSC Pull Server Reporting Services.

DSC ScriptRunner
