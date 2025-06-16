using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "Detective Poirot 2.0 Evidence Collector activated!"

# Parse the request body
$evidence = $Request.Body

# Log the evidence
Write-Host "Evidence received: $($evidence | ConvertTo-Json -Compress)"

# Analyze the evidence
$analysis = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    caseId = [guid]::NewGuid().ToString()
    evidenceType = $evidence.type
    priority = $evidence.priority
    status = "Under Investigation"
    detective = "Poirot 2.0"
    location = "Canada Central"
}

# Return the analysis
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $analysis | ConvertTo-Json
})
