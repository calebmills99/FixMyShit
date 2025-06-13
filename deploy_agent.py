# First, install the Azure AI SDK
# pip install azure-ai-projects azure-identity

import os
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

# Set up your project endpoint
project_endpoint = os.environ["PROJECT_ENDPOINT"]  # Ensure the PROJECT_ENDPOINT environment variable is set

# Initialize client
project_client = AIProjectClient(
    endpoint=project_endpoint,
    credential=DefaultAzureCredential(),
)

# Deploy your agent
agent = project_client.agents.create_agent(
    model="gpt-4o",  # Your deployment name
    name="mmidnight",  # Your agent name
    instructions="""You are a Windows 11 system repair specialist focused on fixing service dependencies and system errors. 
    You have access to ESET System Inspector logs and can analyze system crashes."""
)

print("Agent deployed successfully!")
