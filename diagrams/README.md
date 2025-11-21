# C4 Architecture Diagrams - Mermaid Format

This directory contains the complete C4 Model architecture diagrams for CODITECT Next Generation in Mermaid (MMD) format.

## Diagrams Included

### C1: System Context Diagram
**File**: `C1-SYSTEM-CONTEXT.mmd`
**Purpose**: Shows CODITECT system in relation to external systems and users
**Elements**:
- External actors (Developer/Team, LLM Services, Git, Analytics)
- System boundary (CODITECT)
- High-level layers (Orchestrator, Task Queue, Agents, Memory)
- Information flows (requests, results, events)

**Key Elements**:
- Developer sends feature requests
- System sends code results back
- LLM called for strategic planning (1 call per 10 minutes)
- Git repository as source of truth
- Analytics databases receive all events
- Memory system for learning

### C2: Container Diagram
**File**: `C2-CONTAINER.mmd`
**Purpose**: Shows CODITECT broken down into major containers/services
**Containers**:
1. **Layer 1: Orchestrator** (Strategic Planning)
   - gRPC Server, Mission Planner, Goal Manager, Resource Allocator
   - Update frequency: 10 minutes
   - Cost: HIGH (LLM usage)

2. **Layer 2: Task Queue Manager** (Situation Assessment)
   - gRPC/REST Server, World Model, Consistency Detector, Task Queue, Parametrization Engine
   - Update frequency: 100-500ms
   - Cost: MEDIUM

3. **Layer 3: Agent Framework** (Task Execution)
   - gRPC Server, Worker Agents (Analyzer, Coder, Tester)
   - Execution Sandbox (WASM + Docker)
   - Reflex Safety Layer
   - Update frequency: Continuous
   - Cost: LOW

4. **Persistent Storage & Analytics**
   - Redis Cluster (state, <1ms latency)
   - NATS JetStream (event bus, 1M+ events/sec)
   - ClickHouse (time-series analytics, <100ms queries)
   - Neo4j (knowledge graph)
   - ChromaDB (vector embeddings)
   - S3 (historical archive)

**Color Coding**:
- Yellow: Layer 1 (Orchestrator)
- Green: Layer 2 (Task Queue)
- Blue: Layer 3 (Agents)
- Light Green: Storage & Analytics

### C3: Component Diagram
**File**: `C3-COMPONENT.mmd`
**Purpose**: Details the internal components of each container
**Orchestrator Components**:
- gRPC Server (with all endpoints)
- Mission Planner (LLM-based, task decomposition)
- Goal Manager (tracking, progress, supervision)
- Resource Allocator (capability matching, load balancing)

**Task Queue Components**:
- gRPC/REST Server (task distribution)
- World Model (file state, test results, agent status)
- Consistency Violation Detector (expectation vs actual)
- Task Queue (priority, dependencies)
- Parametrization Engine (intent to action mapping)

**Agent Framework Components**:
- gRPC Server (agent communication)
- Analyzer Agent (code analysis)
- Coder Agent (code generation)
- Tester Agent (test execution)
- Execution Sandbox (WASM primary, Docker fallback)
- Reflex Layer (safety, emergency stop)

**Storage Components**:
- Redis Cluster (state, locks, pub/sub)
- NATS JetStream (event streaming)
- ClickHouse (analytics)
- Neo4j (knowledge graph)
- ChromaDB (vector embeddings)

### C4: Code Level Diagram
**File**: `C4-CODE.mmd`
**Purpose**: Shows implementation details and data structures
**Data Structures**:
- Task (with all fields)
- TaskType (enum variants)
- WorldModel (state management)
- FileState (file tracking)
- ConsistencyViolation (anomalies)
- Investigation (root cause analysis)

**gRPC Service Definitions**:
- Orchestrator Service (Plan, GetStatus, Replan)
- TaskQueue Service (EnqueuePlan, DequeueTask, ReportResult, GetWorldModel)
- Agent Service (Execute, GetStatus, EmergencyStop)

**Key Algorithms**:
- Mission Planning Algorithm (7 steps)
- Consistency Detection Algorithm (6 steps)
- Resource Matching Algorithm (4 steps)

**Data Flow Sequences**:
- Success Flow (7 steps from request to completion)
- Error Recovery Flow (9 steps with anomaly detection and fix)

