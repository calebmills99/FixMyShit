# First, install the Azure AI SDK
# pip install azure-ai-foundry azure-identity

import os
from azure.ai.foundry import AIFoundryClient
from azure.identity import DefaultAzureCredential

# Initialize client
credential = DefaultAzureCredential()
foundry_client = AIFoundryClient(credential=credential)

# Check if workspace exists
workspace_name = "midnight"
workspace = None
for ws in foundry_client.workspaces.list():
    if ws.name == workspace_name:
        workspace = ws
        break

# Create workspace if it doesn't exist
if not workspace:
    print(f"Workspace '{workspace_name}' not found. Creating...")
    workspace = foundry_client.workspaces.create(
        name=workspace_name,
        location="eastus",
        kind="AIProject",
    )
    print(f"Workspace '{workspace_name}' created successfully.")

# Retrieve the correct endpoint
project_endpoint = workspace.endpoint

# Initialize project client
project_client = AIFoundryClient(
    endpoint=project_endpoint,
    credential=credential,
)

# Deploy your agent
agent = project_client.agents.create_agent(
    model="gpt-4o",  # Your deployment name
    name="midnight",  # Corrected agent name to match the Azure project setup
    instructions="""You are a Windows 11 system repair specialist focused on fixing service dependencies and system errors. 
    You have access to ESET System Inspector logs and can analyze system crashes."""
)

print("Agent deployed successfully!")
