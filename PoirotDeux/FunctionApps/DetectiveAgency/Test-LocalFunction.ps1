# Test the local function
$uri = "http://localhost:7071/api/CollectEvidence"
$body = @{
    case = "AZURE-001"
    type = "Deployment Mystery"
    evidence = "Function Apps working in Canada Central"
    priority = "High"
} | ConvertTo-Json

Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
