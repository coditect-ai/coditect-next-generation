# Database Architecture - SQLite & FoundationDB Integration

## Overview

The CODITECT system requires a comprehensive multi-database strategy to support:
- **Distributed ACID transactions** across autonomous agents (FoundationDB)
- **Local persistent state** on edge agents (SQLite)
- **High-speed state access** for coordination (Redis)
- **Long-term analytics** on agent behavior (ClickHouse)
- **Semantic search** for learned patterns (ChromaDB)

This document specifies the role and integration of **SQLite** and **FoundationDB**, which were underspecified in the initial architecture.

---

## Part 1: SQLite - Local Persistent Storage

### 1.1 Purpose & Role

**SQLite serves as the LOCAL PERSISTENT STATE store for each agent and component:**

```
Agent Runtime (Local Machine)
├── In-Memory State (Redis)
├── SQLite Local DB (disk-persisted)
│   ├── Agent configuration
│   ├── Cache of recent world model
│   ├── Task execution history
│   ├── Failed operation recovery
│   └── Offline-capable operations
└── NATS JetStream (network sync)
```

**When to use SQLite:**
- ✅ Local caching of remote world model (for offline capability)
- ✅ Agent configuration and capability registry
- ✅ Task execution history (for debugging)
- ✅ Failed operation recovery and retry queue
- ✅ Reproducibility and deterministic replay
- ✅ Development and testing environments

**When NOT to use SQLite:**
- ❌ Real-time coordination between agents (use Redis)
- ❌ Distributed transactions across agents (use FoundationDB)
- ❌ Analytics queries (use ClickHouse)
- ❌ Multi-agent shared state (use Redis cluster)

### 1.2 SQLite Schema Design

```sql
-- Agent Configuration
CREATE TABLE agent_config (
    agent_id TEXT PRIMARY KEY,
    agent_type TEXT NOT NULL,           -- analyzer, coder, tester, etc
    capabilities TEXT NOT NULL,          -- JSON array
    version TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_agent_type ON agent_config(agent_type);

-- Local World Model Cache
CREATE TABLE world_model_cache (
    cache_id TEXT PRIMARY KEY,
    agent_id TEXT NOT NULL,
    world_model_snapshot TEXT,           -- JSON
    synced_from_redis TIMESTAMP,
    expires_at TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agent_config(agent_id)
);
CREATE INDEX idx_agent_cache ON world_model_cache(agent_id);
CREATE INDEX idx_expires ON world_model_cache(expires_at);

-- Task Execution Log
CREATE TABLE task_execution_log (
    execution_id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    task_type TEXT NOT NULL,             -- Analyze, CodeGeneration, Testing, etc
    status TEXT NOT NULL,                -- pending, running, completed, failed
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    duration_ms INTEGER,
    input_params TEXT,                   -- JSON
    output_result TEXT,                  -- JSON
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_task_id ON task_execution_log(task_id);
CREATE INDEX idx_agent_id ON task_execution_log(agent_id);
CREATE INDEX idx_status ON task_execution_log(status);
CREATE INDEX idx_completed_at ON task_execution_log(completed_at);

-- Recovery Queue (for failed operations)
CREATE TABLE recovery_queue (
    recovery_id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP,
    last_error TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES task_execution_log(task_id)
);
CREATE INDEX idx_next_retry ON recovery_queue(next_retry_at);

-- Deterministic Replay Log
CREATE TABLE replay_log (
    replay_id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    sequence_number INTEGER,
    operation TEXT NOT NULL,             -- JSON-encoded operation
    state_before TEXT,                   -- JSON
    state_after TEXT,                    -- JSON
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_task_replay ON replay_log(task_id, sequence_number);
```

### 1.3 SQLite Integration Points

**Per-Agent SQLite Database:**
```
/var/coditect/
├── agent-id-1/
│   └── local.db (SQLite)
├── agent-id-2/
│   └── local.db (SQLite)
└── agent-id-N/
    └── local.db (SQLite)
```

**Synchronization Pattern:**

