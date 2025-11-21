# C4 Architecture Model - CODITECT Next Generation
## Complete System Architecture Using C4 Methodology

**Document**: Comprehensive C4 diagrams with detailed dataflows
**Status**: Complete with ASCII diagrams and detailed descriptions
**Audience**: Architects, senior engineers, technical leads
**Methodology**: C4 Model (Context → Container → Component → Code)

---

## Overview: The C4 Model

The C4 Model provides four levels of abstraction:

1. **C1: System Context** - What is the system and what role does it play?
2. **C2: Container** - How is the system broken into containers?
3. **C3: Component** - How is each container broken into components?
4. **C4: Code** - How is each component implemented?

Each level increases in detail and scope decreases.

---

# C1: SYSTEM CONTEXT DIAGRAM
## "What is CODITECT and how does it fit in the world?"

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│                     EXTERNAL SYSTEMS & ACTORS                    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │  Developer   │  (User)
    │   / Team     │
    └──────┬───────┘
           │
           │ 1. Requests feature implementation
           │    2. Monitors progress
           │    3. Reviews code/results
           │
           ↓
    ╔══════════════════════════════════════════════════════════╗
    ║                    CODITECT SYSTEM                       ║
    ║    Multi-Agent Autonomous Software Development           ║
    ║                                                          ║
    ║  - Analyzes requirements                                ║
    ║  - Generates code                                       ║
    ║  - Runs tests                                           ║
    ║  - Reports results                                      ║
    ║  - Learns from failures                                 ║
    ║  - Operates autonomously (95% no human intervention)    ║
    ║                                                          ║
    ║  [Orchestrator] ← Plans work                           ║
    ║  [Task Queue]   ← Manages state                         ║
    ║  [Agents]       ← Execute tasks                         ║
    ║  [Memory]       ← Learns from experience                ║
    ╚══════════════════════════════════════════════════════════╝
           ↑
           │ 1. Results (code, tests, reports)
           │ 2. Error logs & anomalies
           │ 3. Progress updates
           │ 4. Cost metrics
           │
    ┌──────┴───────┐
    │  Developer   │  (Receives output)
    │   / Team     │
    └──────────────┘

    ┌─────────────────────┐
    │   LLM Services      │   (External API)
    │  (Claude, GPT, etc) │
    └────────┬────────────┘
             │
             │ 1. Sends: planning prompts, analysis requests
             │ 2. Receives: plans, insights, code ideas
             │ 3. Frequency: ~1 call per 10 minutes (strategic layer)
             │
             ↑
    ┌─────────────────────────────────────────────────┐
    │  CODITECT Orchestrator (Layer 1)                │
    │  Makes high-level decisions using LLM           │
    └─────────────────────────────────────────────────┘

    ┌──────────────────────────┐
    │  Git Repository          │   (External Storage)
    │  (GitHub, GitLab, etc)   │
    └────────┬─────────────────┘
             │
             │ 1. Reads: Current codebase, test files
             │ 2. Writes: Generated code, test results
             │ 3. Frequency: Per task completion
             │
             ↑↓
    ┌──────────────────────────────────────┐
    │  CODITECT Agents (Layer 3)           │
    │  Execute tasks: code gen, testing    │
    └──────────────────────────────────────┘

    ┌──────────────────────────┐
    │  Analytics Databases     │   (External Storage)
    │  (ClickHouse, etc)       │
    └────────┬─────────────────┘
             │
             │ 1. Events: Every task, every agent action
             │ 2. Metrics: Performance, costs, autonomy
             │ 3. Frequency: Real-time (1M+ events/sec)
             │
             ↑
    ┌──────────────────────────────────────┐
    │  CODITECT Task Queue (Layer 2)       │
    │  Sends events to analytics           │
    └──────────────────────────────────────┘
