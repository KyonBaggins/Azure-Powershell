Connect-AzAccount -SubscriptionName '{Subscription name of the LA workspace}'
Select-AzSubscription -SubscriptionId '{Subscription id of the LA workspace}'

$workspaceName = '{Name of the LA workspace}'
$resourcegroup = '{Name of the LA workspace}'

$workspace = Get-AzOperationalInsightsWorkspace -Name $workspaceName -ResourceGroupName $resourcegroup
$workspaceId = $workspace.CustomerId
$workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $workspace.ResourceGroupName -Name $workspace.Name).PrimarySharedKey

if ($workspace.Name -ne $workspaceName)
{
    Write-Error "Unable to find OMS Workspace $workspaceName."
}

$subscriptionList = Get-AzSubscription

foreach ($subscription in $subscriptionList)
{
    Select-AzSubscription -SubscriptionId $subscription.Id

    $vms = Get-AzVM
    foreach ($vm in $vms)
    {
        $location = $vm.Location
        $name = $vm.Name
        $rg = $vm.ResourceGroupName
        $OSType = $vm.StorageProfile.ImageReference
    
        if ($OStype.Offer -eq 'WindowsServer')
        {
            # for Windows VM
            Set-AzVMExtension -ResourceGroupName $rg -VMName $name -Name 'MicrosoftMonitoringAgent' -Publisher 'Microsoft.EnterpriseCloud.Monitoring' -ExtensionType 'MicrosoftMonitoringAgent' -TypeHandlerVersion '1.0' -Location $location -SettingString "{'workspaceId': '$workspaceId'}" -ProtectedSettingString "{'workspaceKey': '$workspaceKey'}" -AsJob
        }
        else 
        {
            # for None-Windows(Linux) VM
            Set-AzVMExtension -ResourceGroupName $rg -VMName $name -Name 'OmsAgentForLinux' -Publisher 'Microsoft.EnterpriseCloud.Monitoring' -ExtensionType 'OmsAgentForLinux' -TypeHandlerVersion '1.0' -Location $location -SettingString "{'workspaceId': '$workspaceId'}" -ProtectedSettingString "{'workspaceKey': '$workspaceKey'}" -AsJob
        }
        Write-Host "Done with VM $($name)."
    }
    Write-Host "Done with Subscription $($subscription.Name)."
}