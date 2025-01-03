# Azure Front Door

[Configure rule sets in Azure Front Door](https://learn.microsoft.com/en-us/azure/frontdoor/standard-premium/how-to-configure-rule-set)

[Cache purging in Azure Front Door with Azure PowerShell](https://learn.microsoft.com/en-us/azure/frontdoor/standard-premium/how-to-cache-purge-powershell)

## Setup

### Deploy

```powershell
$result = .\deploy.ps1 -BackendAddress "app.contoso.com"
$result
$result.outputs.fqdn.value

$domain = $result.outputs.fqdn.value
```

How many 
[POPs](https://learn.microsoft.com/en-us/azure/frontdoor/edge-locations-by-region)
have been used:

```sql
AzureDiagnostics
| where Category == "FrontDoorAccessLog"
| summarize Count=count(pop_s) by pop_s
```

### Test

Check `X-Cache` header if it is `TCP_HIT` or `TCP_MISS`.

```powershell
curl "https://$domain/" --verbose
curl "https://$domain/pages/echo" --verbose
curl "https://$domain/pages/echocache" --verbose

curl "https://$domain/pages/echo?id=$([Guid]::NewGuid().Guid)" --verbose


curl --data "{ 'data': 'DROP TABLE People'  }" -H "Content-Type: application/json" "https://$domain/api/echo" --verbose
```

```bash
ab -n 1000 -c 25 https://$domain/
```

### Clean up

```powershell
Remove-AzResourceGroup -Name "rg-afd-basic" -Force
```
