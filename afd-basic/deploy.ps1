Param (
    [Parameter(HelpMessage = "Deployment target resource group")]
    [string] $ResourceGroupName = "rg-afd-basic",

    [Parameter(HelpMessage = "Azure Front Door name")]
    [string] $FrontDoorName = "afdcontosobasic0001",
    
    [Parameter(HelpMessage = "Backend address 1", Mandatory = $true)]
    [string] $BackendAddress1,
        
    [Parameter(HelpMessage = "Backend address 2", Mandatory = $true)]
    [string] $BackendAddress2,
    
    [Parameter(HelpMessage = "Deployment target resource group location")]
    [string] $Location = "swedencentral",

    [string] $Template = "main.bicep"
)

$ErrorActionPreference = "Stop"

$date = (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss")
$deploymentName = "Local-$date"

if ([string]::IsNullOrEmpty($env:RELEASE_DEFINITIONNAME)) {
    Write-Host (@"
Not executing inside Azure DevOps Release Management.
Make sure you have done "Login-AzAccount" and
"Select-AzSubscription -SubscriptionName name"
so that script continues to work correctly for you.
"@)
}
else {
    $deploymentName = $env:RELEASE_RELEASENAME
}

# Target deployment resource group
if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue)) {
    Write-Warning "Resource group '$ResourceGroupName' doesn't exist and it will be created."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
}

# Additional parameters that we pass to the template deployment
$additionalParameters = New-Object -TypeName hashtable
$additionalParameters['frontDoorName'] = $FrontDoorName
$additionalParameters['backendAddress1'] = $BackendAddress1
$additionalParameters['backendAddress2'] = $BackendAddress2

$result = New-AzResourceGroupDeployment `
    -DeploymentName $deploymentName `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $Template `
    @additionalParameters `
    -Mode Incremental -Force `
    -Verbose

$result
