# Setup-DetectiveGovernance.ps1
# Establishes proper governance with Azure Policy

# 1. Apply resource naming convention policy
$policyDefinition = @"
{
  "properties": {
    "displayName": "Enforce Detective Agency naming convention",
    "description": "Ensures all resources follow the proper naming convention",
    "parameters": {},
    "policyRule": {
      "if": {
        "not": {
          "field": "name",
          "like": "*detective*"
        }
      },
      "then": {
        "effect": "deny"
      }
    }
  }
}
"@

az policy definition create --name "detective-naming-convention" --display-name "Detective Agency Naming Convention" --description "Ensures proper naming for all detective agency resources" --rules "$policyDefinition" --mode All

# 2. Apply resource tagging policy
az policy assignment create --policy "require-tag-and-value" --display-name "Require Case Number tag" --params "{\"tagName\":{\"value\":\"CaseNumber\"},\"tagValue\":{\"value\":\"required\"}}" --scope "/subscriptions/$(az account show --query id -o tsv)"

# 3. Apply security baseline policies (Azure Security Benchmark)
az policy assignment create --policy "1f3afdf9-d0c9-4c3d-847f-89da613e70a8" --display-name "Apply Security Baseline" --scope "/subscriptions/$(az account show --query id -o tsv)"

# 4. Apply cost management policies
az policy assignment create --policy "09024ccc-0c5f-475e-9457-b7c0d9ed487b" --display-name "Restrict VM SKUs to cost-effective options" --scope "/subscriptions/$(az account show --query id -o tsv)"