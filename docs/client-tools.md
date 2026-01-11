# Client Tools & SDKs Documentation

The Agent-Matrix ecosystem provides two complementary command-line tools for interacting with your deployed infrastructure. This guide covers both tools, when to use each, and comprehensive usage examples.

---

## Overview: Two Tools, Distinct Purposes

### Matrix CLI — Client-Side Operations
**Repository:** https://github.com/agent-matrix/matrix-cli

**Purpose:** Client-side tool for discovering, installing, running, and interacting with agents, tools, and MCP servers.

**Use Cases:**
- 🔍 Search and discover available MCP servers, agents, and tools
- 📦 Install and manage packages locally
- ▶️ Run MCP servers locally or attach to remote services
- 🔧 Probe and invoke tools via CLI
- 📊 Monitor running processes with `matrix ps`

**Target Users:** Developers, AI engineers, end users

### Matrix System SDK — Infrastructure Management
**Repository:** https://github.com/agent-matrix/matrix-system

**Purpose:** Production-ready SDK and CLI for monitoring and managing deployed Agent-Matrix infrastructure services.

**Use Cases:**
- 💚 Monitor service health (Hub, AI, Guardian)
- 📋 Track system events and plans
- ✅ Manage governance proposals and approvals
- 🔐 Enforce policies and risk assessment
- 🐍 Python SDK for automation scripts

**Target Users:** DevOps engineers, system administrators, platform operators

---

## Quick Reference: When to Use Which Tool?

| Task | Tool | Command Example |
|------|------|-----------------|
| Search for MCP servers | **Matrix CLI** | `matrix search "hello" --type mcp_server` |
| Install an MCP server | **Matrix CLI** | `matrix install hello-sse-server` |
| Run a local MCP server | **Matrix CLI** | `matrix run hello-sse --port 6288` |
| Probe MCP server tools | **Matrix CLI** | `matrix mcp probe --alias hello-sse` |
| Check infrastructure health | **Matrix System** | `matrix health check --all` |
| Monitor system events | **Matrix System** | `matrix event list --limit 20` |
| Manage governance proposals | **Matrix System** | `matrix proposal approve --id prop-123` |
| Register agents in Hub | **Matrix System** | `matrix agent register --name my-agent` |
| Python automation | **Matrix System SDK** | Import and use Python classes |

---

## Part 1: Matrix CLI Documentation

### Installation

```bash
# Recommended: Install with pipx for isolation
pipx install matrix-cli

# Or with pip
pip install matrix-cli

# With optional MCP support
pip install matrix-cli[mcp]

# For development
pip install matrix-cli[dev]
```

### Configuration

Matrix CLI uses environment variables and/or a TOML configuration file.

**Environment Variables:**
```bash
export MATRIX_HUB_BASE="http://your-matrix-hub-url:30081"
export MATRIX_HUB_TOKEN="your-hub-token"  # Optional
export MATRIX_HOME="$HOME/.matrix"        # Default storage location
export MATRIX_SDK_DEBUG="1"               # Enable debug logging
export SSL_CERT_FILE="/path/to/cert.pem"  # For corporate proxies
```

**Configuration File:** `~/.config/matrix/cli.toml`
```toml
[hub]
base_url = "http://localhost:30081"
token = "optional-auth-token"

[client]
home_dir = "~/.matrix"
debug = false
```

### Core Commands

#### 1. Search and Discovery

```bash
# Search all resources
matrix search "keyword"

# Search specific type
matrix search "hello" --type mcp_server
matrix search "data" --type agent
matrix search "compute" --type tool

# Filter results
matrix search "llm" --category ai --limit 10
```

#### 2. Installation

```bash
# Install by name
matrix install hello-sse-server

# Install with alias
matrix install hello-sse-server --alias hello-sse

# Install specific version
matrix install my-server@1.2.3

# Install with namespaced identifier
matrix install org/my-server
```

#### 3. Running Services

```bash
# Run installed MCP server
matrix run hello-sse-server --port 6288

# Run with custom arguments
matrix run my-server --port 8000 --env production

# Run in background
matrix run hello-sse --port 6288 --daemon

# View running services
matrix ps

# Stop a service
matrix stop hello-sse-server

# Restart a service
matrix restart hello-sse-server
```

#### 4. MCP Server Interaction

