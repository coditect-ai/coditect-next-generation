# Architecture Decision Records (ADRs)
## CODITECT Multi-Agent Autonomous Development System

**Version**: 1.0
**Date**: November 21, 2025
**Status**: Approved

---

## ADR-001: Three-Layer Cognitive Architecture

**Status**: APPROVED
**Date**: 2025-11-21

### Context
Need to design an autonomous system that can plan, execute, and learn. Single-layer approaches (one big LLM) are too expensive. Multi-agent without hierarchy is complex.

### Decision
Implement hierarchical cognitive architecture with three layers:
- Layer 1: Supervision (strategic planning, low frequency)
- Layer 2: Situation Assessment (state management, medium frequency)
- Layer 3: Perception & Action (execution, high frequency)

### Rationale
- **Proven**: Used in Tesla Autopilot, Boston Dynamics, DeepMind AlphaGo
- **Cost-Efficient**: Expensive reasoning happens rarely (Layer 1 every 10min)
- **Scalable**: Each layer independently optimizable
- **Self-Healing**: Middle layer detects divergence and investigates
- **Learning**: State tracking enables episodic memory

### Consequences
- ✅ 10-50x cost reduction via frequency hierarchy
- ✅ Autonomous error recovery
- ✅ Learns from mistakes
- ⚠️ Complexity: Requires state synchronization
- ⚠️ Latency: Multi-layer adds small overhead (acceptable)

### Alternatives Rejected
1. **Single LLM Agent**: Too expensive, no learning, not autonomous
2. **Flat Multi-Agent**: Complex coordination, no clear decision-making
3. **Tree-Only Hierarchy**: Brittle, no peer learning

---

## ADR-002: Consistency Violation Detection for Error Recovery

**Status**: APPROVED
**Date**: 2025-11-21