```

## C1: Key Elements

### Actors
1. **Developer/Team**
   - Sends: Feature requests, project requirements
   - Receives: Implemented code, test results, cost reports
   - Interaction: Web UI or CLI

2. **External LLM Services**
   - Role: Provides reasoning for strategic planning
   - Called by: Orchestrator (Layer 1)
   - Frequency: Low (every 10 minutes)
   - Cost: Highest per call, but infrequent

3. **Git Repository**
   - Role: Source of truth for codebase
   - Accessed by: Analyzer (reads), Coder (writes)
   - Frequency: Per task

4. **Analytics Databases**
   - Role: Store events for learning and metrics
   - Fed by: All layers
   - Frequency: Real-time streaming

### System Responsibilities
- ✅ Autonomous feature implementation
- ✅ Code quality assurance (testing)
- ✅ Error detection and recovery
- ✅ Experience-based learning
- ✅ Cost-optimized execution

### Key Characteristics
- High autonomy (95%)
- Low LLM cost (10-50x reduction)
- High reliability (99.9% uptime)
- Scalable (1-1000+ agents)

---

# C2: CONTAINER DIAGRAM
## "How is CODITECT broken into high-level containers?"

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CODITECT SYSTEM                                   │
│  Multi-Agent Autonomous Software Development Platform                   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────┐
│     USER INTERFACE              │
├─────────────────────────────────┤
│  • Web Dashboard                │
│  • CLI Tools                    │
│  • API Client                   │
│                                 │
│  Technologies:                  │
│  - React/TypeScript (UI)        │
│  - Actix-web (API Gateway)      │
│  - gRPC Client (Orchestrator)   │
└────────────┬────────────────────┘
             │
             │ REST API / gRPC
             │ Feature requests
             │ Status queries
             │ Results retrieval
             │
             ↓
┌──────────────────────────────────────────────────────────────────────────┐
│  LAYER 1: ORCHESTRATOR CONTAINER (Strategic Planning)                    │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  Responsibility: High-level planning, goal supervision                   │
│  Update Frequency: 10-minute cycles                                      │
│  Cost Profile: High (LLM usage)                                          │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ gRPC Server (Async Tokio-based)                                    │  │
│  │ • Receives feature requests                                        │  │
│  │ • Sends task plans                                                │  │
│  │ • Receives status updates                                         │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ Mission Planner (LLM-based)                                        │  │
│  │ • Input: "Implement user authentication"                           │  │
│  │ • Process: Decompose into tasks using Claude LLM                   │  │
│  │ • Output: Task DAG (Analyze → Code → Test)                         │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ Goal Manager                                                        │  │
│  │ • Tracks: Active goals and progress                                │  │
│  │ • Detects: Completion (all subtasks done)                          │  │
│  │ • Detects: Failure (timeout, error threshold)                      │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ Resource Allocator                                                  │  │
│  │ • Knows: Agent capabilities and current load                       │  │
│  │ • Assigns: Tasks to best-fit agents                                │  │
│  │ • Balances: Work across available agents                           │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  External Dependencies:                                                 │
│  → LLM Services (Claude API) for planning                              │
│  → Redis (state storage, <1ms queries)                                 │
└──────────────────────────────────────────────────────────────────────────┘
             ↑↓
      gRPC + Protobuf
      Task plans, status updates
             ↑↓
┌──────────────────────────────────────────────────────────────────────────┐
│  LAYER 2: TASK QUEUE CONTAINER (Situation Assessment)                    │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  Responsibility: State management, anomaly detection, task coordination  │
│  Update Frequency: 100-500ms cycles                                      │
│  Cost Profile: Medium (state ops + selective LLM)                        │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ gRPC/REST Server                                                   │  │
│  │ • Receives: Task plans from Orchestrator                           │  │
│  │ • Receives: Task results from Agents                               │  │
│  │ • Sends: Task assignments to Agents                                │  │
│  │ • Sends: Status to Orchestrator                                    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ World Model (In-Memory State)                                      │  │
│  │ • Files: {path, content_hash, last_modified}                       │  │
│  │ • Tests: {test_name, status, output}                               │  │
│  │ • Agents: {agent_id, status, current_task}                         │  │
│  │ • Decisions: {decision_id, outcome, timestamp}                     │  │
│  │ Query Latency: <1ms (Redis-backed)                                 │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ Consistency Violation Detector                                      │  │
│  │ • Records expectation BEFORE action                                │  │
│  │   "Test should pass"                                               │  │
│  │ • Gets actual AFTER action                                         │  │
│  │   "Test actually failed"                                           │  │
│  │ • Detects mismatch → Triggers investigation                        │  │
│  │ • Enables autonomous error recovery (99%)                          │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ Parametrization Engine                                              │  │
│  │ • Input: High-level intent (AnalyzeCode, WriteCode)                │  │
│  │ • Process: Map to concrete actions with parameters                 │  │
│  │ • Output: Parameterized task for agent execution                   │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ Task Queue                                                          │  │
│  │ • Queue: Pending tasks from Orchestrator                           │  │
│  │ • Priority: Task importance (critical tasks first)                 │  │
│  │ • Dependencies: Task ordering (A must complete before B)           │  │
│  │ • Assignment: Based on agent capability + load                     │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  External Dependencies:                                                 │
│  → Redis Cluster (world model, distributed locks)                      │
│  → NATS JetStream (event streaming)                                    │
│  → ClickHouse (analytics, optional for investigation)                  │
└──────────────────────────────────────────────────────────────────────────┘
             ↑↓
      gRPC + Protobuf
      Task assignments, results
             ↑↓
┌──────────────────────────────────────────────────────────────────────────┐
│  LAYER 3: AGENT FRAMEWORK CONTAINER (Execution)                          │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  Responsibility: Execute assigned tasks, report results                  │
│  Update Frequency: Continuous (per task)                                │
│  Cost Profile: Low (no LLM calls, cheap execution)                      │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ ANALYZER AGENT                    │ CODER AGENT                     │  │
│  ├────────────────────────────────────┼─────────────────────────────┤  │
│  │ • Reads requirements               │ • Generates code              │  │
│  │ • Analyzes codebase                │ • Uses code templates         │  │
│  │ • Detects patterns                 │ • Integrates with existing    │  │
│  │ • Reports findings                 │ • Formats according to style  │  │
│  │ • Suggests improvements            │ • Reports generated code      │  │
│  │                                    │                               │  │
│  │ Output: Analysis report            │ Output: Code files            │  │
│  └────────────────────────────────────┴─────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ TESTER AGENT                      │ [EXTENSIBLE FOR MORE]          │  │
│  ├────────────────────────────────────┼─────────────────────────────┤  │
│  │ • Runs test suites                 │ • Reviewer Agent              │  │
│  │ • Parses test output               │ • Debugger Agent              │  │
│  │ • Analyzes failures                │ • Documentation Agent         │  │
│  │ • Reports coverage                 │ • Performance Agent           │  │
│  │ • Suggests test cases              │ • Security Agent              │  │
│  │                                    │                               │  │
│  │ Output: Test results               │ Output: Specialized insights  │  │
│  └────────────────────────────────────┴─────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ Agent Communication Layer (gRPC)                                    │  │
│  │ • Receives: Tasks from Task Queue                                  │  │
│  │ • Sends: Results back to Task Queue                                │  │
│  │ • Receives: Stimulus (emergency stop, status check)                │  │
│  │ • Protocol: gRPC + Protobuf (type-safe, efficient)                 │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ Execution Sandbox (WASM + Docker)                                  │  │
│  │ • Primary: WebAssembly (wasmtime)                                  │  │
│  │   - 5-20ms startup time                                            │  │
│  │   - Memory-safe execution                                          │  │
│  │   - Fuel-based instruction limits                                  │  │
│  │   - No network access by default                                   │  │
│  │ • Fallback: Docker containers                                      │  │
│  │   - For heavy libraries (numpy, pandas)                            │  │
│  │   - For compute-intensive tasks                                    │  │
│  │   - Slower but more compatible                                     │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ Reflex Layer (Safety & Emergency)                                  │  │
│  │ • Emergency Stop: Bypass planning, stop immediately                │  │
│  │ • Safety Constraints: Never delete user files                      │  │
│  │ • Rate Limiting: Never spam LLM API                                │  │
│  │ • Resource Limits: Memory, CPU, timeout enforced                   │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  External Dependencies:                                                 │
│  → Git Repository (reads/writes code)                                  │
│  → WASM/Docker (code execution)                                        │
│  → NATS JetStream (event reporting)                                    │
└──────────────────────────────────────────────────────────────────────────┘


┌──────────────────────────────────────────────────────────────────────────┐
│  PERSISTENT STORAGE & ANALYTICS CONTAINER                                │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────────┐                                                │
│  │ Redis Cluster        │  World State                                   │
│  │ (3-node HA)          │  • <1ms queries                               │
│  │                      │  • Distributed locks                          │
│  │                      │  • Pub/Sub for events                         │
│  └──────────────────────┘                                                │
│                                                                           │
│  ┌──────────────────────┐                                                │
│  │ NATS JetStream       │  Event Bus                                    │
│  │ (Clustered)          │  • 1M+ events/sec throughput                  │
│  │                      │  • Full message replay (7 days)               │
│  │                      │  • Durable subscriptions                      │
│  └──────────────────────┘                                                │
│                                                                           │
│  ┌──────────────────────┐                                                │
│  │ ClickHouse           │  Analytics & Time-Series                      │
│  │ (Clustered)          │  • <100ms queries on billions of rows         │
│  │                      │  • 50:1 compression                           │
│  │                      │  • TTL-based archival                         │
│  └──────────────────────┘                                                │
│                                                                           │
│  ┌──────────────────────┐                                                │
│  │ Neo4j                │  Knowledge Graph                              │
│  │ (Property Graph DB)  │  • Agent-File-Decision relationships          │
│  │                      │  • Root cause analysis (trace backwards)       │
│  │                      │  • Decision impact analysis                    │
│  └──────────────────────┘                                                │
│                                                                           │
│  ┌──────────────────────┐                                                │
│  │ ChromaDB             │  Vector Embeddings                            │
│  │ (Vector Store)       │  • Similar situation search                   │
│  │                      │  • Episodic memory for learning               │
│  │                      │  • Semantic search of past experiences        │
│  └──────────────────────┘                                                │
│                                                                           │
│  ┌──────────────────────┐                                                │
│  │ S3 / Object Store    │  Historical Archive                           │
│  │                      │  • Events older than 7 days                   │
│  │                      │  • Parquet format (compressed)                │
│  │                      │  • Long-term analysis capability              │
│  └──────────────────────┘                                                │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
      ↑↓ All containers write/read events
      Event streaming & state synchronization

┌──────────────────────────────────────────────────────────────────────────┐
│  EXTERNAL INTEGRATIONS                                                    │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌───────────────┐  │
│  │ LLM Services         │  │ Git Repository       │  │ Kubernetes    │  │
│  │ (Claude, GPT, etc)   │  │ (GitHub, GitLab)     │  │ (Deployment)  │  │
│  │                      │  │                      │  │               │  │
│  │ • Planning prompts   │  │ • Source of truth    │  │ • Orchestrator│  │
│  │ • Code analysis      │  │ • Code commits       │  │ • Task Queue  │  │
│  │ • Anomaly analysis   │  │ • Test results       │  │ • Agents      │  │
│  └──────────────────────┘  └──────────────────────┘  └───────────────┘  │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

## C2: Key Containers

### 1. Orchestrator Container (Layer 1)
- **Purpose**: Strategic planning
- **Frequency**: 10-minute cycles
- **Cost**: High (LLM usage)
- **Components**: Mission Planner, Goal Manager, Resource Allocator
- **External Deps**: LLM Services, Redis

### 2. Task Queue Container (Layer 2)
- **Purpose**: State management & anomaly detection
- **Frequency**: 100-500ms cycles
- **Cost**: Medium
- **Components**: World Model, Consistency Detector, Task Queue, Parametrizer
- **External Deps**: Redis, NATS, ClickHouse

### 3. Agent Framework Container (Layer 3)
- **Purpose**: Task execution
- **Frequency**: Continuous
- **Cost**: Low
- **Components**: Multiple agent types (Analyzer, Coder, Tester, extensible)
- **External Deps**: Git, WASM/Docker, NATS

### 4. Persistent Storage & Analytics
- **Purpose**: Learning, analytics, reliability
- **Components**: Redis, NATS, ClickHouse, Neo4j, ChromaDB, S3
- **Frequency**: Real-time streaming
- **Cost**: Manageable through tiering (hot→cold progression)

---

# C3: COMPONENT DIAGRAM
## Layer by Layer Detailed Components

## C3.1: ORCHESTRATOR CONTAINER COMPONENTS

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR CONTAINER                               │
│               Strategic Planning & Goal Supervision                     │
└─────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│ gRPC Server (Actix-web + Tokio)                                        │
│                                                                         │
│ Endpoints:                                                              │
│ • POST /api/v1/orchestrator/plan                                       │
│   Input: {user_request: String, context: WorldModel}                   │
│   Output: {plan: TaskDAG, estimated_duration: Duration}                │
│                                                                         │
│ • GET /api/v1/orchestrator/status/{goal_id}                            │
│   Output: {status: String, progress: f64, current_task: Task}          │
│                                                                         │
│ • POST /api/v1/orchestrator/replan/{goal_id}                           │
│   Input: {reason: String, new_context: WorldModel}                     │
│   Output: {new_plan: TaskDAG}                                          │
│                                                                         │
│ Protocol: gRPC with HTTP/2 multiplexing                                │
│ Security: Mutual TLS, service account authentication                   │
│ Performance: <100ms response time for plan requests                     │
└────────────────────────────────────────────────────────────────────────┘
         ↓ Sends planning requests (every 10 minutes)
┌────────────────────────────────────────────────────────────────────────┐
│ Mission Planner (LLM-Based Planning Engine)                            │
│                                                                         │
│ Input Channels:                                                         │
│ • User request: "Implement user authentication"                        │
│ • Current world model: File structure, test status, agent state        │
│ • Goal history: Previous attempts, lessons learned                     │
│ • Capability list: What agents can do                                  │
│                                                                         │
│ Processing Pipeline:                                                   │
│ 1. Parse request → Extract intent, constraints, success criteria      │
│ 2. Analyze context → Current code state, existing patterns            │
│ 3. Generate outline → Rough steps to achieve goal                     │
│ 4. Decompose → Break into smaller tasks                               │
│ 5. Order tasks → Respecting dependencies                              │
│ 6. Estimate effort → Per-task time estimates                          │
│ 7. Assign agents → Based on capabilities                              │
│                                                                         │
│ LLM Interaction:                                                        │
│ • Model: Claude 3.5 Sonnet (primary), Haiku (fallback)                │
│ • Prompt Engineering: 5-shot examples of good task decomposition      │
│ • Token Usage: ~2000 tokens average per planning cycle                │
│ • Cost: ~$0.003 per planning cycle                                    │
│ • Latency: 20-30 seconds to generate complete plan                    │
│                                                                         │
│ Output: Task DAG (Directed Acyclic Graph)                             │
│ {                                                                       │
│   "goal_id": "impl_auth_001",                                         │
│   "tasks": [                                                            │
│     {                                                                   │
│       "id": "analyze_auth_001",                                        │
│       "type": "analyze",                                               │
│       "description": "Analyze authentication requirements",            │
│       "assigned_agent": "analyzer_1",                                  │
│       "dependencies": [],                                              │
│       "estimated_duration": "5m"                                       │
│     },                                                                  │
│     {                                                                   │
│       "id": "code_auth_001",                                           │
│       "type": "code_generation",                                       │
│       "description": "Implement authentication logic",                 │
│       "assigned_agent": "coder_1",                                     │
│       "dependencies": ["analyze_auth_001"],                            │
│       "estimated_duration": "15m"                                      │
│     },                                                                  │
│     ...                                                                 │
│   ],                                                                    │
│   "total_estimated_duration": "45m"                                    │
│ }                                                                        │
│                                                                         │
│ Failure Handling:                                                       │
│ • LLM timeout: Use cached previous plan                                │
│ • Invalid decomposition: Fall back to simpler task structure           │
│ • Rate limit hit: Queue and retry with backoff                        │
│                                                                         │
│ Learning Integration:                                                  │
│ • Stores: Each plan and its outcome (success/failure)                 │
│ • Analyzes: Which decompositions work well for which task types       │
│ • Adapts: Incorporates successful patterns in future plans            │
└────────────────────────────────────────────────────────────────────────┘
         ↓ Tracks goal progress and success
┌────────────────────────────────────────────────────────────────────────┐
│ Goal Manager (Goal Tracking & Supervision)                             │
│                                                                         │
│ State Management:                                                       │
│ {                                                                       │
│   "goal_id": "impl_auth_001",                                          │
│   "description": "Implement user authentication",                      │
│   "status": "in_progress",                                             │
│   "subtasks": {                                                         │
│     "analyze_auth_001": {                                              │
│       "status": "completed",                                           │
│       "completed_at": "2025-11-21T10:05:30Z",                          │
│       "result": "Requirements: OAuth2 + JWT + session management"      │
│     },                                                                  │
│     "code_auth_001": {                                                 │
│       "status": "in_progress",                                         │
│       "started_at": "2025-11-21T10:06:00Z",                            │
│       "assigned_to": "coder_1"                                         │
│     },                                                                  │
│     "test_auth_001": {                                                 │
│       "status": "pending",                                             │
│       "depends_on": "code_auth_001"                                    │
│     }                                                                   │
│   },                                                                    │
│   "progress": 0.33,  // 1/3 complete                                  │
│   "created_at": "2025-11-21T10:00:00Z",                                │
│   "estimated_completion": "2025-11-21T10:45:00Z",                      │
│   "replan_count": 0,  // How many times plan changed                  │
│   "anomalies_detected": 0                                              │
│ }                                                                        │
│                                                                         │
│ Responsibilities:                                                       │
│ • Track: Every subtask and its status                                  │
│ • Detect completion: All subtasks done → goal complete                 │
│ • Detect failure: Timeout or error threshold exceeded                  │
│ • Detect divergence: Plan off-track (ask Task Queue)                   │
│ • Trigger replan: If major issues detected                             │
│ • Report progress: Every 10 seconds to Task Queue                      │
│                                                                         │
│ Success Criteria:                                                       │
│ Goal completed when:                                                    │
│ ✓ All subtasks show "completed" status                                 │
│ ✓ No unresolved anomalies                                              │
│ ✓ Final tests passing (if applicable)                                  │
│ ✓ Within estimated time (or accepted overrun)                          │
│                                                                         │
│ Failure Criteria:                                                       │
│ Goal failed when:                                                       │
│ ✗ Timeout exceeded (default: 2x estimated time)                        │
│ ✗ Too many subtask failures (>30% failing)                             │
│ ✗ Critical anomaly unresolvable (3+ attempts)                          │
│ ✗ Resource exhaustion (LLM quota, disk space)                          │
└────────────────────────────────────────────────────────────────────────┘
         ↓ Requests resource allocation
┌────────────────────────────────────────────────────────────────────────┐
│ Resource Allocator (Capability & Load Matching)                        │
│                                                                         │
│ Agent Capability Registry:                                              │
│ {                                                                       │
│   "analyzer_1": {                                                       │
│     "type": "analyzer",                                                │
│     "capabilities": ["code_analysis", "pattern_detection"],            │
│     "languages": ["python", "rust", "javascript"],                     │
│     "skills": ["security_analysis", "performance_analysis"],           │
│     "max_concurrent_tasks": 3,                                         │
│     "current_load": 1,  // Currently executing 1 task                 │
│     "success_rate": 0.98,  // 98% task success rate                   │
│     "avg_task_duration": "4m",  // Average execution time              │
│     "availability": "available"                                        │
│   },                                                                    │
│   "coder_1": {                                                          │
│     "type": "coder",                                                   │
│     "capabilities": ["code_generation", "refactoring"],                │
│     "languages": ["python", "rust", "javascript", "go"],               │
│     "skills": ["async_patterns", "design_patterns"],                   │
│     "max_concurrent_tasks": 2,                                         │
│     "current_load": 0,  // Available                                  │
│     "success_rate": 0.95,  // 95% task success rate                   │
│     "avg_task_duration": "12m",                                        │
│     "availability": "available"                                        │
│   },                                                                    │
│   ...                                                                   │
│ }                                                                        │
│                                                                         │
│ Task-to-Agent Matching Algorithm:                                      │
│ 1. Filter agents by capability match                                   │
│   Input: Task type "implement_auth_function"                           │
│   Filter: Agents with "code_generation" capability                     │
│   Candidates: [coder_1, coder_2, coder_3]                              │
│                                                                         │
│ 2. Filter by load balance                                              │
│   Sort by: current_load / max_concurrent_tasks                         │
│   Scores:                                                               │
│   - coder_1: 0 / 2 = 0.0  (fully available)                            │
│   - coder_2: 2 / 2 = 1.0  (fully loaded)                               │
│   - coder_3: 1 / 3 = 0.33 (partially loaded)                           │
│   Candidates: [coder_1, coder_3]                                       │
│                                                                         │
│ 3. Select best-fit agent                                               │
│   Score: success_rate × availability × load_balance                    │
│   coder_1: 0.95 × 1.0 × (1 - 0.0) = 0.95                              │
│   coder_3: 0.92 × 1.0 × (1 - 0.33) = 0.62                              │
│   Selected: coder_1 (highest score)                                    │
│                                                                         │
│ Output: {agent_id: "coder_1", confidence: 0.95}                       │
│                                                                         │
│ Dynamic Adjustment:                                                    │
│ • Monitor task success/failure                                         │
│ • Update agent success_rate                                            │
│ • Reassign subsequent tasks based on performance                       │
│ • Handle agent failures (find replacement)                             │
│                                                                         │
│ Load Balancing:                                                        │
│ • Never overload any agent                                             │
│ • Prefer underutilized agents                                          │
│ • Consider agent specialization                                        │
│ • Account for task priority                                            │
└────────────────────────────────────────────────────────────────────────┘

[Each component communicates via well-defined interfaces]
[All state changes logged to event bus for auditability]
[All components report metrics to monitoring/observability stack]
```