```bash
# Probe server capabilities
matrix mcp probe --alias hello-sse-server

# List available tools
matrix mcp list-tools --alias hello-sse-server

# Invoke a tool
matrix do hello-sse-server "Analyze this data"

# Call with JSON arguments
matrix mcp call --alias hello-sse --tool process_data --args '{"input": "data"}'
```

#### 5. Process Management

```bash
# List running services
matrix ps

# View detailed service info
matrix ps --verbose

# View service logs
matrix logs hello-sse-server

# Follow logs in real-time
matrix logs hello-sse-server --follow

# Check service health
matrix health hello-sse-server
```

#### 6. Connector Mode (Remote Services)

For pre-existing remote MCP servers, create a connector:

**Create connector JSON:**
```json
{
  "name": "remote-mcp-server",
  "type": "connector",
  "url": "http://remote-host:8000",
  "transport": "sse"
}
```

**Install and use:**
```bash
# Create connector
matrix connector create --file remote-connector.json

# Use like local server
matrix mcp probe --alias remote-mcp-server
matrix do remote-mcp-server "Your query"
```

#### 7. Uninstallation

```bash
# Uninstall package
matrix uninstall hello-sse-server

# Uninstall and purge data
matrix uninstall hello-sse-server --purge

# Uninstall all stopped services
matrix uninstall --all --stopped
```

### Matrix CLI Examples

#### Example 1: Full MCP Server Workflow

```bash
# 1. Search for MCP servers
matrix search "hello" --type mcp_server

# 2. Install the server
matrix install hello-sse-server --alias hello-sse

# 3. Run the server
matrix run hello-sse --port 6288

# 4. Probe capabilities
matrix mcp probe --alias hello-sse

# 5. Interact with the server
matrix do hello-sse "What can you do?"

# 6. View running process
matrix ps

# 7. Check logs
matrix logs hello-sse --follow

# 8. Stop when done
matrix stop hello-sse
```

#### Example 2: Managing Multiple Services

```bash
# Install multiple servers
matrix install hello-sse-server --alias hello-sse
matrix install data-processor --alias processor
matrix install llm-gateway --alias llm

# Run all services
matrix run hello-sse --port 6001
matrix run processor --port 6002
matrix run llm --port 6003

# View all running services
matrix ps

# Output:
# ALIAS         PORT    STATUS    UPTIME      URL
# hello-sse     6001    running   5m 23s      http://localhost:6001
# processor     6002    running   3m 15s      http://localhost:6002
# llm           6003    running   1m 42s      http://localhost:6003

# Stop all services
matrix stop hello-sse processor llm
```

#### Example 3: Development Workflow

```bash
# Install local development server
matrix install ./my-mcp-server --alias dev-server

# Run with debug logging
MATRIX_SDK_DEBUG=1 matrix run dev-server --port 9000

# Watch logs
matrix logs dev-server --follow

# Make changes to code, restart
matrix restart dev-server

# Test with different inputs
matrix do dev-server "Test input 1"
matrix do dev-server "Test input 2"

# Uninstall when done
matrix uninstall dev-server --purge
```

---

## Part 2: Matrix System SDK Documentation

### Installation

```bash
# Recommended: Install with uv
uv pip install matrix-system

# Or with pip
pip install matrix-system

# From source
git clone https://github.com/agent-matrix/matrix-system.git
cd matrix-system
make install
```

### Configuration

The SDK reads configuration from environment variables:

```bash
# Required: Service URLs
export MATRIX_HUB_URL="http://your-matrix-hub-url:30081"
export MATRIX_AI_URL="http://your-matrix-ai-url:30083"
export MATRIX_GUARDIAN_URL="http://your-matrix-guardian-url:30082"

# Required: Authentication
export ADMIN_TOKEN="your-admin-token"

# Optional: Logging
export LOG_LEVEL="INFO"  # DEBUG, INFO, WARNING, ERROR, CRITICAL
```

**MiniKube Example:**
```bash
export MINIKUBE_IP=$(minikube ip)
export MATRIX_HUB_URL="http://$MINIKUBE_IP:30081"
export MATRIX_AI_URL="http://$MINIKUBE_IP:30083"
export MATRIX_GUARDIAN_URL="http://$MINIKUBE_IP:30082"
export ADMIN_TOKEN="your-admin-token"
```

**Docker Compose Example:**
```bash
export MATRIX_HUB_URL="http://your-vm-ip:8000"
export MATRIX_AI_URL="http://your-vm-ip:7860"
export MATRIX_GUARDIAN_URL="http://your-vm-ip:8001"
export ADMIN_TOKEN="your-admin-token"
```

