# CLAUDE.md - AI Agent Guidelines for CODITECT Next Generation

## Project Purpose

CODITECT Next Generation is a Python-based framework for building fully autonomous multi-agent development systems. It implements a three-layer cognitive architecture (Orchestrator → Task Queue → Worker Agents) capable of analyzing, coding, and testing in parallel with 10-50x LLM cost reduction.

## Essential Reading (in order)

1. **README.md** - User-facing overview and quick start
2. **PROJECT-PLAN.md** - Implementation roadmap and deliverables
3. **TASKLIST.md** - Checkbox-based progress tracking
4. **docs/EXECUTIVE-SUMMARY.md** - Business case and architecture overview
5. **docs/PHASE-1-EXECUTION-PLAN.md** - Detailed 10-day implementation plan
6. **docs/SDD-SOFTWARE-DESIGN-DOCUMENT.md** - Complete system architecture

## Tech Stack

**Backend (Python 3.8+):**
- **FastAPI** - gRPC and REST API framework
- **NATS JetStream** - Event-driven message bus
- **Redis** - State management and world model
- **WebAssembly (WASM)** - Secure code execution sandbox
- **Docker** - Fallback sandbox and containerization
- **Protocol Buffers** - Event schema and gRPC serialization

**Infrastructure:**
- **Kubernetes (K8s)** - Container orchestration
- **Prometheus + Grafana** - Metrics and monitoring
- **Jaeger** - Distributed tracing
- **ClickHouse** - Event analytics and time-series data

**Testing:**
- **pytest** - Unit and integration tests (target: 85%+ coverage)
- **pytest-cov** - Coverage reporting
- **mypy** - Type checking
- **pylint** - Code quality

## Project Structure

```
coditect-next-generation/
├── .coditect -> ../../../.coditect  # Distributed intelligence
├── .claude -> .coditect              # Claude Code compatibility
├── src/                              # Python implementation
│   ├── orchestrator/                 # Layer 1: Strategic planning
│   │   ├── mission_planner.py        # Task decomposition
│   │   ├── goal_manager.py           # State tracking
│   │   └── resource_allocator.py     # Agent assignment
│   ├── task_queue/                   # Layer 2: Situation assessment
│   │   ├── world_model.py            # Shared state representation
│   │   ├── consistency_detector.py   # Violation detection
│   │   └── parametrization_engine.py # Task parameterization
│   ├── agents/                       # Layer 3: Worker agents
│   │   ├── base_agent.py             # Agent abstract class
│   │   ├── analyzer_agent.py         # Code analysis
│   │   ├── coder_agent.py            # Code generation
│   │   └── tester_agent.py           # Test execution
│   ├── sandbox/                      # Execution safety
│   │   ├── wasm_sandbox.py           # WebAssembly isolation
│   │   └── docker_sandbox.py         # Container-based sandbox
│   └── infrastructure/               # Supporting services
│       ├── nats_client.py            # Event bus
│       └── redis_client.py           # State storage
├── tests/                            # Test suite (85%+ coverage)
├── docs/                             # Architecture documentation
├── scripts/                          # Automation and utilities
├── deployments/                      # K8s manifests and Docker
│   ├── kubernetes/                   # K8s deployment
│   └── docker/                       # Docker Compose
└── diagrams/                         # C4 architecture diagrams
```

## Key Components

### Layer 1: Orchestrator (Strategic Planning)
- **mission_planner.py** - Decomposes user requests into goals (every 10 minutes)
- **goal_manager.py** - Tracks goal state and dependencies
- **resource_allocator.py** - Assigns agents to tasks based on capabilities

**Frequency**: 10 minutes (high-cost LLM inference)
**Purpose**: Strategic planning, goal decomposition, resource allocation

### Layer 2: Task Queue Manager (Situation Assessment)
- **world_model.py** - Maintains shared state representation
- **consistency_detector.py** - Detects expect vs. actual violations
- **parametrization_engine.py** - Converts goals to executable tasks

