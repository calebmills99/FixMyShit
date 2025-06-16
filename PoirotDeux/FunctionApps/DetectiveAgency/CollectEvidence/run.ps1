using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Write-Host "Detective Poirot 2.0 - Evidence Collection Service"

# Parse the request
$evidence = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    requestId = [guid]::NewGuid().ToString()
    method = $Request.Method
    query = $Request.Query
    body = $Request.Body
}

# Log the evidence
Write-Information "Evidence collected: $($evidence | ConvertTo-Json -Compress)"

# Analyze based on request type
if ($Request.Query.case -or $Request.Body.case) {
    $caseId = $Request.Query.case ?? $Request.Body.case
    $response = @{
        status = "Evidence Collected"
        caseId = $caseId
        detective = "Poirot 2.0"
        message = "The little grey cells are working on case: $caseId"
        timestamp = $evidence.timestamp
    }
} else {
    $response = @{
        status = "Ready"
        detective = "Poirot 2.0"
        message = "Submit evidence with 'case' parameter"
        endpoint = "/api/CollectEvidence?case=YOUR_CASE_ID"
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Headers = @{
        "Content-Type" = "application/json"
    }
    Body = $response | ConvertTo-Json
})
