# Project

Repo for a logic app and set of automation scripts to rip and replace your AVD enviornment...in beta (ish) now!

# PreReqs

1. Azure Bicep

    [Install Bicep tools](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)

# Using the Rip and Replace Logic App solution

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

4. Manual Steps


## Key Vault Secrets
 The following values will be required at runtime:

* "DomainUserPrincipalName" - Domain join user for the Azure Active Directory environment
* "DomainPassword" - Domain join password for the djuser
* "LocalAdminUsername" - The name of the vmuser for the virtual machine infastructure
* "LocalAdminPassword' - The password for the virtual machine infrastructure

## Authenticate API connector for Office 365

The solution uses the [O365 connector](https://docs.microsoft.com/en-us/connectors/office365connector/) to automate the task of sending an approval workflow e-mail.

After the solution is deployed the O365 connector must be authenticated.

![o365auth](https://user-images.githubusercontent.com/34066455/188218548-c2ec79f7-43cb-40f7-9c2c-9009a820845d.gif)

Refence Links for the O365 Connector:
[Connect using other accounts](https://docs.microsoft.com/en-us/azure/connectors/connectors-create-api-office365-outlook#connect-using-other-accounts)



