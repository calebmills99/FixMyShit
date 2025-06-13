# First, install the Azure AI SDK
# pip install azure-ai-foundry

from azure.ai.foundry import AIFoundryClient

# Initialize client
project_client = AIFoundryClient(
    subscription_id="831ed202-1c08-4b14-91eb-19ee3e5b3c78",
    resource_group="guardr",
    project_name="midnight"
)

# Deploy your agent
agent = project_client.agents.create_agent(
    model="gpt-4o",  # Your deployment name
    name="midnight",  # Your agent name
    instructions="""You are a Windows 11 system repair specialist focused on fixing service dependencies and system errors. 
    You have access to ESET System Inspector logs and can analyze system crashes."""
)

print("Agent deployed successfully!")