### CLI Commands

#### 1. Health Commands

```bash
# Check all services
matrix health check --all

# Check specific service
matrix health check --service hub
matrix health check --service ai
matrix health check --service guardian

# Get health score
matrix health score
```

#### 2. Agent Commands

```bash
# List all agents
matrix agent list

# Register a new agent
matrix agent register --name my-agent --type general

# Get agent details
matrix agent get --id agent-123

# Update agent
matrix agent update --id agent-123 --status active

# Delete agent
matrix agent delete --id agent-123
```

#### 3. Event Commands

```bash
# List recent events
matrix event list --limit 20

# Get specific event
matrix event get --id event-123

# Filter events by type
matrix event list --type plan_created
matrix event list --type action_executed
```

#### 4. Proposal Commands

```bash
# List proposals
matrix proposal list

# Get proposal details
matrix proposal get --id proposal-123

# Approve proposal
matrix proposal approve --id proposal-123

# Reject proposal
matrix proposal reject --id proposal-123 --reason "Risk too high"
```

#### 5. System Commands

```bash
# Get system status
matrix system status

# View configuration
matrix config show

# Test connectivity
matrix ping
```

### Python SDK Usage

#### Initialization

```python
from matrix_system import MatrixHub, MatrixAI, MatrixGuardian

# Initialize clients (uses environment variables)
hub = MatrixHub()
ai = MatrixAI()
guardian = MatrixGuardian()

# Or specify URLs explicitly
hub = MatrixHub(
    base_url="http://localhost:30081",
    admin_token="your-admin-token"
)
```

#### Health Monitoring

```python
from matrix_system import MatrixHub

hub = MatrixHub()

# Get health status
health = hub.health_check()
print(f"Status: {health.status}")
print(f"Score: {health.score}")
print(f"Message: {health.message}")

# Check if healthy
if health.is_healthy():
    print("System is healthy!")
else:
    print(f"System has issues: {health.issues}")
```

#### Agent Management

```python
from matrix_system import MatrixHub

hub = MatrixHub()

# Register an agent
agent = hub.register_agent(
    name="data-processor",
    agent_type="worker",
    capabilities=["data_processing", "etl"],
    metadata={"version": "1.0.0"}
)
print(f"Registered agent: {agent.id}")

# List all agents
agents = hub.list_agents()
for agent in agents:
    print(f"Agent: {agent.name} (ID: {agent.id})")

# Get agent details
agent = hub.get_agent(agent_id="agent-123")
print(f"Agent status: {agent.status}")

# Update agent
hub.update_agent(
    agent_id="agent-123",
    status="active",
    metadata={"last_update": "2026-01-11"}
)

# Delete agent
hub.delete_agent(agent_id="agent-123")
```

#### Event Tracking

```python
from matrix_system import MatrixHub

hub = MatrixHub()

# Get recent events
events = hub.get_events(limit=10)
for event in events:
    print(f"Event: {event.type} at {event.timestamp}")
    print(f"  Details: {event.details}")

# Filter events by type
plan_events = hub.get_events(event_type="plan_created", limit=20)

# Get specific event
event = hub.get_event(event_id="event-123")
print(f"Event data: {event.data}")
```

#### Proposal Management

```python
from matrix_system import MatrixGuardian

guardian = MatrixGuardian()

# List pending proposals
proposals = guardian.list_proposals(status="pending")
for proposal in proposals:
    print(f"Proposal: {proposal.id}")
    print(f"  Risk: {proposal.risk_level}")
    print(f"  Description: {proposal.description}")

# Get proposal details
proposal = guardian.get_proposal(proposal_id="proposal-123")
print(f"Risk Assessment: {proposal.risk_assessment}")

# Approve proposal
guardian.approve_proposal(
    proposal_id="proposal-123",
    approver="admin",
    notes="Approved after review"
)

# Reject proposal
guardian.reject_proposal(
    proposal_id="proposal-456",
    approver="admin",
    reason="Risk level too high for automated execution"
)
```

#### AI Operations

```python
from matrix_system import MatrixAI

ai = MatrixAI()

# Submit a task for reasoning
task = ai.create_task(
    description="Analyze system logs and identify anomalies",
    context={"time_range": "last_24h"},
    priority="high"
)
print(f"Task created: {task.id}")

# Get task status
status = ai.get_task_status(task_id=task.id)
print(f"Task status: {status.state}")

# Get task results
if status.state == "completed":
    result = ai.get_task_result(task_id=task.id)
    print(f"Analysis: {result.analysis}")
    print(f"Recommendations: {result.recommendations}")
```

