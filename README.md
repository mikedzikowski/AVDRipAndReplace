# Project

Repo for a logic app and set of automation scripts to rip and replace your AVD enviornment...in beta (ish) now!

# PreReqs

1. Azure Bicep

    [Install Bicep tools](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)

# Using the AVD Rip and Replace Logic App solution

1. You can build the bicep code by running the following:

```PowerShell
    bicep build .\main.bicep
```

2. If using JSON, create a parameters file for main.json

    [Associating a parameter file with an ARM template](https://marketplace.visualstudio.com/items?itemName=msazurermtools.azurerm-vscode-tools#parameter-files)

3. Run the following command to deploy the solution

```PowerShell
    New-AzDeployment -name 'Avd-LogicApp-RipAndReplace' -TemplateFile .\main.json -TemplateParameterFile .\main.parameters.json -Verbose -Location usgovvirginia
```

4. Resource Pre-Reqs


## Key Vault Secrets
 The following values will be required to have been created in a keyvault to be used with the template spec:

* "DomainUserPrincipalName" - Domain join user for the Azure Active Directory environment
* "DomainPassword" - Domain join password for the djuser
* "LocalAdminUsername" - The name of the vmuser for the virtual machine infastructure
* "LocalAdminPassword' - The password for the virtual machine infrastructure

## Template Spec

* A template spec should be created to support the rip and replace of the AVD environment. The resource id of the template spec will be selected during deployment of the solution.

The powershell script included in the AVDRipAndReplace repository - [New-AvdTemplateSpec.ps1](https://github.com/mikedzikowski/AVDRipAndReplace/blob/main/templateSpec/New-AvdTemplateSpec.ps1) can assist with automating the creation of the template spec.

## Authenticate API connector for Office 365

If the O365 connector deployment option is selected the solution uses the [O365 connector](https://docs.microsoft.com/en-us/connectors/office365connector/) to automate the task of sending an approval workflow e-mail.

After the solution is deployed the O365 connector must be authenticated.

![o365auth](https://user-images.githubusercontent.com/34066455/188218548-c2ec79f7-43cb-40f7-9c2c-9009a820845d.gif)

Refence Links for the O365 Connector:
[Connect using other accounts](https://docs.microsoft.com/en-us/azure/connectors/connectors-create-api-office365-outlook#connect-using-other-accounts)

### Azure Portal


| Deployment Type | Link |
|:--|:--|
| Azure portal UI | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmikedzikowski%2FAVDRipAndReplace%2Fmain%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fmikedzikowski%2FAVDRipAndReplace%2Fmain%2Fui.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmikedzikowski%2FAVDRipAndReplace%2Fmain%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fmikedzikowski%2FAVDRipAndReplace%2Fmain%2Fui.json) |
| Command line (Bicep/ARM) | [![Powershell/Azure CLI](./images/powershell.png)](https://github.com/mikedzikowski/AVDRipAndReplace#using-the-rip-and-replace-logic-app-solution) |