```
Agent starts
  ↓
Load SQLite recovery_queue
  ↓
Sync with Redis (priority: in-flight tasks first)
  ↓
Fill world_model_cache from Redis
  ↓
Resume from recovery_queue
  ↓
Execute tasks
  ↓
Write results to Redis + SQLite simultaneously
  ↓
On Redis sync failure: retry from SQLite
```

### 1.4 SQLite Query Examples

**Load recovery queue on startup:**
```sql
SELECT * FROM recovery_queue
WHERE next_retry_at <= CURRENT_TIMESTAMP
ORDER BY created_at ASC
LIMIT 100;
```

**Find recent task execution history:**
```sql
SELECT task_id, status, duration_ms, error_message
FROM task_execution_log
WHERE agent_id = ?
  AND completed_at > datetime('now', '-1 hour')
ORDER BY completed_at DESC;
```

**Deterministic replay for debugging:**
```sql
SELECT operation, state_before, state_after
FROM replay_log
WHERE task_id = ?
ORDER BY sequence_number ASC;
```

---

## Part 2: FoundationDB - Distributed ACID Transactions

### 2.1 Purpose & Role

**FoundationDB provides the DISTRIBUTED TRANSACTION LAYER for the multi-agent swarm:**

```
CODITECT Multi-Agent System
├── Layer 1: Orchestrator (centralized planning)
├── Layer 2: Task Queue (task distribution)
├── Layer 3: Worker Agents (autonomous execution)
│
└── Persistence Layer (needs global consistency)
    ├── Redis (fast state, 1ms latency)
    ├── FoundationDB (ACID transactions across agents)
    └── Event Streaming (NATS JetStream)
```

**Problem FoundationDB Solves:**

Without FoundationDB:
```
Agent A writes: File F now depends on Feature X
Agent B tries to write: Feature X doesn't exist yet
Result: Inconsistent state, cascading failures
```

With FoundationDB:
```
Transaction T1: (Agent A writes dependency) + (Agent B creates feature)
Either both succeed together, or both fail atomically
→ No partial state, no races, no cascading failures
```

**When to use FoundationDB:**
- ✅ Multi-agent coordinated state changes (atomic)
- ✅ Goal decomposition with dependency tracking
- ✅ Critical resource allocation decisions
- ✅ State rollback on consistency violations
- ✅ Complex agreement protocols (multiple agents)
- ✅ Failure recovery with state consistency

**When NOT to use FoundationDB:**
- ❌ Real-time high-frequency updates (latency too high)
- ❌ Time-series data (use ClickHouse)
- ❌ Full-text search (use specialized engines)
- ❌ Analytics (use ClickHouse)

### 2.2 FoundationDB Key Design

The key design is critical for sharding and locality:

```
Key Space Design:
/coditect/
├── agent/{agent_id}/config
├── agent/{agent_id}/state
├── task/{task_id}/definition
├── task/{task_id}/dependencies
├── task/{task_id}/result
├── goal/{goal_id}/subtasks
├── goal/{goal_id}/status
├── consistency/{violation_id}/investigation
└── resource/{resource_type}/{resource_id}/owner
```

**Multi-Tenant Key Design (if needed):**
```
/coditect/tenant/{tenant_id}/
├── agent/{agent_id}/config
├── task/{task_id}/definition
└── goal/{goal_id}/status
```

### 2.3 FoundationDB Schema & Operations