#### Error Handling

```python
from matrix_system import MatrixHub
from matrix_system.exceptions import (
    MatrixAPIError,
    MatrixAuthenticationError,
    MatrixConnectionError,
    MatrixValidationError
)

hub = MatrixHub()

try:
    agent = hub.register_agent(name="test-agent", agent_type="general")
except MatrixAuthenticationError as e:
    print(f"Authentication failed: {e}")
except MatrixValidationError as e:
    print(f"Invalid data: {e}")
except MatrixConnectionError as e:
    print(f"Connection error: {e}")
except MatrixAPIError as e:
    print(f"API error: {e.status_code} - {e.message}")
```

---

## Integration Examples

### Example 1: Complete Workflow (Both Tools)

```bash
# 1. Use Matrix CLI to discover and run MCP servers
matrix search "data-processor" --type mcp_server
matrix install data-processor-mcp --alias processor
matrix run processor --port 7000

# 2. Use Matrix System to register the service in Hub
matrix agent register --name processor-agent --type mcp_server

# 3. Check infrastructure health
matrix health check --all

# 4. Monitor events
matrix event list --limit 10

# 5. Interact with the MCP server
matrix do processor "Process this dataset"

# 6. View running services
matrix ps
```

### Example 2: Health Monitoring Dashboard (Python)

```python
from matrix_system import MatrixHub, MatrixAI, MatrixGuardian
import time

def health_dashboard():
    hub = MatrixHub()
    ai = MatrixAI()
    guardian = MatrixGuardian()

    services = {
        "Matrix Hub": hub,
        "Matrix AI": ai,
        "Matrix Guardian": guardian
    }

    while True:
        print("\n=== Agent-Matrix Health Dashboard ===")
        for name, service in services.items():
            health = service.health_check()
            status = "✅" if health.is_healthy() else "❌"
            print(f"{status} {name}: Score {health.score}/100")

        time.sleep(30)

health_dashboard()
```

### Example 3: Automated Governance Workflow

```python
from matrix_system import MatrixGuardian

def process_pending_proposals():
    guardian = MatrixGuardian()

    proposals = guardian.list_proposals(status="pending")

    for proposal in proposals:
        print(f"\nProposal: {proposal.id}")
        print(f"Description: {proposal.description}")
        print(f"Risk Level: {proposal.risk_level}")

        # Auto-approve low-risk proposals
        if proposal.risk_level == "low":
            guardian.approve_proposal(
                proposal_id=proposal.id,
                approver="automated-system",
                notes="Auto-approved: low risk"
            )
            print("✅ Auto-approved")

        # Flag high-risk for manual review
        elif proposal.risk_level == "high":
            print("⚠️  Requires manual review")

        # Review medium-risk proposals
        else:
            print("🔍 Requires risk assessment")

process_pending_proposals()
```

### Example 4: Agent Fleet Management

```python
from matrix_system import MatrixHub

def register_fleet(agent_count=10):
    hub = MatrixHub()

    agents = []
    for i in range(agent_count):
        agent = hub.register_agent(
            name=f"worker-{i:03d}",
            agent_type="worker",
            capabilities=["data_processing"],
            metadata={"fleet": "production", "zone": "us-east-1"}
        )
        agents.append(agent)
        print(f"Registered: {agent.name}")

    return agents

# Register 10 worker agents
fleet = register_fleet(10)
print(f"Fleet size: {len(fleet)} agents")
```

---

## API Reference

### Matrix System SDK Classes

#### MatrixHub

The Hub client provides access to the central coordination service.

**Methods:**
- `health_check()` - Check Hub health status
- `register_agent(name, agent_type, **kwargs)` - Register a new agent
- `list_agents(**filters)` - List all agents
- `get_agent(agent_id)` - Get agent details
- `update_agent(agent_id, **updates)` - Update agent information
- `delete_agent(agent_id)` - Delete an agent
- `get_events(**filters)` - Get system events
- `get_event(event_id)` - Get specific event details

#### MatrixAI

The AI client provides access to planning and reasoning services.

