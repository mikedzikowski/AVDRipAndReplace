param subscriptionId string
param workflows_GetBlobUpdate_name string
param automationAccountConnectionName string
param automationAccountResourceGroup string
param automationAccountLocation string
param automationAccountName string
param blobConnectionName string
param location string
param identityType string
param state string
param schema string
param contentVersion string
param connectionType string
param triggerFrequency string
param triggerInterval int
param container string
param hostPoolName string
param checkBothCreatedAndModifiedDateTime bool
param maxFileCount int
param runbookNewHostPoolRipAndReplace string
param storageAccountName string
param waitForRunBook bool
param emailContact string
param officeConnectionName string
param startTime string
param dayOfWeek string
param dayOfWeekOccurrence string
param cloud string
param tenantId string
param templateSpecId string

resource workflows_GetBlobUpdate_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_GetBlobUpdate_name
  location: location
  tags: {}
  identity: {
    type: identityType
  }
  properties: {
    state: state
    definition: {
      '$schema': schema
      contentVersion: contentVersion
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: connectionType
        }
      }
      triggers: {
        When_a_software_package_is_added_to_storage_account_container_for_AVD: {
          recurrence: {
            frequency: triggerFrequency
            interval: triggerInterval
          }
          evaluatedRecurrence: {
            frequency: triggerFrequency
            interval: triggerInterval
          }
          splitOn: '@triggerBody()'
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${storageAccountName}\'))}/triggers/batch/onupdatedfile'
            queries: {
              checkBothCreatedAndModifiedDateTime: checkBothCreatedAndModifiedDateTime
              folderId: '/${container}'
              maxFileCount: maxFileCount
            }
          }
        }
      }
      actions: {
        Condition_Check_for_Approval_Selection_in_Email: {
          actions: {
            Create_Schedule_for_Hostpool_Rip_and_Replace_on_AVD_Environment: {
              runAfter: {
              }
              type: 'ApiConnection'
              inputs: {
                body: {
                  properties: {
                    parameters: {
                      AutomationAccountName: automationAccountName
                      ResourceGroupName: automationAccountResourceGroup
                      ScheduleName: '${hostPoolName}-ScheduleForRipAndReplace'
                      StartTime: startTime
                      DayOfWeek: dayOfWeek
                      DayOfWeekOccurrence: dayOfWeekOccurrence
                      environment: cloud
                      runbookName: runbookNewHostPoolRipAndReplace
                      HostPoolName: hostPoolName
                      TenantId: tenantId
                      TemplateSpecId: templateSpecId
                      SubscriptionId: subscriptionId
                    }
                  }
                }
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
                  }
                }
                method: 'put'
                path: '/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs'
                queries: {
                  runbookName: 'New-AutomationSchedule'
                  wait: waitForRunBook
                  'x-ms-api-version': '2015-10-31'
                }
              }
            }
          }
          runAfter: {
            Send_Approval_Email_for_Rip_and_Replace_in_AVD_Environment: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Terminate: {
                runAfter: {
                }
                type: 'Terminate'
                inputs: {
                  runStatus: 'Cancelled'
                }
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@body(\'Send_Approval_Email_for_Rip_and_Replace_in_AVD_Environment\')?[\'SelectedOption\']'
                  'Approve'
                ]
              }
            ]
          }
          type: 'If'
        }
        Send_Approval_Email_for_Rip_and_Replace_in_AVD_Environment: {
          runAfter: {
          }
          type: 'ApiConnectionWebhook'
          inputs: {
            body: {
              Message: {
                HideHTMLMessage: false
                Importance: 'High'
                Options: 'Approve, Reject'
                ShowHTMLConfirmationDialog: false
                Subject: 'Software Update Found for AVD Hostpool Environment - Please Approve or Reject the Rip and Replace of the AVD Environment'
                To: emailContact
              }
              NotificationUrl: '@{listCallbackUrl()}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            path: '/approvalmail/$subscriptions'
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          azureautomation: {
            connectionId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${automationAccountConnectionName}'
            connectionName: automationAccountConnectionName
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureautomation'
          }
          azureblob: {
            connectionId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${blobConnectionName}'
            connectionName: blobConnectionName
            id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
          }
          office365: {
            connectionId: '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${officeConnectionName}'
            connectionName: officeConnectionName
            id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${automationAccountLocation}/managedApis/office365'
          }
        }
      }
    }
  }
}

output blobPrincipalId string = workflows_GetBlobUpdate_name_resource.identity.principalId