**Frequency**: 100ms (medium-cost state updates)
**Purpose**: State tracking, consistency checking, task distribution

### Layer 3: Worker Agents (Execution)
- **analyzer_agent.py** - Code analysis and inspection
- **coder_agent.py** - Code generation
- **tester_agent.py** - Test execution and validation

**Frequency**: Milliseconds (low-cost local execution)
**Purpose**: Execute tasks, report results, safety reflexes

### Sandbox (Security)
- **wasm_sandbox.py** - WebAssembly isolation with resource limits
- **docker_sandbox.py** - Container-based fallback sandbox

**Purpose**: Prevent malicious code, limit CPU/RAM, filesystem isolation

### Infrastructure
- **nats_client.py** - Event bus for agent communication
- **redis_client.py** - World model storage and caching

## Common Operations

### Run Development Environment
```bash
make dev                              # Start all services (NATS, Redis, API)
docker-compose up -d                  # Alternative with Docker Compose
```

### Run Tests
```bash
pytest                                # All tests
pytest --cov=src                      # With coverage
pytest tests/unit/orchestrator/       # Specific suite
make test                             # Via Makefile
```

### Start Services
```bash
# Orchestrator (Layer 1)
python -m src.orchestrator.service --port 50051

# Task Queue Manager (Layer 2)
python -m src.task_queue.service --port 50052

# Agent Workers (Layer 3)
python -m src.agents.analyzer_agent --agent-id analyzer-1
python -m src.agents.coder_agent --agent-id coder-1
python -m src.agents.tester_agent --agent-id tester-1
```

### Infrastructure Services
```bash
# NATS JetStream
nats-server -js

# Redis
redis-server

# Kubernetes deployment
kubectl apply -f deployments/kubernetes/
```

## Development Workflow

### Adding New Worker Agent
1. Create `src/agents/new_agent.py` inheriting from `BaseAgent`
2. Implement `run(task: Task) -> Result` method
3. Register agent in `src/agents/__init__.py`
4. Add unit tests in `tests/unit/agents/test_new_agent.py`
5. Update agent registry in `resource_allocator.py`
6. Add integration test in `tests/integration/test_end_to_end.py`
7. Document in `docs/AGENTS.md`

### Adding New Orchestrator Strategy
1. Create `src/orchestrator/strategies/new_strategy.py`
2. Implement `decompose(request: UserRequest) -> List[Goal]` method
3. Add to strategy factory in `mission_planner.py`
4. Add unit tests with known decomposition examples
5. Add integration test with full workflow
6. Update `docs/SDD-SOFTWARE-DESIGN-DOCUMENT.md`

### Adding New Consistency Check
1. Create check in `src/task_queue/consistency_detector.py`
2. Define violation type in `models/violations.py`
3. Implement investigation strategy for violation
4. Add unit tests with violation scenarios
5. Document in `docs/CONSISTENCY-VIOLATION-CATALOG.md`

## When to Use Architecture Patterns

**Three-Layer Cognitive Architecture** - When building autonomous systems:
- Layer 1 (Orchestrator): Infrequent, expensive, strategic
- Layer 2 (Task Queue): Frequent, medium-cost, tactical
- Layer 3 (Agents): Continuous, cheap, reflexive
- Use for: Cost optimization (10-50x reduction)

**Consistency Violation Detection** - When agents make mistakes:
- Compare expected state vs. actual state
- Trigger investigation mode on mismatch
- Update world model with new understanding
- Use for: Self-healing and error recovery (99%+ automatic)

**Episodic Memory** - When agents repeat mistakes:
- Store successful task completions
- Retrieve similar past experiences
- Reuse successful patterns
- Use for: Continuous learning and knowledge reuse

**Horizontal Coordination** - When tasks are parallelizable:
- Agents work as peers (no hierarchy)
- Share world model for coordination
- Use for: Speed improvement (days → hours)

**Vertical Coordination** - When tasks have dependencies:
- Hierarchical agent structure
- Parent delegates to children
- Use for: Complex multi-step workflows