## C3.2: TASK QUEUE CONTAINER COMPONENTS

```
┌─────────────────────────────────────────────────────────────────────────┐
│              TASK QUEUE MANAGER CONTAINER                               │
│           Situation Assessment & Anomaly Detection                      │
└─────────────────────────────────────────────────────────────────────────┘

[Similar detailed breakdown for:]
• World Model Component
  - File state tracking (hashes, timestamps)
  - Test results storage (pass/fail/timeout)
  - Agent status tracking
  - Decision history
  - Query interface (<1ms latency)

• Consistency Violation Detector Component
  - Expectation recording (before action)
  - Actual result capture (after action)
  - Comparison logic
  - Violation categorization
  - Investigation trigger
  - Learning feedback

• Task Queue Component
  - Priority queue implementation
  - Dependency resolution
  - Task assignment
  - Result collection
  - Timeout handling

• Parametrization Engine Component
  - Intent mapping (high-level → low-level)
  - Parameter generation (context-aware)
  - Validation
  - Optimization hints
```

## C3.3: AGENT FRAMEWORK CONTAINER COMPONENTS

```
┌─────────────────────────────────────────────────────────────────────────┐
│               AGENT FRAMEWORK CONTAINER                                 │
│                Task Execution                                           │
└─────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│ Analyzer Agent Component                                                │
│                                                                         │
│ Inputs: Code files, requirements, test results                         │
│ Processing:                                                             │
│ • Static code analysis (complexity, patterns)                          │
│ • Dynamic analysis (test coverage, performance)                        │
│ • Pattern detection (duplicated code, anti-patterns)                   │
│ • Requirement matching (is code implementing spec?)                    │
│ Outputs: Analysis report, recommendations                             │
│ Latency: <1s for small projects, <5s for large                        │
│ Cost: $ (no LLM calls during execution)                                │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│ Coder Agent Component                                                   │
│                                                                         │
│ Inputs: Specification, existing code, style guide                      │
│ Processing:                                                             │
│ • LLM code generation (Claude for multi-line functions)                │
│ • Integration with existing code (imports, dependencies)               │
│ • Style enforcement (formatting, conventions)                          │
│ • Validation (syntax checking, compilation)                           │
│ Outputs: Generated code file, metrics                                  │
│ Latency: 3-10s depending on code size                                  │
│ Cost: $$$ (uses LLM, but caching helps)                                │
│ Strategy: Delegate to Task Queue for smarter caching                   │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│ Tester Agent Component                                                  │
│                                                                         │
│ Inputs: Test files, code implementation                                │
│ Processing:                                                             │
│ • Test discovery (find all tests)                                      │
│ • Test execution (run in sandbox)                                      │
│ • Result parsing (extract pass/fail/error)                             │
│ • Coverage analysis (which lines tested)                               │
│ • Failure analysis (root cause of failures)                            │
│ Outputs: Test results, coverage report                                 │
│ Latency: 1-30s depending on test count                                 │
│ Cost: $ (no LLM calls)                                                 │
│ Reliability: 99%+ (tests either pass or fail, clear signal)            │
└────────────────────────────────────────────────────────────────────────┘

[Extensible framework allows adding:]
• Reviewer Agent (code review, security check)
• Debugger Agent (step-by-step debugging)
• Documentation Agent (generate docstrings)
• Performance Agent (profiling, optimization)
• Security Agent (vulnerability scanning)
```

