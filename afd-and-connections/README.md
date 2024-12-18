# Azure Front Door and connections

## Scenario

tba

## Setup

### Variables

```powershell
# FQDN of the AFD:
$domain = "contoso0000000025.swedencentral.cloudapp.azure.com"

# VM password
$vmPasswordPlainText = "<your VM password>"
$vmPassword = ConvertTo-SecureString -String $vmPasswordPlainText -Force -AsPlainText
```

### Deploy

```powershell
$result = .\deploy.ps1 -FrontDoorName "afdcontoso00000001" -VMPassword $vmPassword
$result
$result.outputs.fqdn.value
```

```powershell
# Connect to the VM
$vmPasswordPlainText | clip
mstsc /v:$($result.outputs.vm1PublicIP.value) /f
mstsc /v:$($result.outputs.vm2PublicIP.value) /f
```

### Test

```powershell
start "http://$domain"
start "http://$($result.outputs.vm1.value)"
start "http://$($result.outputs.vm2FQDN.value)"

#
curl "http://$domain" --verbose

# Restart entire IIS
iisreset

# Site restart
. $env:systemroot\system32\inetsrv\AppCmd.exe stop site "Default Web Site"
. $env:systemroot\system32\inetsrv\AppCmd.exe start site "Default Web Site"

# Apppool - overlapped restart
. $env:systemroot\system32\inetsrv\AppCmd.exe recycle apppool "DefaultAppPool"

# Force the VM to be unhealthy (as Probe.aspx monitors this file)
"maintenance" | Out-File -FilePath "C:\maintenance.txt"

# Remove the maintenance file
Remove-Item -Path "C:\maintenance.txt"
```

### Clean up

```powershell
Remove-AzResourceGroup -Name "rg-afd-connections" -Force
```