```python
# FoundationDB operations in pseudocode

# Operation 1: Atomic Goal Decomposition
@fdb.transactional
def decompose_goal(tr, goal_id, user_request):
    """
    Atomically:
    1. Create goal record
    2. Create subtask records
    3. Set dependencies
    4. Update status to READY

    If any step fails, entire transaction rolls back.
    No partial decompositions.
    """
    # Create goal
    goal_key = f'/coditect/goal/{goal_id}/status'
    tr[goal_key] = json.dumps({
        'status': 'DECOMPOSING',
        'created_at': time.time(),
        'user_request': user_request
    })

    # Create subtasks (multiple writes in same transaction)
    for task_idx, task_def in enumerate(subtasks):
        task_id = f'{goal_id}:task_{task_idx}'
        task_key = f'/coditect/task/{task_id}/definition'
        tr[task_key] = json.dumps(task_def)

        # Set dependencies
        dep_key = f'/coditect/task/{task_id}/dependencies'
        tr[dep_key] = json.dumps(task_def.get('depends_on', []))

    # Update goal status atomically (last write in transaction)
    tr[goal_key] = json.dumps({
        'status': 'READY',
        'subtask_count': len(subtasks),
        'decomposed_at': time.time()
    })
    # If exception thrown between goal creation and final status update,
    # entire transaction rolls back - no partial state


# Operation 2: Atomic Task Result With Consistency Violation Detection
@fdb.transactional
def report_task_result(tr, task_id, result, expected_state):
    """
    Atomically:
    1. Store task result
    2. Update world model
    3. Check consistency violation
    4. If violation: create investigation record
    """
    # Store result
    result_key = f'/coditect/task/{task_id}/result'
    tr[result_key] = json.dumps(result)

    # Update world model
    world_key = f'/coditect/world_model/snapshot'
    current_world = tr[world_key]  # Atomic read in transaction
    updated_world = apply_result(current_world, result)
    tr[world_key] = updated_world

    # Check consistency
    if updated_world != expected_state:
        # Consistency violation detected
        violation_key = f'/coditect/consistency/{uuid()}/investigation'
        tr[violation_key] = json.dumps({
            'task_id': task_id,
            'expected': expected_state,
            'actual': updated_world,
            'created_at': time.time()
        })

    # All updates succeed together, or none do


# Operation 3: Distributed Mutex (Resource Allocation)
@fdb.transactional
def allocate_resource(tr, agent_id, resource_id):
    """
    Atomically:
    1. Check if resource is available
    2. Allocate to agent
    3. Update resource owner

    No race conditions - only one agent can win.
    """
    resource_owner_key = f'/coditect/resource/{resource_id}/owner'
    current_owner = tr[resource_owner_key]

    if current_owner is None:  # Available
        tr[resource_owner_key] = agent_id
        return True
    else:
        return False  # Already allocated


# Operation 4: Complex Coordination (Multi-Agent Agreement)
@fdb.transactional
def coordinate_agents_for_feature(tr, feature_id, agent_ids):
    """
    Atomically:
    1. Lock all required agents
    2. Update feature status
    3. Create coordination record

    Either all agents agree or transaction fails.
    """
    feature_key = f'/coditect/feature/{feature_id}/status'

    # Atomic check: are all agents available?
    for agent_id in agent_ids:
        agent_lock_key = f'/coditect/agent/{agent_id}/lock'
        if tr[agent_lock_key] is not None:
            raise Exception('Agent busy, transaction aborted')

    # All available - lock them all atomically
    for agent_id in agent_ids:
        agent_lock_key = f'/coditect/agent/{agent_id}/lock'
        tr[agent_lock_key] = feature_id

    # Update feature
    tr[feature_key] = json.dumps({
        'status': 'IN_PROGRESS',
        'agents': agent_ids,
        'locked_at': time.time()
    })
```

### 2.4 FoundationDB Deployment

```yaml
# FoundationDB Cluster Configuration
# Usually 5-7 servers for HA

apiVersion: v1
kind: ConfigMap
metadata:
  name: fdb-config
data:
  cluster-file: |
    [general]
    cluster_file = /var/fdb/fdb.cluster

    [fdbserver.1]
    command = /usr/sbin/fdbserver
    datadir = /var/fdb/data
    logdir = /var/log/fdb
    public_address = fdb-1.fdb-service:4500
    listen_address = 0.0.0.0:4500

# Persistent Volumes for FoundationDB
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fdb-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 500Gi  # Adjust based on state size
```

### 2.5 Performance Characteristics

