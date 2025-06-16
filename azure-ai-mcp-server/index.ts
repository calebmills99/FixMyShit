#!/usr/bin/env node

/**
 * Azure AI MCP Server for Cursor IDE
 * Provides Azure OpenAI, ML Workspace, and resource management tools
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from '@modelcontextprotocol/sdk/types.js';
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

interface AzureConfig {
  subscriptionId: string;
  resourceGroup: string;
  openaiEndpoint: string;
  openaiKey: string;
  mlWorkspace: string;
}

class AzureAIMCPServer {
  private server: Server;
  private config: AzureConfig;

  constructor() {
    this.server = new Server(
      {
        name: 'azure-ai-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.loadConfig();
    this.setupToolHandlers();
    this.setupErrorHandling();
  }

  private loadConfig(): void {
    // Load configuration from .env file
    const envPath = path.join(process.cwd(), '.env');
    if (fs.existsSync(envPath)) {
      const envContent = fs.readFileSync(envPath, 'utf8');
      const envVars: Record<string, string> = {};
      
      envContent.split('\n').forEach(line => {
        const [key, value] = line.split('=');
        if (key && value) {
          envVars[key.trim()] = value.trim();
        }
      });

      this.config = {
        subscriptionId: envVars.AZURE_SUBSCRIPTION_ID || '',
        resourceGroup: envVars.AZURE_RESOURCE_GROUP || 'guardr',
        openaiEndpoint: envVars.AZURE_OPENAI_ENDPOINT || '',
        openaiKey: envVars.AZURE_OPENAI_API_KEY || '',
        mlWorkspace: envVars.AZURE_ML_WORKSPACE_NAME || 'midnight'
      };
    } else {
      throw new Error('.env file not found');
    }
  }

  private setupToolHandlers(): void {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'azure_openai_chat',
            description: 'Chat with Azure OpenAI using your deployed model',
            inputSchema: {
              type: 'object',
              properties: {
                message: {
                  type: 'string',
                  description: 'Message to send to Azure OpenAI'
                },
                model: {
                  type: 'string',
                  description: 'Deployment name (default: gpt-4.1)',
                  default: 'gpt-4.1'
                }
              },
              required: ['message']
            }
          },
          {
            name: 'azure_resources_list',
            description: 'List Azure resources in your resource group',
            inputSchema: {
              type: 'object',
              properties: {
                resourceType: {
                  type: 'string',
                  description: 'Filter by resource type (optional)'
                }
              }
            }
          },
          {
            name: 'azure_ml_workspace_info',
            description: 'Get Azure ML workspace information and status',
            inputSchema: {
              type: 'object',
              properties: {}
            }
          },
          {
            name: 'azure_openai_deployments',
            description: 'List all OpenAI deployments in your resource',
            inputSchema: {
              type: 'object',
              properties: {}
            }
          },
          {
            name: 'azure_cost_analysis',
            description: 'Get cost analysis for your Azure resources',
            inputSchema: {
              type: 'object',
              properties: {
                timeframe: {
                  type: 'string',
                  description: 'Time frame: last7days, last30days, thismonth',
                  default: 'last7days'
                }
              }
            }
          },
          {
            name: 'azure_logs_query',
            description: 'Query Azure logs for your OpenAI or ML workspace',
            inputSchema: {
              type: 'object',
              properties: {
                query: {
                  type: 'string',
                  description: 'KQL query to run'
                },
                service: {
                  type: 'string',
                  description: 'Service to query: openai, ml-workspace',
                  default: 'openai'
                }
              },
              required: ['query']
            }
          }
        ]
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'azure_openai_chat':
            return await this.azureOpenAIChat(args);
          
          case 'azure_resources_list':
            return await this.listAzureResources(args);
          
          case 'azure_ml_workspace_info':
            return await this.getMLWorkspaceInfo();
          
          case 'azure_openai_deployments':
            return await this.listOpenAIDeployments();
          
          case 'azure_cost_analysis':
            return await this.getCostAnalysis(args);
          
          case 'azure_logs_query':
            return await this.queryAzureLogs(args);

          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error instanceof Error ? error.message : String(error)}`
            }
          ]
        };
      }
    });
  }

  private async azureOpenAIChat(args: any) {
    const { message, model = 'gpt-4.1' } = args;
    
    // Create a simple Python script to call Azure OpenAI
    const pythonScript = `
import os
import json
from openai import AzureOpenAI

client = AzureOpenAI(
    azure_endpoint="${this.config.openaiEndpoint}",
    api_key="${this.config.openaiKey}",
    api_version="2024-12-01-preview"
)

try:
    response = client.chat.completions.create(
        model="${model}",
        messages=[{"role": "user", "content": "${message}"}],
        max_tokens=500
    )
    print(json.dumps({
        "success": True,
        "response": response.choices[0].message.content,
        "usage": {
            "prompt_tokens": response.usage.prompt_tokens,
            "completion_tokens": response.usage.completion_tokens,
            "total_tokens": response.usage.total_tokens
        }
    }))
except Exception as e:
    print(json.dumps({"success": False, "error": str(e)}))
`;

    try {
      const result = execSync(`python -c "${pythonScript}"`, { encoding: 'utf8' });
      const parsed = JSON.parse(result);
      
      if (parsed.success) {
        return {
          content: [
            {
              type: 'text',
              text: `Azure OpenAI Response:\n${parsed.response}\n\nTokens used: ${parsed.usage.total_tokens}`
            }
          ]
        };
      } else {
        throw new Error(parsed.error);
      }
    } catch (error) {
      throw new Error(`Failed to call Azure OpenAI: ${error}`);
    }
  }

  private async listAzureResources(args: any) {
    const { resourceType } = args;
    
    let command = `az resource list --resource-group ${this.config.resourceGroup} --output json`;
    if (resourceType) {
      command += ` --resource-type ${resourceType}`;
    }

    try {
      const result = execSync(command, { encoding: 'utf8' });
      const resources = JSON.parse(result);
      
      const resourceList = resources.map((r: any) => 
        `- ${r.name} (${r.type}) - ${r.location}`
      ).join('\n');

      return {
        content: [
          {
            type: 'text',
            text: `Azure Resources in ${this.config.resourceGroup}:\n${resourceList}`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Failed to list Azure resources: ${error}`);
    }
  }

  private async getMLWorkspaceInfo() {
    const command = `az ml workspace show --name ${this.config.mlWorkspace} --resource-group ${this.config.resourceGroup} --output json`;
    
    try {
      const result = execSync(command, { encoding: 'utf8' });
      const workspace = JSON.parse(result);
      
      return {
        content: [
          {
            type: 'text',
            text: `ML Workspace: ${workspace.name}\nLocation: ${workspace.location}\nDescription: ${workspace.description || 'No description'}\nDiscovery URL: ${workspace.discovery_url}`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Failed to get ML workspace info: ${error}`);
    }
  }

  private async listOpenAIDeployments() {
    // Get the OpenAI resource name from the endpoint
    const resourceName = this.config.openaiEndpoint.split('//')[1].split('.')[0];
    
    const command = `az cognitiveservices account deployment list --name ${resourceName} --resource-group ${this.config.resourceGroup} --output json`;
    
    try {
      const result = execSync(command, { encoding: 'utf8' });
      const deployments = JSON.parse(result);
      
      const deploymentList = deployments.map((d: any) => 
        `- ${d.name}: ${d.properties.model.name} (${d.properties.model.version}) - ${d.properties.provisioningState}`
      ).join('\n');

      return {
        content: [
          {
            type: 'text',
            text: `OpenAI Deployments:\n${deploymentList}`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Failed to list OpenAI deployments: ${error}`);
    }
  }

  private async getCostAnalysis(args: any) {
    const { timeframe = 'last7days' } = args;
    
    const command = `az consumption usage list --subscription ${this.config.subscriptionId} --output json --max-items 10`;
    
    try {
      const result = execSync(command, { encoding: 'utf8' });
      const usage = JSON.parse(result);
      
      // Filter for our resource group
      const filteredUsage = usage.filter((u: any) => 
        u.instanceName?.includes(this.config.resourceGroup) || 
        u.resourceGroup?.toLowerCase() === this.config.resourceGroup.toLowerCase()
      );

      const costSummary = filteredUsage.slice(0, 5).map((u: any) => 
        `- ${u.instanceName}: $${u.pretaxCost} (${u.usageStart})`
      ).join('\n');

      return {
        content: [
          {
            type: 'text',
            text: `Recent Azure Costs (${timeframe}):\n${costSummary || 'No recent usage found'}`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Failed to get cost analysis: ${error}`);
    }
  }

  private async queryAzureLogs(args: any) {
    const { query, service = 'openai' } = args;
    
    // This would require Log Analytics workspace setup
    // For now, return a placeholder
    return {
      content: [
        {
          type: 'text',
          text: `Azure Logs Query (${service}):\nQuery: ${query}\n\nNote: Log Analytics integration requires additional setup. This is a placeholder response.`
        }
      ]
    };
  }

  private setupErrorHandling(): void {
    this.server.onerror = (error) => {
      console.error('[MCP Error]', error);
    };

    process.on('SIGINT', async () => {
      await this.server.close();
      process.exit(0);
    });
  }

  async run(): Promise<void> {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Azure AI MCP Server running on stdio');
  }
}

// Run the server
if (import.meta.url === `file://${process.argv[1]}`) {
  const server = new AzureAIMCPServer();
  server.run().catch(console.error);
}