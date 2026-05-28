#!/usr/bin/env python3
"""Deploy test agent to Watsonx Orchestrate."""

import os
import sys
from pathlib import Path

# Set environment variables (with hackathon defaults)
os.environ['WO_INSTANCE_URL'] = os.getenv('WO_INSTANCE_URL', 'https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/f0486067-ab8a-458e-9db1-c44bc11bf146')
os.environ['WO_INSTANCE_API_KEY'] = os.getenv('WO_INSTANCE_API_KEY', '***REMOVED***')
os.environ['WO_IAM_URL'] = os.getenv('WO_IAM_URL', 'https://iam.cloud.ibm.com')
os.environ['WO_AUTH_TYPE'] = os.getenv('WO_AUTH_TYPE', 'ibm_iam')

from ibm_watsonx_orchestrate import OrchestrateClient

def main():
    """Deploy the test agent."""
    print("Initializing Orchestrate client...")
    client = OrchestrateClient()
    
    # Import connection
    print("\n1. Creating connection 'test_app'...")
    try:
        connection_file = Path("connections/test_app.yaml")
        client.connections.create_from_yaml(connection_file)
        print("✓ Connection created successfully")
    except Exception as e:
        print(f"⚠ Connection creation: {e}")
    
    # Import tool
    print("\n2. Importing tool 'hello_world'...")
    try:
        tool_file = Path("tools/hello_world.py")
        client.tools.create_from_file(tool_file, kind="python")
        print("✓ Tool imported successfully")
    except Exception as e:
        print(f"✗ Tool import failed: {e}")
        return 1
    
    # Import agent
    print("\n3. Importing agent 'test_agent'...")
    try:
        agent_file = Path("agents/test_agent.yaml")
        client.agents.create_from_yaml(agent_file)
        print("✓ Agent imported successfully")
    except Exception as e:
        print(f"✗ Agent import failed: {e}")
        return 1
    
    print("\n✅ Test agent deployed successfully!")
    print("\nYou can now test the agent in the Watsonx Orchestrate UI:")
    print("https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/f0486067-ab8a-458e-9db1-c44bc11bf146")
    return 0

if __name__ == "__main__":
    sys.exit(main())
