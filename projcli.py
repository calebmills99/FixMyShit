from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient

project = AIProjectClient(
  endpoint="https://eastus.api.cognitive.microsoft.com/models",  # Replace with your endpoint
AzureKeyCredential=DefaultAzureCredential())