
#region  PREREQ

$Settings = Get-Content -Path './_general.json' | ConvertFrom-Json

# Login
$loginProps = @{
    Tenant       = 'tenant-id'
    AccountId    = "my.account@mydomain.com"
    Subscription = 'subscription-id'
}
Connect-AzAccount @loginProps

# Check
Get-AzContext

# Create Resource group
$rgName = 'STG-TEST'
New-AzResourceGroup -Name $rgName -Location $Settings.region

# NSG
$nsgProp = @{
    Name              = ("NSG_{0}" -f (get-date -f s).replace(':', ''))
    ResourceGroupName = $rgName
    TemplateFile      = './prereq/aadds_nsg.bicep'
}
$aaddsNsg = New-AzResourceGroupDeployment @nsgProp
$aaddsNsg

# Update AADDS subnet with NSG
foreach ($subnet in $Settings.virtualNetwork.subnets){
    if ($subnet.sNetName -eq 'AADDS'){
        $subnet.nsg = $aaddsNsg.Outputs.nsgRecID.Value
    }
}

# Save back to settings
Set-Content -Path './_general.json' -Value ($Settings|ConvertTo-Json -Depth 10) -Encoding utf8

# vNET
$vnetProp = @{
    Name              = ("vNet-sNet_{0}" -f (get-date -f s).replace(':', ''))
    ResourceGroupName = $rgName
    TemplateFile      = './prereq/vnet.bicep'
}
New-AzResourceGroupDeployment @vnetProp

# AADDS 
Register-AzResourceProvider -ProviderNamespace Microsoft.AAD
New-AzADServicePrincipal -AppId "6ba9a5d4-8456-4118-b521-9c5ca10cdf84"

$AADGroup = @{
    DisplayName = "AAD DC Administrators"
    Description = "Delegated group to administer Azure AD Domain Services"
    SecurityEnabled = $true
    MailEnabled = $false 
    MailNickName = "AADDCAdministrators"
}
New-AzADGroup @AADGroup

# First, retrieve the object ID of the newly created 'AAD DC Administrators' group.
$GroupObjectId = Get-AzADGroup -Filter "DisplayName eq 'AAD DC Administrators'" | Select-Object Id

# Add the user to the 'AAD DC Administrators' group.
Add-AzADGroupMember -TargetGroupObjectId $GroupObjectId.id -MemberUserPrincipalName $loginProps.AccountId

# Create AADDS
$vNetName =   "$($Settings.companyAbbreviation)-$($Settings.virtualNetwork.vNetName)-vnet"
$aaddsProp = @{
    Name              = ("AADDS_{0}" -f (get-date -f s).replace(':', ''))
    ResourceGroupName = $rgName
    TemplateFile      = './prereq/aadds.bicep'
    SubNetResourceId = "/subscriptions/$($loginProps.Subscription)/resourceGroups/$rgName/providers/Microsoft.Network/virtualNetworks/$vNetName/subnets/aadds-snet"
}
New-AzResourceGroupDeployment @aaddsProp

# SET DNS
$dnsProp = @{
    Name              = ("vnet_DNS_{0}" -f (get-date -f s).replace(':', ''))
    ResourceGroupName = $rgName
    TemplateFile      = './prereq/set-vnet-dns.bicep'
}
New-AzResourceGroupDeployment @dnsProp


#endregion

#region DEMO

# Storage Account Name
$stName = 'stgtest0101'

# Create Storage Account via BICEP
$stDeployment = @{
    Name               = ("StorageAccount_{0}" -f (get-date -f s).replace(':', ''))
    ResourceGroupName  = $rgName
    TemplateFile       = './2.storage.bicep'
    storageAccountName = $stName
}
New-AzResourceGroupDeployment @stDeployment

# Check the portal
# Account exists, AAD connected

# Show FILE SHARE BICEP TEMPLATE

# Create fileshare via BICEP with RBAC
$fsDeployment = @{
    Name                    = ("FileShare_BICEP_{0}" -f (get-date -f s).replace(':', ''))
    ResourceGroupName       = $rgName
    TemplateFile            = './3.fileshare-w-permissions.bicep'
    TemplateParameterObject = @{
        existingStorageAccount = $stName
        fileshareName          = 'bicep'
        permissionRoleGuid     = '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb' # Get-AzRoleDefinition | ? name -like Storage*|select name, id
        groupsOid              = @('767dae6c-4043-4c37-82c8-eaf406bcf642') # Economy Data Users, Get-AzADGroup -DisplayName 'Economy Data Users'
    }
}

# EXPLANATION: Role definition to set on the share
Get-AzRoleDefinition | Where-Object name -like 'Storage File *' | Select-Object name, id

# EXPLANATION: To group
Get-AzADGroup -DisplayName 'Economy Data Users'

# Do the ACTUAL DEPLOYMENT
New-AzResourceGroupDeployment @fsDeployment

# Check the permissions - portal

# Check the permissions via PS
Get-AzRoleAssignment | Where-Object Scope -like '*storageaccount*' | Select-Object displayname, scope | Sort-Object Scope

# Create new share and set permission via portal

# Check the permissions via PS
Get-AzRoleAssignment | Where-Object Scope -like '*storageaccount*' | Select-Object displayname, scope | Sort-Object Scope

# WHY?
https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/allversions


## SOLUTION
# Create fileshare via BICEP and ARM, USING THE RESOURCE ID as SCOPE
$fsArmDeployment = @{
    Name                    = ("FileShare_BICEP_ARM_{0}" -f (get-date -f s).replace(':', ''))
    ResourceGroupName       = $rgName
    TemplateFile            = '4.fileshare-w-permissions-and-arm.bicep'
    TemplateParameterObject = @{
        existingStorageAccount = $stName
        fileshareName          = 'biceparm'
        permissionRoleGuid     = '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'
        groupsOid              = '767dae6c-4043-4c37-82c8-eaf406bcf642'
    }
}
New-AzResourceGroupDeployment @fsArmDeployment

# Check the permissions via PS
Get-AzRoleAssignment | Where-Object Scope -like '*storageaccount*' | Select-Object displayname, scope | Sort-Object Scope

# GitHub Issue
https://github.com/Azure/bicep/issues/6100


#endregion

#region RINSE

Remove-AzResourceGroup -Name $rgName -Force

#endregion
