import os
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

# Set up your project endpoint
# Ensure the PROJECT_ENDPOINT environment variable is set, or hardcode it.
# For example: project_endpoint = "https://<your-project-name>.eastus.inference.ai.azure.com"
try:
    project_endpoint = os.environ["PROJECT_ENDPOINT"]
except KeyError:
    print("Error: PROJECT_ENDPOINT environment variable not set.")
    print("Please set it to your Azure AI Project endpoint.")
    exit(1)

# Initialize client
credential = DefaultAzureCredential()
project_client = AIProjectClient(
    endpoint=project_endpoint,
    credential=credential,
)

# Deploy your agent
try:
    agent = project_client.agents.create_or_update(
        name="midnight-agent",
        version="1",
        properties={
            "model": "gpt-4o",
            "instructions": """You are a Windows 11 system repair specialist focused on fixing service dependencies and system errors.
            You have access to ESET System Inspector logs and can analyze system crashes."""
        }
    )
    print("Agent 'midnight-agent' deployed successfully!")
except Exception as e:
    print(f"Agent deployment failed: {e}")
