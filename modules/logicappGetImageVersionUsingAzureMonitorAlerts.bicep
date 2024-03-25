param workflows_GetImageVersion_name string
param automationAccountConnectionName string
param location string
param state string
param recurrenceFrequency string
param recurrenceInterval int
param recurrenceType string
param automationAccountName string
param automationAccountResourceGroup string
param automationAccountLocation string
param runbookNewHostPoolRipAndReplace string
param getRunbookScheduleRunbookName string
param getRunbookGetSessionHostVm string
param getGetMarketPlaceImageVersion string
param waitForRunBook bool
param identityType string
param startTime string
param dayOfWeek string
param dayOfWeekOccurrence string
param cloud string
param tenantId string
param subscriptionId string
param hostPoolName string
param templateSpecId string
param automationAccountConnectId   string
param imageSource       string
param aibSubscription string

resource  workflows_GetImageVersion_name_resource  'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_GetImageVersion_name
  location: location
  identity: {
    type: identityType
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
      }
      triggers: {
       Recurrence: {
         recurrence: {
           frequency: recurrenceFrequency
           interval: recurrenceInterval
         }
         evaluatedRecurrence: {
           frequency: recurrenceFrequency
           interval: recurrenceInterval
         }
         type: recurrenceType
       }
     }
      actions: {
        Check_for_Exisiting_Runbook_Schedule_for_Hostpool_AVD_Environment: {
          runAfter: {
            Parse_Session_Host_VM_and_RG: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              properties: {
                parameters: {
                  AutomationAccountName: automationAccountName
                  ResourceGroupName: automationAccountResourceGroup
                  runbookName: runbookNewHostPoolRipAndReplace
                  Environment: cloud
                  HostpoolName: hostPoolName
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs')
            queries: {
              runbookName: getRunbookScheduleRunbookName
              wait: waitForRunBook
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Condition_Check_for_Runbook_Schedule_and_Image_Version_on_AVD_Environment: {
          actions: {
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
                path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs')
                queries: {
                  runbookName: 'Get-NewImageAlertStatus'
                  wait: true
                  'x-ms-api-version': '2015-10-31'
                }
              }
            }
            Alert_Status_Output: {
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
            Condition: {
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
                          ImageSource: imageSource
                          aibSubscription: aibSubscription
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
                      wait: true
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
                  Terminate_2: {
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
            Parse_JSON: {
              runAfter: {
                Alert_Status_Output: [
                  'Succeeded'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'Alert_Status_Output\')'
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
          runAfter: {
            Parse_image_version: [
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
                  '@body(\'Parse_Schedule\')?[\'ScheduleFound\']'
                  false
                ]
              }
              {
                equals: [
                  '@body(\'Parse_image_version\')?[\'NewImageFound\']'
                  true
                ]
              }
            ]
          }
          type: 'If'
        }
        Get_Image_Version_of_Sessionhost_in_AVD_Environment: {
          runAfter: {
            Parse_Schedule: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              properties: {
                parameters: {
                  ResourceGroupName: '@body(\'Parse_Session_Host_VM_and_RG\')?[\'productionVmRg\']'
                  VMName: '@body(\'Parse_Session_Host_VM_and_RG\')?[\'productionVm\']'
                  environment: cloud
                  ImageSource      : imageSource
                  aibSubscription: aibSubscription
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
              runbookName: getGetMarketPlaceImageVersion
              wait: true
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_Job_Output: {
          runAfter: {
            Get_Session_Host_Information_Resource_Group_and_Virtual_Machine_Name: [
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Get_Session_Host_Information_Resource_Group_and_Virtual_Machine_Name\')?[\'properties\']?[\'jobId\'])}/output')
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_Job_Output_of_Marketplace_Image_Version: {
          runAfter: {
            Get_Image_Version_of_Sessionhost_in_AVD_Environment: [
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Get_Image_Version_of_Sessionhost_in_AVD_Environment\')?[\'properties\']?[\'jobId\'])}/output')
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        'Get_Output_from_Runbook_Get-RunBookSchedule': {
          runAfter: {
            Check_for_Exisiting_Runbook_Schedule_for_Hostpool_AVD_Environment: [
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs/@{encodeURIComponent(body(\'Check_for_Exisiting_Runbook_Schedule_for_Hostpool_AVD_Environment\')?[\'properties\']?[\'jobId\'])}/output')
            queries: {
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Get_Session_Host_Information_Resource_Group_and_Virtual_Machine_Name: {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              properties: {
                parameters: {
                  environment: cloud
                  hostpoolName: hostPoolName
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
            path: concat('/subscriptions/@{encodeURIComponent(\'${subscriptionId}\')}/resourceGroups/@{encodeURIComponent(\'${automationAccountResourceGroup}\')}/providers/Microsoft.Automation/automationAccounts/@{encodeURIComponent(\'${automationAccountName}\')}/jobs')
            queries: {
              runbookName: getRunbookGetSessionHostVm
              wait: true
              'x-ms-api-version': '2015-10-31'
            }
          }
        }
        Parse_Schedule: {
          runAfter: {
            'Get_Output_from_Runbook_Get-RunBookSchedule': [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_Output_from_Runbook_Get-RunBookSchedule\')'
            schema: {
              properties: {
                ScheduleFound: {
                  type: 'boolean'
                }
              }
              type: 'object'
            }
          }
        }
        Parse_Session_Host_VM_and_RG: {
          runAfter: {
            Get_Job_Output: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_job_output\')'
            schema: {
              properties: {
                hostPool: {
                  type: 'string'
                }
                productionVM: {
                  type: 'string'
                }
                productionVmRg: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
        Parse_image_version: {
          runAfter: {
            Get_Job_Output_of_Marketplace_Image_Version: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Get_Job_Output_of_Marketplace_Image_Version\')'
            schema: {
              properties: {
                ImageVersion: {
                  type: 'string'
                }
                NewImageFound: {
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
            connectionId: automationAccountConnectId
            connectionName: automationAccountConnectionName
            connectionProperties:{
            authentication: {
              type: 'ManagedServiceIdentity'
            }
          }
            id: concat('/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${automationAccountLocation}/managedApis/azureautomation')
          }
        }
      }
    }
  }
}
output imagePrincipalId string = workflows_GetImageVersion_name_resource.identity.principalId