**Protobuf Message Definitions**:
- PlanRequest, PlanResponse
- Task message format
- TaskResult message format

---

## How to View These Diagrams

### Option 1: GitHub
Simply navigate to any `.mmd` file in this directory on GitHub. GitHub automatically renders Mermaid diagrams.

### Option 2: Mermaid Live Editor
1. Go to https://mermaid.live
2. Copy the contents of any `.mmd` file
3. Paste into the editor
4. View the rendered diagram
5. Export as PNG, SVG, or PDF if needed

### Option 3: Local Rendering
Many tools support Mermaid rendering:
- VSCode with Mermaid extension
- Obsidian with Mermaid plugin
- Notion (native support)
- Confluence with Mermaid plugin
- MkDocs with pymdown-extensions
- Markdown processors with mermaid support

### Option 4: Command Line
Using `mermaid-cli`:
```bash
npm install -g @mermaid-js/mermaid-cli

# Convert to PNG
mmdc -i C1-SYSTEM-CONTEXT.mmd -o C1-SYSTEM-CONTEXT.png

# Convert to SVG
mmdc -i C1-SYSTEM-CONTEXT.mmd -o C1-SYSTEM-CONTEXT.svg -t dark
```

---

## Diagram Details

### Color Scheme
- **Yellow (#fff9c4)**: Layer 1 (Orchestrator) - Strategic Planning
- **Green (#c8e6c9)**: Layer 2 (Task Queue) - Situation Assessment
- **Blue (#bbdefb)**: Layer 3 (Agents) - Execution
- **Light Green (#f0f4c3)**: Storage & Analytics
- **Gray (#f5f5f5)**: External Systems

### Interaction Patterns
1. **Downward Flow**: Orders and goals flowing down layers
2. **Upward Flow**: Results and anomalies flowing up
3. **Side Connections**: Consistency violations triggering investigation
4. **Event Publishing**: All layers emit events to storage layer

### Latency Characteristics
- **Layer 1**: 10-minute cycles (slow, expensive, strategic)
- **Layer 2**: 100-500ms cycles (medium, detection)
- **Layer 3**: Continuous execution (fast, local)

### Cost Distribution
- **Layer 1**: HIGH (LLM calls)
- **Layer 2**: MEDIUM (state ops + selective LLM)
- **Layer 3**: LOW (no LLM, cheap execution)

---

## Using Diagrams for Different Purposes

### For Presentation
1. Use GitHub or Mermaid Live Editor to display
2. Take screenshots for slides
3. Export high-quality images (PNG/SVG)

### For Documentation
1. Embed in markdown files using Mermaid code blocks
2. Link to GitHub raw files
3. Export as high-res images

### For Implementation
1. Use as reference for component boundaries
2. Use for understanding data flows
3. Use for team onboarding

### For Design Review
1. Present C1 for system context
2. Present C2 for architecture overview
3. Present C3 for component details
4. Present C4 for implementation specifics

---

## Mermaid Features Used

These diagrams leverage Mermaid's capabilities:
- **Subgraphs**: Grouping related components
- **Nodes**: Individual components and systems
- **Edges**: Connections and data flows
- **Styling**: Color coding by layer
- **Labels**: Detailed component descriptions

---

## Extending These Diagrams

To add new components or flows:

1. Open the relevant `.mmd` file
2. Add new subgraph for major feature area
3. Add new nodes for components
4. Connect with appropriate edges
5. Update styling as needed
6. Test rendering

Example format for new component:
```
ComponentName["Component Name<br/><br/>Property 1: value<br/>Property 2: value"]
```

---

## Integration with Documentation

These diagrams are referenced in:
- `C4-ARCHITECTURE-MODEL.md` (detailed explanations)
- `SDD-SOFTWARE-DESIGN-DOCUMENT.md` (architecture section)
- `README.md` (overview section)

---

## Version Control

These files are version controlled. Always update diagrams when:
- Adding new components
- Changing communication patterns
- Modifying storage systems
- Updating algorithms
- Changing layer responsibilities

---

**Last Updated**: November 21, 2025
**Format**: Mermaid (MMD)
**Status**: Complete - All 4 levels documented
**Audience**: All technical stakeholders