| Metric | Value | Use Case |
|--------|-------|----------|
| **Latency** | 1-10ms (txn) | Distributed coordination |
| **Throughput** | 10K-100K txn/sec | Multi-agent tasks |
| **Consistency** | ACID | Critical decisions |
| **Durability** | WAL-based | Data safety |
| **Replication** | 3-way (configurable) | HA across failures |

---

## Part 3: Integration Architecture

### 3.1 Complete Data Flow

```
USER REQUEST
  ↓
ORCHESTRATOR (Layer 1)
  │
  ├─ FoundationDB Transaction
  │  (Decompose goal, create task DAG)
  │  └─ Atomic: Goal + Tasks + Dependencies
  │
  ├─ Redis Update
  │  (World model snapshot, <1ms)
  │
  └─ NATS Event
     (Publish plan_created event)

TASK QUEUE MANAGER (Layer 2)
  │
  ├─ FoundationDB Read
  │  (Get task definition, check dependencies)
  │
  ├─ Redis Update
  │  (Queue task for agents)
  │
  └─ NATS Event
     (Publish task_queued event)

WORKER AGENTS (Layer 3)
  │
  ├─ SQLite Local Cache
  │  (Load world model snapshot)
  │
  ├─ Execute Task
  │  (In sandbox: WASM or Docker)
  │
  ├─ SQLite Log
  │  (Write execution log, recovery queue)
  │
  ├─ Redis Update
  │  (Report result, <1ms sync)
  │
  ├─ FoundationDB Transaction
  │  (Atomic: task_result + world_model_update + consistency check)
  │
  └─ NATS Event
     (Publish task_completed event)

CONSISTENCY DETECTOR (Layer 2)
  │
  ├─ NATS Event (from agent)
  │  (Receive task_result event)
  │
  ├─ Compare
  │  (Expected vs Actual state)
  │
  ├─ FoundationDB Transaction
  │  (Create investigation record if violation)
  │
  └─ NATS Event
     (Publish violation_detected if needed)

ANALYTICS & LEARNING
  │
  ├─ ClickHouse
  │  (Store all events for analysis)
  │
  ├─ ChromaDB
  │  (Embed patterns, semantic search)
  │
  └─ Neo4j
     (Build knowledge graph)
```

### 3.2 Technology Stack Responsibilities

| Technology | Layer | Responsibility | Latency | Persistence |
|-----------|-------|-----------------|---------|-------------|
| **Redis** | State | Fast state queries, locks | <1ms | Optional |
| **FoundationDB** | Coordination | Atomic transactions | 1-10ms | Yes (ACID) |
| **SQLite** | Agent Local | Persistent cache, recovery | <10ms | Yes (local) |
| **NATS JetStream** | Events | Event streaming, replay | <10ms | Yes (7 days) |
| **ClickHouse** | Analytics | Historical data, analytics | <100ms | Yes (cold) |
| **Neo4j** | Knowledge | Relationship graph | <100ms | Yes |
| **ChromaDB** | Semantic | Vector embeddings | <50ms | Yes |

### 3.3 Consistency Model

**CODITECT uses a hybrid consistency model:**

```
Tier 1: ACID Consistency (FoundationDB)
├─ Goal decomposition (must be atomic)
├─ Critical resource allocation
├─ Multi-agent agreement protocols
└─ State rollback on violations

Tier 2: Eventual Consistency (Redis → FoundationDB)
├─ Fast writes to Redis
├─ Async persistence to FoundationDB
├─ Agents read from Redis (fast)
└─ NATS ensures ordering

Tier 3: Analytical Consistency (ClickHouse)
├─ All events replayed
├─ Corrected state computed
└─ Violations detected retrospectively
```

---

## Part 4: Implementation Roadmap

### Phase 1 (Weeks 1-2): Foundation
- [ ] SQLite schema design and migration scripts
- [ ] FoundationDB cluster setup (3-5 nodes)
- [ ] Integration with Layer 1 (Orchestrator)
- [ ] Unit tests for ACID operations

### Phase 2 (Weeks 3-4): Integration
- [ ] SQLite sync with Redis (bi-directional)
- [ ] FoundationDB integration with Layer 2 (Task Queue)
- [ ] Recovery queue implementation
- [ ] Replay log for debugging

