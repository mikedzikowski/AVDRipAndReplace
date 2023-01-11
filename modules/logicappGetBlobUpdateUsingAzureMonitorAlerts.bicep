param subscriptionId string
param workflows_GetBlobUpdate_name string
param automationAccountConnectionName string
param automationAccountResourceGroup string
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
            Parse_JSON: [
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
                  '@body(\'Parse_JSON\')?[\'Approval\']'
                  true
                ]
              }
            ]
          }
          type: 'If'
        }
        Alert_Status: {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              properties: {
                parameters: {
                  environment: cloud
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
              runbookName: 'Get-NewBlobAlertStatus'
              wait: waitForRunBook
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Alert_status_output: {
          runAfter: {
            Alert_Status: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureautomation\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Alert_Status\')?[\'properties\']?[\'jobId\'])}/output'
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Parse_JSON: {
          runAfter: {
            Alert_status_output: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Alert_status_output\')'
            schema: {
              properties: {
                Approval: {
                  type: 'boolean'
                }
              }
              type: 'object'
            }
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
        }
      }
    }
  }
}
output blobPrincipalId string = workflows_GetBlobUpdate_name_resource.identity.principalId