---

# C4: CODE LEVEL DIAGRAM
## Detailed Implementation Patterns

## C4.1: Data Structures

```rust
// Task representation
#[derive(Serialize, Deserialize, Clone)]
pub struct Task {
    pub id: String,
    pub goal_id: String,
    pub task_type: TaskType,
    pub description: String,
    pub assigned_agent: Option<String>,
    pub dependencies: Vec<String>,
    pub estimated_duration: Duration,
    pub priority: Priority,
    pub parameters: HashMap<String, Value>,
    pub expected_result: Option<String>,
    pub created_at: DateTime<Utc>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub status: TaskStatus,
    pub result: Option<TaskResult>,
}

#[derive(Serialize, Deserialize, Clone)]
pub enum TaskType {
    Analyze { target: String },
    CodeGeneration { specification: String },
    Testing { test_file: String },
    CodeReview { target: String },
    Documentation { target: String },
    // Extensible
}

#[derive(Serialize, Deserialize, Clone)]
pub struct TaskResult {
    pub success: bool,
    pub output: String,
    pub metrics: Metrics,
    pub anomalies: Vec<Anomaly>,
}

// World model representation
#[derive(Serialize, Deserialize, Clone)]
pub struct WorldModel {
    pub files: HashMap<String, FileState>,
    pub tests: HashMap<String, TestResult>,
    pub agents: HashMap<String, AgentStatus>,
    pub decisions: Vec<Decision>,
    pub timestamp: DateTime<Utc>,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct FileState {
    pub path: String,
    pub content_hash: String,
    pub last_modified: DateTime<Utc>,
    pub last_modifier: String,
    pub language: String,
    pub size_bytes: u64,
}

// Consistency violation representation
#[derive(Serialize, Deserialize, Clone)]
pub struct ConsistencyViolation {
    pub violation_id: String,
    pub task_id: String,
    pub violation_type: String,
    pub expected: String,
    pub actual: String,
    pub detected_at: DateTime<Utc>,
    pub investigation: Option<Investigation>,
    pub resolved: bool,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Investigation {
    pub investigation_id: String,
    pub started_at: DateTime<Utc>,
    pub actions_taken: Vec<String>,
    pub findings: String,
    pub root_cause: Option<String>,
    pub resolution: Option<String>,
}
```