### Phase 3 (Weeks 5-6): Resilience
- [ ] Failure recovery from SQLite
- [ ] Consistency violation detection via FoundationDB
- [ ] Transaction rollback handling
- [ ] Multi-agent coordination tests

### Phase 4 (Weeks 7-8): Optimization
- [ ] FoundationDB tuning (latency optimization)
- [ ] SQLite batch operations
- [ ] Analytics and monitoring
- [ ] Load testing (50+ agents)

---

## Part 5: Migration Strategy (Existing Systems)

If migrating from existing systems:

### From Single Database to Hybrid
```
Before:
  PostgreSQL (everything)

After:
  PostgreSQL → Redis (fast queries)
                ├── FoundationDB (ACID txns)
                └── SQLite (local cache)

Timeline: 4 weeks
1. Run in parallel (dual-write)
2. Migrate 10% of traffic
3. Monitor metrics
4. Increase to 100%
5. Switch off old system
```

### From No Database to Full Stack
```
Add in order:
1. SQLite (quick, local)
2. Redis (coordinator)
3. FoundationDB (critical paths)
4. ClickHouse (analytics)
```

---

## Part 6: The Syncer - Edge-to-Cloud Synchronization

### 6.1 The Store-and-Forward Pattern

The **FoundationDBSyncer** is the critical component that bridges local SQLite (edge) with cloud FoundationDB (hub):

```
Edge (User's Machine)           Cloud (Hub)
┌──────────────────────┐        ┌─────────────────┐
│  SQLite Local DB     │        │  FoundationDB   │
│  (Always Available)  │        │  (Source Truth) │
│  ↓                   │        │                 │
│  pending_events      │────→   │  Global History │
│  (Outbox Table)      │        │  with Timestamps│
│                      │        │                 │
│ ← Syncer Heartbeat ← │        │                 │
│ (every 2 seconds)    │        │                 │
└──────────────────────┘        └─────────────────┘
```

**The Atomic Swap:**
1. **Read**: Grab 50 events from SQLite
2. **Push**: Write them to FDB in a single ACID transaction
3. **Ack**: Only after FDB confirms, delete from SQLite
4. **Zero Data Loss**: If power fails at step 2, data stays in SQLite and retries

### 6.2 Syncer Implementation

