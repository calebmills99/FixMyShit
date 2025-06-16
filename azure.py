import os
import openai
from openai import AzureOpenAI

client = AzureOpenAI(
    api_version="2024-12-01-preview",
    endpoint="https://eastus.api.cognitive.microsoft.com/",
    credential=AzureKeyCredential("3INQ78OeO7B8xXMNd8b908h8YuZuf9DE7sBWdFLk502b1LzuwZ4UJQQJ99BFACYeBjFXJ3w3AAABACOGeHQJ"),
    AzureKeyCredential="3INQ78OeO7B8xXMNd8b908h8YuZuf9DE7sBWdFLk502b1LzuwZ4UJQQJ99BFACYeBjFXJ3w3AAABACOGeHQJ"
)