**Methods:**
- `health_check()` - Check AI service health
- `create_task(description, **kwargs)` - Create a new reasoning task
- `get_task_status(task_id)` - Get task execution status
- `get_task_result(task_id)` - Get completed task results
- `list_tasks(**filters)` - List all tasks
- `cancel_task(task_id)` - Cancel a running task

#### MatrixGuardian

The Guardian client provides access to governance and policy enforcement.

**Methods:**
- `health_check()` - Check Guardian health status
- `list_proposals(**filters)` - List governance proposals
- `get_proposal(proposal_id)` - Get proposal details
- `approve_proposal(proposal_id, **kwargs)` - Approve a proposal
- `reject_proposal(proposal_id, reason, **kwargs)` - Reject a proposal
- `get_policies()` - Get active governance policies
- `evaluate_risk(action)` - Evaluate risk for an action

---

## Best Practices

### 1. Tool Selection

**Use Matrix CLI when:**
- Running local MCP servers for development
- Discovering and installing agents/tools
- Testing MCP server capabilities
- Quick prototyping and experimentation

**Use Matrix System when:**
- Monitoring production infrastructure
- Managing governance and approvals
- Tracking system-wide events
- Building automation scripts
- Performing administrative tasks

### 2. Error Handling

Always handle exceptions appropriately:

```python
from matrix_system import MatrixHub
from matrix_system.exceptions import MatrixAPIError

hub = MatrixHub()

try:
    agents = hub.list_agents()
except MatrixAPIError as e:
    print(f"Failed to list agents: {e}")
    # Implement retry logic or fallback
```

### 3. Configuration Management

Store sensitive configuration in environment variables:

```python
import os
from matrix_system import MatrixHub

# Good: Use environment variables
hub = MatrixHub()

# Bad: Hardcode credentials
hub = MatrixHub(
    base_url="http://example.com",
    admin_token="hardcoded-token-123"  # Don't do this!
)
```

### 4. Connection Reuse

Reuse client instances when possible:

```python
# Good: Reuse client
hub = MatrixHub()
for _ in range(100):
    agents = hub.list_agents()

# Bad: Create new client each time
for _ in range(100):
    hub = MatrixHub()
    agents = hub.list_agents()
```

### 5. Health Checks Before Operations

```python
hub = MatrixHub()

health = hub.health_check()
if not health.is_healthy():
    raise RuntimeError(f"System unhealthy: {health.message}")

# Proceed with operations
agent = hub.register_agent(...)
```

---

## Troubleshooting

### Matrix CLI Issues

#### Problem: Cannot find MCP server

**Solutions:**
- Verify Hub URL: `echo $MATRIX_HUB_BASE`
- Test connectivity: `curl http://your-hub-url/health`
- Search with different keywords
- Check Hub is running and accessible

#### Problem: Service won't start

**Solutions:**
- Check if port is already in use: `lsof -i :PORT`
- Review installation: `matrix list --installed`
- Check logs: `matrix logs service-name`
- Try different port: `matrix run service --port 9999`

#### Problem: Connector authentication fails

**Solutions:**
- Verify remote URL is accessible
- Check authentication credentials
- Review connector JSON configuration
- Test with `curl` first

### Matrix System Issues

#### Problem: Connection errors

**Solutions:**
- Verify service URLs are correct
- Check services are running: `kubectl get pods -n matrix`
- Verify network connectivity: `curl http://your-hub-url/health`
- Check firewall rules

#### Problem: Authentication errors

**Solutions:**
- Verify `ADMIN_TOKEN` environment variable is set
- Check token matches service configuration
- For MiniKube: `kubectl get configmap -n matrix`
- For Docker Compose: Check `.env` file

#### Problem: Validation errors

**Solutions:**
- Check required fields are provided
- Verify data types match expected schema
- Review API documentation
- Enable debug logging: `LOG_LEVEL=DEBUG`

---

## Resources

### Matrix CLI
- **GitHub Repository**: https://github.com/agent-matrix/matrix-cli
- **Issue Tracker**: https://github.com/agent-matrix/matrix-cli/issues

### Matrix System SDK
- **GitHub Repository**: https://github.com/agent-matrix/matrix-system
- **Issue Tracker**: https://github.com/agent-matrix/matrix-system/issues

### Matrix Infrastructure
- **Main Repository**: https://github.com/agent-matrix/matrix-infra
- **Discussions**: https://github.com/agent-matrix/matrix-infra/discussions

---

## License

Both tools are licensed under Apache-2.0. See respective repositories for details.