```python
import sqlite3
import fdb
import fdb.tuple
import time
import logging
import struct
from typing import List, Tuple

# Initialize FDB API
fdb.api_version(710)

# Configuration
LOCAL_DB_PATH = "context.db"
BATCH_SIZE = 50
SYNC_INTERVAL = 2.0 # Seconds

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] SYNC: %(message)s')
logger = logging.getLogger("syncer")

class FoundationDBSyncer:
    def __init__(self, cluster_file: str = None):
        # 1. Connect to Cloud (The Hub)
        try:
            self.fdb_db = fdb.open(cluster_file)
            # Open the Directory Layer for Multi-Tenancy
            self.root_dir = fdb.directory.create_or_open(self.fdb_db, ('coditect_saas',))
            logger.info("✅ Connected to FoundationDB Cloud Cluster.")
        except Exception as e:
            logger.critical(f"❌ Failed to connect to FDB: {e}")
            raise e

        # 2. Connect to Edge (The Spoke)
        self.local_conn = sqlite3.connect(LOCAL_DB_PATH, check_same_thread=False)
        self.local_conn.row_factory = sqlite3.Row
        self.ensure_local_schema()

    def ensure_local_schema(self):
        """Ensure the local SQLite 'Outbox' exists."""
        self.local_conn.execute("""
            CREATE TABLE IF NOT EXISTS pending_events (
                id TEXT PRIMARY KEY,
                tenant_id TEXT,
                project_id TEXT,
                payload BLOB,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        self.local_conn.commit()

    def get_pending_batch(self, limit: int) -> List[sqlite3.Row]:
        """Fetch the oldest events that haven't been synced yet."""
        cursor = self.local_conn.cursor()
        cursor.execute(
            "SELECT * FROM pending_events ORDER BY created_at ASC LIMIT ?",
            (limit,)
        )
        return cursor.fetchall()

    def push_batch_to_cloud(self, batch: List[sqlite3.Row]):
        """
        The Critical Phase: Writes to FDB using Versionstamps.
        Versionstamps give us a perfect global ordering of events.
        """
        try:
            @fdb.transactional
            def execute_sync_tx(tr):
                for row in batch:
                    # A. Resolve the Directory (Tenant → Project)
                    tenant_dir = self.root_dir.create_or_open(tr, (row['tenant_id'],))
                    project_subspace = tenant_dir.create_or_open(tr, (row['project_id'],))

                    # B. Construct the Key with Versionstamp
                    # \x00 * 10 is a placeholder that FDB replaces with the global commit version
                    key = project_subspace.pack_with_versionstamp(
                        ('history', fdb.Versionstamp(), row['id'])
                    )

                    # C. Set the Value (The Protobuf Blob)
                    tr[key] = row['payload']

            # Execute the transaction atomically
            execute_sync_tx(self.fdb_db)
            return True

        except fdb.FDBError as e:
            logger.warning(f"⚠️ Sync failed (Network/Conflict): {e}")
            return False

    def clear_local_batch(self, batch_ids: List[str]):
        """Delete from SQLite only after Cloud Confirmation."""
        if not batch_ids:
            return

        placeholders = ','.join('?' for _ in batch_ids)
        with self.local_conn:
            self.local_conn.execute(
                f"DELETE FROM pending_events WHERE id IN ({placeholders})",
                batch_ids
            )
        logger.info(f"🗑️ Cleared {len(batch_ids)} events from local outbox.")

    def run(self):
        """The Main Loop - Runs as a systemd service."""
        logger.info("🚀 Syncer Service Started (Background).")
        while True:
            try:
                # 1. Check Local Queue
                batch = self.get_pending_batch(BATCH_SIZE)

                if not batch:
                    time.sleep(SYNC_INTERVAL)
                    continue

                logger.info(f"📦 Found {len(batch)} pending events. Syncing...")

                # 2. Push to Cloud
                success = self.push_batch_to_cloud(batch)

                # 3. Cleanup
                if success:
                    batch_ids = [row['id'] for row in batch]
                    self.clear_local_batch(batch_ids)
                    logger.info("✅ Sync Complete.")
                else:
                    time.sleep(5.0)  # Backoff on failure

            except KeyboardInterrupt:
                logger.info("🛑 Stopping Syncer...")
                break
            except Exception as e:
                logger.error(f"Unexpected error in loop: {e}")
                time.sleep(5.0)

if __name__ == "__main__":
    syncer = FoundationDBSyncer()
    syncer.run()
```

### 6.3 Why This is a Competitive Advantage

**`pack_with_versionstamp()`** - The Magic Line:
- FoundationDB automatically assigns a **monotonic global timestamp** to every transaction
- This creates a perfect timeline of events across all users, all devices
- Enables "Time Travel" debugging - replay any user's session from any point
- Impossible to fake or manipulate timestamps

**Offline-First Enterprise Wedge:**
- Defense contractors and finance firms can't send code to cloud
- With SQLite, agents run locally on secure laptops
- Sync to cloud when network available
- **CODITECT can market**: "Security. Privacy. Autonomy. On your laptop."

**Real-time Collaboration:**
- Multiple users' agents coordinating simultaneously
- All state changes atomically committed to FDB
- Similar to Google Docs but for AI swarms
- Competitors cobble together Postgres + Redis - will hit scaling walls

---

## References

- FoundationDB: https://www.foundationdb.org/
- FoundationDB Python API: https://apple.github.io/foundationdb/python/
- SQLite: https://www.sqlite.org/
- Redis: https://redis.io/
- ClickHouse: https://clickhouse.com/
- Original Research: docs/original-research/CHUNKS/chunk-012.txt (FoundationDBSyncer implementation)