## Testing Requirements

**Unit Tests:**
- All orchestrator, task queue, and agent modules
- Test against known decomposition examples
- Edge cases (zero inputs, circular dependencies)
- Mock external services (NATS, Redis)

**Integration Tests:**
- Layer-to-layer communication (gRPC)
- Event bus message passing
- State consistency across layers
- Sandbox isolation verification

**End-to-End Tests:**
- Complete user request workflow
- User input → autonomous completion
- Consistency violation recovery
- Multi-agent coordination

**Coverage Target:** 85%+ overall, 95%+ for critical paths

## Performance Targets

- **Task Delegation Latency**: <5 seconds
- **Consistency Check Frequency**: 100ms (Layer 2)
- **Strategic Planning Frequency**: 10 minutes (Layer 1)
- **Agent Throughput**: 50+ concurrent agents
- **Event Processing**: 1M+ events/second
- **System Uptime**: 99.9%

## Security Considerations

- **WASM Sandbox**: Filesystem isolation, CPU/RAM limits
- **Docker Sandbox**: Network isolation, read-only volumes
- **gRPC Auth**: mTLS for service-to-service communication
- **Event Validation**: Protobuf schema enforcement
- **Rate Limiting**: Per-agent request throttling
- **Audit Trail**: Complete event log for compliance

## CODITECT Integration

**Slash Command:**
```bash
/autonomous-dev "Build user authentication feature with tests"
```

**Agent:**
```
Use orchestrator subagent to decompose the authentication feature
into parallel tasks for analyzer, coder, and tester agents.
```

**Skill:**
```yaml
name: autonomous-multi-agent-dev
category: development-automation
description: Fully autonomous multi-agent development with self-healing
```

## Common Pitfalls

**Orchestrator Design:**
- Avoid too-frequent LLM calls (use 10-minute cadence)
- Don't decompose tasks too granularly (aim for 5-20 goals)
- Ensure goals have clear success criteria

**Consistency Detection:**
- Always compare expect vs. actual (not just check actual)
- Trigger investigation on mismatch, not automatic retry
- Update world model after investigation

**Agent Coordination:**
- Use shared world model, not agent-to-agent messaging
- Avoid circular dependencies between agents
- Ensure agents can work in parallel when possible

**Sandbox Security:**
- Never execute untrusted code outside sandbox
- Set CPU/RAM limits to prevent resource exhaustion
- Isolate filesystem to prevent data exfiltration

## Environment Variables

```bash
REDIS_URL=redis://localhost:6379          # State storage
NATS_URL=nats://localhost:4222            # Event bus
ORCHESTRATOR_PORT=50051                   # gRPC service port
TASK_QUEUE_PORT=50052                     # gRPC service port
LOG_LEVEL=INFO                            # Logging verbosity
SANDBOX_TYPE=wasm                         # wasm or docker
CONSISTENCY_CHECK_INTERVAL=100            # Milliseconds
STRATEGY_PLAN_INTERVAL=600                # Seconds (10 minutes)
```

## Quick Reference

**Install Dependencies:**
```bash
pip install -r requirements.txt           # Production
pip install -r requirements-dev.txt       # Development
```

**Run Application:**
```bash
make dev                                  # All services
make test                                 # Test suite
make coverage                             # Coverage report
make deploy-staging                       # Deploy to staging
```

**Quality Checks:**
```bash
make lint                                 # Run linters
make typecheck                            # mypy type checking
make format                               # Black code formatting
```

## Support

- **Technical questions**: See docs/ directory
- **Implementation details**: See PROJECT-PLAN.md and TASKLIST.md
- **Architecture decisions**: See docs/ADRS-ARCHITECTURE-DECISION-RECORDS.md
- **Phase 1 roadmap**: See docs/PHASE-1-EXECUTION-PLAN.md

---

**Last Updated:** 2025-11-22
**Status:** Phase 1 Implementation Ready
**Primary Contact:** Hal Casteel (hal@az1.ai)