## C4.2: API Contracts (gRPC)

```protobuf
// orchestrator.proto
syntax = "proto3";

service Orchestrator {
  // Plan a high-level goal
  rpc Plan(PlanRequest) returns (PlanResponse);

  // Check status of a goal
  rpc GetGoalStatus(GetGoalStatusRequest)
    returns (GetGoalStatusResponse);

  // Replan based on new information
  rpc Replan(ReplanRequest) returns (PlanResponse);
}

message PlanRequest {
  string user_request = 1;  // "Implement user authentication"
  WorldModel context = 2;
  repeated string constraints = 3;
}

message PlanResponse {
  string goal_id = 1;
  repeated Task tasks = 2;
  string estimated_duration = 3;
}

// task_queue.proto
service TaskQueue {
  // Send plan to task queue
  rpc EnqueuePlan(PlanRequest) returns (EnqueueResponse);

  // Get next task for agent
  rpc DequeueTask(DequeueRequest) returns (Task);

  // Report task completion
  rpc ReportResult(TaskResult) returns (AckResponse);

  // Get world model
  rpc GetWorldModel(EmptyRequest) returns (WorldModel);
}

// agent.proto
service Agent {
  // Execute a task
  rpc Execute(Task) returns (TaskResult);

  // Get agent status
  rpc GetStatus(EmptyRequest) returns (AgentStatus);

  // Emergency stop
  rpc EmergencyStop(EmptyRequest) returns (AckResponse);
}
```