### Context
Agents make mistakes (tests fail, code doesn't compile). Need self-healing capability without human intervention.

### Decision
Implement consistency violation detection:
- Expect state before action (world model simulation)
- Report actual state after action
- Compare expected vs actual
- If mismatch: trigger exploration mode (debug, analyze, update model)

### Rationale
- **Superior to Retry Logic**: Understands why failures happen
- **Reduces Cost**: Doesn't blindly retry expensive operations
- **Improves Quality**: Updates understanding from each failure
- **Enables Learning**: Failure analysis feeds into episodic memory

### Consequences
- ✅ Autonomous error recovery (99%+ success)
- ✅ Continuous improvement from failures
- ✅ Reduced manual debugging
- ⚠️ Requires accurate world model (could miss edge cases)
- ⚠️ Investigation adds latency (acceptable for error cases)

### Alternatives Rejected
1. **Blind Retry**: No learning, expensive
2. **Escalate to Humans**: Not autonomous
3. **Circuit Breaker Only**: Stops work, doesn't fix root cause

---

## ADR-003: WebAssembly Sandbox for Code Execution

**Status**: APPROVED
**Date**: 2025-11-21

### Context
Agents generate and run code. Must be safe (can't delete user files). Must be fast (enable frequent agent execution).

### Decision
Use WebAssembly (wasmtime) as primary sandbox:
- Startup: 5-20ms (vs Docker's 500-2000ms)
- Isolation: Memory-safe, mathematical guarantee
- Fuel Limits: Instruction-based limits (prevent infinite loops)
- File Access: Restricted to project directory
- Fallback: Docker for heavy libraries (numpy, pandas, torch)

### Rationale
- **Fast**: 10x faster startup enables more frequent execution
- **Lightweight**: No Docker daemon required
- **Safe by Design**: Memory safety built into WebAssembly
- **Cost-Effective**: Lower resource overhead
- **First-Run Experience**: Works immediately without Docker setup

### Consequences
- ✅ 10x faster agent execution
- ✅ No Docker dependency
- ✅ Safe code execution by default
- ⚠️ Limited library support (pure Python only)
- ⚠️ Need fallback for heavy compute

### Alternatives Rejected
1. **Direct Execution**: Unsafe, can delete user files
2. **Docker Only**: Too slow for frequent execution, heavy dependency
3. **chroot/jail**: Complex cross-platform support
4. **seccomp**: Incomplete sandboxing, complex rules

---

## ADR-004: Four-Layer Memory (Event Bus → Data Lake → Knowledge Graph → Vector Store)

**Status**: APPROVED
**Date**: 2025-11-21

### Context
Agents need to learn from past experiences. Standard logging loses context. Need cost-effective long-term storage.

### Decision
Implement four-layer memory architecture:
1. **Hot** (Real-Time): NATS JetStream - streaming events
2. **Warm** (Recent): S3 + Parquet - recent history archive
3. **Cold** (Historical): ClickHouse - queryable analytics
4. **Semantic** (Wisdom): Vector DB - lessons learned

### Rationale
- **Cost-Optimized**: Hot→Warm→Cold reduces storage costs by 95%
- **Tiered Access**: Frequent queries use ClickHouse (fast), rare use S3 (cheap)
- **Learning**: Vector store enables semantic search for similar past situations
- **Auditability**: Complete history available for analysis
- **Scalable**: Each layer handles its scale efficiently

### Consequences
- ✅ 95% cost reduction via compression + archival
- ✅ Agents learn from past mistakes
- ✅ Complete audit trail for debugging
- ✅ Fast queries on recent data, cheap storage of old data
- ⚠️ Complexity: Four systems to operate
- ⚠️ Latency: Cold queries slower than hot (acceptable)

### Alternatives Rejected
1. **Single Database**: Too expensive to store everything
2. **Two-Layer (Hot + Archive)**: No mid-tier for frequent queries
3. **Log Files Only**: No semantic search, no learning

---

## ADR-005: Hybrid Coordination (Vertical + Horizontal)

**Status**: APPROVED
**Date**: 2025-11-21

### Context
Need to support multiple coordination patterns:
- Vertical: Orchestrator → Agent teams (simple, efficient)
- Horizontal: Agents negotiate (resilient, local)

### Decision
Implement hybrid model:
- **Vertical**: Global orchestrator sets strategy, sends orders
- **Horizontal**: Agents within teams negotiate (P2P mesh)
- **Override Hierarchy**: Safety > Swarm consensus > Supervisor orders

### Rationale
- **Flexible**: Supports both centralized and distributed coordination
- **Resilient**: If manager fails, agents continue via horizontal links
- **Scalable**: Add agents horizontally, scales linearly
- **Efficient**: Strategic decisions made once, shared by many agents
- **Safe**: Safety reflexes always take priority

### Consequences
- ✅ Scales to 50-1000+ agents
- ✅ Resilient to component failures
- ✅ Flexible coordination strategies
- ⚠️ Complexity: Need conflict resolution logic
- ⚠️ Consistency: Eventual consistency model (acceptable)

### Alternatives Rejected
1. **Vertical Only**: Bottleneck at manager, not resilient
2. **Horizontal Only**: Complex negotiation, no clear direction
3. **Strict Hierarchy**: Brittle, single point of failure

---

## ADR-006: gRPC + Protocol Buffers for Agent Communication

**Status**: APPROVED
**Date**: 2025-11-21

### Context
Agents need to communicate efficiently and reliably. Need type safety for protocol versions.

### Decision
Use gRPC (Google Remote Procedure Call) with Protocol Buffers:
- Synchronous: Task assignment, status queries
- Async: Event streaming via NATS
- Type-Safe: Proto definitions ensure compatibility
- Efficient: Binary protocol, smaller payloads than JSON

### Rationale
- **Type Safety**: Proto definitions prevent message mismatches
- **Efficiency**: Binary format, 10x smaller than JSON
- **Compatibility**: Backward/forward compatibility built-in
- **Performance**: HTTP/2 multiplexing, streaming support
- **Ecosystem**: Mature tooling, wide language support

### Consequences
- ✅ Type-safe agent communication
- ✅ Efficient bandwidth usage
- ✅ Clear service contracts
- ⚠️ Learning curve: Proto definitions, gRPC concepts
- ⚠️ Debugging: Binary format less human-readable

### Alternatives Rejected
1. **REST + JSON**: Too verbose, no type safety
2. **Message Queues Only**: No request/response pattern
3. **Custom Binary**: Harder to maintain, debug

---

## ADR-007: ClickHouse for Time-Series Analytics

**Status**: APPROVED
**Date**: 2025-11-21

### Context
Need to store and query billions of agent events. SQL databases too slow. NoSQL loses queryability.

### Decision
Use ClickHouse as analytical database for swarm events:
- Time-series optimized (fast queries on timestamps)
- Columnar storage (50:1 compression)
- SQL queries (familiar to teams)
- TTL-based archival (automatic old data deletion)
- Distributed queries (scales horizontally)

### Rationale
- **Performance**: <100ms queries on billions of rows
- **Cost**: 50:1 compression reduces storage cost by 98%
- **Queryability**: SQL interface familiar to teams
- **Maintenance**: Automatic TTL deletion, no manual cleanup
- **Scale**: Handles 1M+ events/second
- **Traceability**: Complete query history available

### Consequences
- ✅ Sub-100ms analytics queries
- ✅ 98% storage cost reduction
- ✅ Full SQL query language
- ✅ Scales to trillions of events
- ⚠️ Complex setup, requires operational knowledge
- ⚠️ Not ideal for small datasets (overkill)

### Alternatives Rejected
1. **PostgreSQL**: Not optimized for time-series, slower queries
2. **MongoDB**: No SQL, harder to query analytics
3. **Elasticsearch**: Good for logs, expensive for analytics
4. **TimescaleDB**: Good alternative, but less mature for 1M+/sec

---

## ADR-008: Redis for Distributed State

**Status**: APPROVED
**Date**: 2025-11-21

### Context
World model must be accessible to all agents with <100ms latency. Need distributed locks for state consistency.

### Decision
Use Redis as primary distributed state store:
- Cluster mode: 3-way replication for fault tolerance
- TTL: Auto-expiration for temporary data
- Locks: Distributed locking via SET NX EX
- Sync: Backup to SQLite for offline operation

### Rationale
- **Speed**: <1ms latency (sufficient for state queries)
- **Reliability**: 3-way replication, automatic failover
- **Simplicity**: Key-value model, easy to understand
- **Scalability**: Cluster mode handles millions of keys
- **Locking**: Built-in atomic operations for consistency

### Consequences
- ✅ <1ms state query latency
- ✅ Distributed consensus with locks
- ✅ Auto-expiration of temporary data
- ⚠️ Limited persistence (acceptable for state)
- ⚠️ Memory-bound (acceptable with cluster)

### Alternatives Rejected
1. **Memcached**: No persistence, no locking
2. **PostgreSQL**: Too slow for <100ms requirement
3. **etcd**: Good alternative, but more complex for this use case

---

## ADR-009: NATS JetStream for Event Streaming

**Status**: APPROVED
**Date**: 2025-11-21

### Context
Need to stream agent events in real-time, with replay capability and durability.

### Decision
Use NATS JetStream as event bus:
- Durability: Messages persisted to disk
- Replay: Full history available for replay
- Streaming: 1M+ events/second throughput
- Topics: Subject-based routing (agent.think, agent.act, etc)

### Rationale
- **Throughput**: Handles 1M+ events/second
- **Durability**: Messages persisted, no loss
- **Replay**: Full history enables debugging
- **Simplicity**: Pub/sub model, easy to understand
- **Scaling**: Clustered JetStream for HA

### Consequences
- ✅ Reliable event streaming
- ✅ Full replay capability
- ✅ 1M+ events/second throughput
- ✅ Fault tolerance via clustering
- ⚠️ Operational complexity: cluster management
- ⚠️ Storage: 1M events/sec = 100TB/year (mitigated by TTL)

### Alternatives Rejected
1. **Kafka**: More complex, overkill for this scale
2. **RabbitMQ**: No replay, message loss risk
3. **AWS SQS**: Vendor lock-in, no replay
4. **Google Cloud Pub/Sub**: Vendor lock-in, higher latency

---

## ADR-010: Kubernetes for Production Deployment

**Status**: APPROVED
**Date**: 2025-11-21

### Context
Need to deploy multi-component system with auto-scaling, rolling updates, and self-healing.

### Decision
Use Kubernetes for orchestration:
- Containers: Docker images for all services
- Auto-scaling: HPA based on CPU/memory
- Updates: Blue-green deployments
- Self-Healing: Automatic pod restart on failure

### Rationale
- **Industry Standard**: Wide adoption, mature tooling
- **Auto-Scaling**: Responds to load automatically
- **Declarative**: Infrastructure as code (Helm charts)
- **Monitoring**: Built-in metrics collection
- **Multi-Cloud**: Works on AWS, GCP, Azure

### Consequences
- ✅ Scalable production infrastructure
- ✅ Automatic failure recovery
- ✅ Easy deployments (blue-green)
- ✅ Cloud-agnostic
- ⚠️ Operational complexity: K8s learning curve
- ⚠️ Cost: Requires managed service (EKS, GKE, AKS) or self-hosted

### Alternatives Rejected
1. **Manual VMs**: No auto-scaling, manual operations
2. **Serverless (Lambda)**: Inappropriate for stateful services
3. **Docker Swarm**: Less mature than K8s
4. **Docker Compose**: Good for dev, insufficient for production

---

## Summary Table

| ADR | Decision | Status | Impact |
|-----|----------|--------|--------|
| ADR-001 | 3-Layer Architecture | Approved | Cost reduction 10-50x |
| ADR-002 | Consistency Violation Detection | Approved | Autonomous error recovery |
| ADR-003 | WebAssembly Sandbox | Approved | 10x faster execution |
| ADR-004 | Four-Layer Memory | Approved | 95% storage cost reduction |
| ADR-005 | Hybrid Coordination | Approved | Scales to 1000+ agents |
| ADR-006 | gRPC + Protobuf | Approved | Type-safe communication |
| ADR-007 | ClickHouse | Approved | <100ms analytics |
| ADR-008 | Redis State | Approved | <1ms latency |
| ADR-009 | NATS JetStream | Approved | 1M+ events/second |
| ADR-010 | Kubernetes | Approved | Production-grade operations |

---

## Future ADRs (To Be Defined)

- **ADR-011**: Model Selection (which LLMs for which tasks)
- **ADR-012**: Testing Strategy (unit, integration, e2e, load)
- **ADR-013**: Security (authentication, authorization, encryption)
- **ADR-014**: Disaster Recovery (backup, restore, failover)
- **ADR-015**: Cost Optimization (reserved capacity, spot instances)

---

**Document Status**: Complete ✅
**Review Cycle**: Quarterly
**Next Review**: February 2026