## C4.3: Communication Flow Examples

```
SUCCESSFUL FLOW:
─────────────────

1. User: "Implement user authentication"
   ↓
2. Orchestrator.Plan():
   Input: { user_request: "Implement user authentication" }
   Process: Use LLM to decompose
   Output: { goal_id: "auth_001", tasks: [analyze, code, test] }
   ↓
3. TaskQueue.EnqueuePlan():
   Input: Plan with 3 tasks
   Action: Add to queue, start assigning to agents
   ↓
4. TaskQueue.DequeueTask(analyzer_1):
   Returns: Task { id: "analyze_1", type: Analyze, ... }
   ↓
5. Analyzer.Execute(task):
   Input: Task
   Process: Read requirements, analyze existing code
   Output: { success: true, output: "Requirements analyzed" }
   ↓
6. TaskQueue.ReportResult():
   Input: TaskResult from analyzer
   Action: Update world model, queue next task
   ↓
7. TaskQueue.DequeueTask(coder_1):
   Returns: Task { id: "code_1", type: CodeGeneration, ... }
   ↓
8. Coder.Execute(task):
   Input: Task with specification from analysis
   Process: Generate code using LLM
   Output: { success: true, output: "Generated auth.rs" }
   ↓
9. TaskQueue.ReportResult():
   Input: Code generation result
   Action: Update world model, verify syntax, queue test
   ↓
10. TaskQueue.DequeueTask(tester_1):
    Returns: Task { id: "test_1", type: Testing, ... }
    ↓
11. Tester.Execute(task):
    Input: Test file to run
    Process: Execute tests in WASM sandbox
    Output: { success: true, output: "All tests passing (45/45)" }
    ↓
12. TaskQueue.ReportResult():
    Input: Test results
    Action: Check for consistency violations
    Status: No violations detected
    ↓
13. Orchestrator.GetGoalStatus("auth_001"):
    Returns: { status: "completed", progress: 1.0 }
    ↓
14. User: Goal completed! "Implement user authentication" is done.


ERROR RECOVERY FLOW:
─────────────────────

1. ... (steps 1-10 same as above)
   ↓
11. Tester.Execute(task):
    Input: Test file to run
    Expected: All tests pass
    Process: Execute tests in WASM sandbox
    Actual Output: { success: false, failures: [
      { test: "test_login", error: "Session not created" }
    ]}
    ↓
12. TaskQueue.ReportResult():
    Input: Test failed

    CONSISTENCY CHECK:
    Expected: "Tests should pass"
    Actual: "test_login failed"
    → VIOLATION DETECTED!
    ↓
13. ConsistencyDetector.Investigate():
    Question: "Why did test fail when code looked right?"
    Analysis Steps:
    • Check recent code changes
    • Review error message: "Session not created"
    • Hypothesis: Session.save() call missing
    ↓
14. Investigation finds:
    Root Cause: "Auth code doesn't call session.save()"
    Recommendation: "Add session.save() after auth success"
    ↓
15. Orchestrator.Replan("auth_001"):
    Input: { reason: "Test failed - session creation missing" }
    Process: Revise plan to fix auth implementation
    Output: New plan with "Fix session creation" task
    ↓
16. TaskQueue receives new plan:
    Enqueues: Task { id: "fix_session_1", type: CodeGeneration }
    ↓
17. Coder.Execute(new_task):
    Input: "Fix auth code to save session"
    Process: Generate fix
    Output: Updated auth.rs with session.save()
    ↓
18. TaskQueue.ReportResult():
    Input: Updated code
    Action: Queue test again
    ↓
19. Tester.Execute(test_again):
    Process: Run tests again
    Output: { success: true, output: "All tests passing (45/45)" }
    ↓
20. LEARNING:
    Orchestrator stores:
    • Original plan → Caused failure
    • Error: Session creation missing
    • Fix that worked: Add session.save()
    • Future: When generating auth code, always check session handling
    ↓
21. User: Goal completed! (with autonomous recovery)
```

---

## Summary: Four Levels of C4 Model

| Level | Focus | Detail | Audience |
|-------|-------|--------|----------|
| **C1** | System Context | External actors, responsibilities | Everyone |
| **C2** | Containers | High-level building blocks (Orchestrator, Task Queue, Agents) | Architects, leads |
| **C3** | Components | Internal architecture of each container | Senior engineers |
| **C4** | Code | Implementation details, algorithms, data structures | Developers |

This C4 model provides a complete blueprint from high-level architecture down to code-level implementation details.

---

**Status**: ✅ Complete
**Date**: November 21, 2025
**Ready for**: Implementation, code review, system design discussions

