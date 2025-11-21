# Test Design Document (TDD)
## CODITECT Multi-Agent Autonomous Development System

**Version**: 1.0
**Date**: November 21, 2025
**Status**: Ready for Implementation
**Coverage Target**: 85%+ (excluding UI)

---

## 1. TEST STRATEGY OVERVIEW

### 1.1 Test Pyramid
```
                    /\
                   /  \           E2E Tests (10%)
                  /____\
                 /      \       Integration (25%)
                /________\
               /          \  Unit Tests (65%)
              /____________\
```

### 1.2 Test Levels

**Unit Tests (65%)**: Component functionality in isolation
- Agent decision-making
- World model updates
- Consistency violation detection
- Parametrization engine

**Integration Tests (25%)**: Multi-component interaction
- Layer-to-layer communication
- Event flow through system
- Error recovery scenarios
- State synchronization

**E2E Tests (10%)**: Complete workflows
- User request → completion
- Multi-agent coordination
- Error scenarios with recovery

---

## 2. UNIT TESTS

### 2.1 Orchestrator Tests

**File**: `tests/unit/orchestrator_test.rs`

```rust
#[test]
fn test_mission_planner_simple_task() {
    let planner = MissionPlanner::new();
    let request = "Implement user authentication";

    let plan = planner.decompose(request);

    assert_eq!(plan.tasks.len(), 3);  // Analyze, Code, Test
    assert!(plan.tasks[0].task_type.contains("analyze"));
}

#[test]
fn test_mission_planner_dependency_ordering() {
    let planner = MissionPlanner::new();
    let request = "Write and test feature X";

    let plan = planner.decompose(request);

    // Test task should depend on code task
    assert!(plan.tasks[2].dependencies.contains(&plan.tasks[1].id));
}

#[test]
fn test_goal_manager_completion_detection() {
    let mut manager = GoalManager::new();
    let goal = Goal::new("Complete feature X");

    manager.track_goal(&goal);
    assert!(!manager.is_completed(&goal.id));

    // All subtasks completed
    manager.mark_subtask_complete(goal.id, task_1);
    manager.mark_subtask_complete(goal.id, task_2);

    assert!(manager.is_completed(&goal.id));
}
```

### 2.2 Task Queue Manager Tests

**File**: `tests/unit/task_queue_test.rs`

```rust
#[test]
fn test_world_model_state_update() {
    let mut world_model = WorldModel::new();

    let update = StateUpdate {
        file: "src/main.rs",
        hash: "abc123",
        timestamp: now(),
    };

    world_model.apply_update(&update);

    assert_eq!(world_model.get_file_hash("src/main.rs"), Some("abc123"));
}

#[test]
fn test_consistency_violation_detection() {
    let mut detector = ConsistencyDetector::new();

    // Expect test to pass
    detector.expect_state("test_result", "PASS");

    // Actual state is failure
    detector.report_actual("test_result", "FAIL");

    let violation = detector.check_consistency();
    assert!(violation.is_some());
    assert_eq!(violation.unwrap().violation_type, "test_expectation_mismatch");
}

#[test]
fn test_parametrization_intent_to_action() {
    let engine = ParametrizationEngine::new();

    let intent = HighLevelIntent::AnalyzeCode {
        path: "src/",
    };

    let action = engine.parametrize(&intent, &world_model);

    assert_eq!(action.tool, "find_files");
    assert_eq!(action.params["pattern"], "*.rs");
}
```

### 2.3 Agent Tests

**File**: `tests/unit/agent_test.rs`

```rust
#[test]
fn test_agent_task_execution() {
    let agent = CodeAgent::new();
    let task = Task {
        id: "task_1",
        description: "Implement login function",
        parameters: map!["language" => "rust"],
    };

    let result = agent.execute(&task);

    assert!(result.success);
    assert!(!result.code.is_empty());
}

#[test]
fn test_agent_error_reporting() {
    let agent = CodeAgent::new();
    let task = Task {
        id: "task_2",
        parameters: map!["invalid" => "true"],
    };

    let result = agent.execute(&task);

    assert!(!result.success);
    assert!(!result.error_message.is_empty());
}

#[test]
fn test_reflex_emergency_stop() {
    let mut agent = CodeAgent::new();

    agent.inject_stimulus(Stimulus::Emergency);

    // Should stop immediately
    assert!(agent.is_stopped());
    assert!(!agent.is_executing());
}
```

---

## 3. INTEGRATION TESTS

### 3.1 Layer Communication Tests

**File**: `tests/integration/layer_communication_test.rs`

```rust
#[tokio::test]
async fn test_orchestrator_to_queue_communication() {
    let orchestrator = Orchestrator::new().await;
    let queue = TaskQueueManager::new().await;

    let request = "Implement feature X";
    let plan = orchestrator.plan(request).await;

    queue.receive_plan(plan).await;

    let tasks = queue.get_pending_tasks().await;
    assert!(tasks.len() > 0);
}

#[tokio::test]
async fn test_queue_to_agent_task_assignment() {
    let queue = TaskQueueManager::new().await;
    let agent = CodeAgent::new().await;

    let task = Task {
        id: "task_1",
        assigned_agent: "coder_1",
    };

    queue.assign_task(&task).await;
    let assigned = agent.receive_task().await;

    assert_eq!(assigned.id, "task_1");
}

#[tokio::test]
async fn test_agent_to_queue_result_reporting() {
    let queue = TaskQueueManager::new().await;
    let agent = CodeAgent::new().await;

    let task = Task { id: "task_1", ... };
    let result = TaskResult {
        task_id: "task_1",
        success: true,
        output: "code generated",
    };

    agent.report_result(&result).await;
    let reported = queue.receive_result().await;

    assert_eq!(reported.task_id, "task_1");
}
```

### 3.2 Event Flow Tests

**File**: `tests/integration/event_flow_test.rs`

```rust
#[tokio::test]
async fn test_event_persistence_to_nats() {
    let mut system = System::new().await;

    // Trigger agent action
    system.execute_task("task_1").await;

    // Wait for event propagation
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Verify event in NATS
    let events = system.nats.get_events("agent.act").await;
    assert!(events.len() > 0);
    assert_eq!(events[0].task_id, "task_1");
}

#[tokio::test]
async fn test_event_archive_to_s3() {
    let mut system = System::new().await;

    // Generate 1000 events
    for i in 0..1000 {
        system.emit_event(format!("event_{}", i)).await;
    }

    // Trigger archival
    system.archive_events().await;

    // Verify in S3
    let s3_files = system.s3.list_objects("events/").await;
    assert!(s3_files.len() > 0);
}
```

### 3.3 Error Recovery Tests

**File**: `tests/integration/error_recovery_test.rs`

```rust
#[tokio::test]
async fn test_consistency_violation_detection_and_recovery() {
    let mut system = System::new().await;

    // Set expectation
    system.expect_state("test_result", "PASS");

    // Execute task that fails
    system.execute_task("failing_test").await;

    // Wait for detection
    tokio::time::sleep(Duration::from_millis(100)).await;

    // Verify violation was detected
    let violations = system.get_violations().await;
    assert!(violations.len() > 0);

    // Verify investigation triggered
    let investigation = violations[0].investigation.as_ref();
    assert!(investigation.is_some());
    assert!(!investigation.unwrap().results.is_empty());
}

#[tokio::test]
async fn test_agent_timeout_and_recovery() {
    let agent = CodeAgent::with_timeout(Duration::from_secs(5));

    let slow_task = Task {
        id: "slow_task",
        timeout: Duration::from_secs(2),
        ..Default::default()
    };

    let result = agent.execute(&slow_task).await;

    assert!(!result.success);
    assert!(result.error_message.contains("timeout"));

    // Agent should be recoverable
    let quick_task = Task {
        id: "quick_task",
        ..Default::default()
    };

    let result2 = agent.execute(&quick_task).await;
    assert!(result2.success);
}
```

---

## 4. END-TO-END TESTS

### 4.1 Complete Workflow Tests

**File**: `tests/e2e/workflow_test.rs`

```rust
#[tokio::test]
async fn test_complete_feature_implementation_workflow() {
    let mut system = System::new().await;

    // User request
    let request = "Implement user authentication";

    // Execute complete workflow
    let result = system.execute_request(request).await;

    // Verify success
    assert!(result.success);
    assert!(!result.generated_code.is_empty());
    assert!(result.tests_passing);

    // Verify traceability
    let trace = system.get_trace_by_request(request).await;
    assert!(trace.spans.len() > 10);  // Multiple operations
}

#[tokio::test]
async fn test_multi_agent_coordination() {
    let mut system = System::new().await;

    let request = "Refactor authentication module and add tests";

    // Trigger workflow
    system.execute_request(request).await;

    // Verify all agents participated
    let agents_used = system.get_agents_used().await;
    assert!(agents_used.contains("analyzer_1"));
    assert!(agents_used.contains("coder_1"));
    assert!(agents_used.contains("tester_1"));
}
```

### 4.2 Load Testing

**File**: `tests/e2e/load_test.rs`

```rust
#[tokio::test]
async fn test_system_under_load_50_agents() {
    let mut system = System::new().await;

    // Spin up 50 agents
    system.spawn_agents(50).await;

    // Send 1000 tasks
    let mut handles = vec![];
    for i in 0..1000 {
        let system_clone = system.clone();
        let handle = tokio::spawn(async move {
            system_clone.execute_task(format!("task_{}", i)).await
        });
        handles.push(handle);
    }

    // Wait for completion
    let results = futures::future::join_all(handles).await;

    // Verify success rate
    let successful = results.iter().filter(|r| r.is_ok()).count();
    assert!(successful as f32 / results.len() as f32 >= 0.99);  // 99%+

    // Verify performance
    let metrics = system.get_metrics().await;
    assert!(metrics.p99_latency < Duration::from_secs(30));
}

#[tokio::test]
async fn test_nats_throughput_1m_events_per_second() {
    let nats = NatsCluster::new().await;

    let start = Instant::now();

    // Emit 1M events
    for i in 0..1_000_000 {
        nats.publish(format!("test.event_{}", i), "payload").await;
    }

    let elapsed = start.elapsed();
    let throughput = 1_000_000.0 / elapsed.as_secs_f64();

    assert!(throughput > 1_000_000.0);  // 1M+ events/sec
}
```

---

## 5. PERFORMANCE TESTS

### 5.1 Latency Tests

```rust
#[test]
fn test_world_model_query_latency() {
    let mut world_model = WorldModel::new();

    // Add 10,000 files
    for i in 0..10_000 {
        world_model.add_file(format!("file_{}.rs", i), "hash_{}", i);
    }

    let start = Instant::now();
    let result = world_model.query("file_5000.rs");
    let elapsed = start.elapsed();

    assert!(elapsed < Duration::from_millis(10));  // <10ms
    assert!(result.is_some());
}

#[test]
fn test_consistency_violation_detection_latency() {
    let detector = ConsistencyDetector::new();

    let start = Instant::now();
    detector.check_consistency();
    let elapsed = start.elapsed();

    assert!(elapsed < Duration::from_millis(5));  // <5ms
}
```

---

## 6. TEST EXECUTION

### 6.1 Continuous Integration

**GitHub Actions**: `.github/workflows/test.yml`

```yaml
name: Tests

on: [push, pull_request]

jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: cargo test --lib --verbose
      - run: cargo test --test '*/unit_*' --verbose

  integration:
    runs-on: ubuntu-latest
    services:
      redis: { image: 'redis:latest', options: '--health-cmd "redis-cli ping"' }
      nats: { image: 'nats:latest' }
    steps:
      - uses: actions/checkout@v2
      - run: cargo test --test '*/integration_*' --verbose

  e2e:
    runs-on: ubuntu-latest
    services:
      redis: ...
      nats: ...
      clickhouse: { image: 'clickhouse/clickhouse-server:latest' }
    steps:
      - uses: actions/checkout@v2
      - run: cargo test --test '*/e2e_*' --verbose

  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: cargo tarpaulin --out Html --output-dir coverage
      - uses: codecov/codecov-action@v2
```

### 6.2 Manual Testing Checklist

- [ ] Orchestrator planning logic (manual scenarios)
- [ ] Agent sandboxing (verify isolation)
- [ ] Error recovery (inject failures, verify recovery)
- [ ] Multi-agent coordination (visual trace verification)
- [ ] Performance under sustained load (hours)

---

## 7. TEST DATA & FIXTURES

### 7.1 Mock Data

```rust
fn mock_world_model() -> WorldModel {
    WorldModel {
        files: map![
            "src/main.rs" => "abc123",
            "src/lib.rs" => "def456",
        ],
        tests: map![
            "test_main" => TestResult::Pass,
        ],
        agents: map![
            "analyzer_1" => AgentState::Ready,
        ],
    }
}

fn mock_task() -> Task {
    Task {
        id: "task_1".to_string(),
        description: "Implement login".to_string(),
        assigned_agent: "coder_1".to_string(),
        parameters: map!["language" => "rust"],
        dependencies: vec![],
    }
}
```

### 7.2 Test Scenarios

- **Happy Path**: Normal workflow without errors
- **Timeout**: Task exceeds time limit
- **Resource Exhaustion**: Out of memory/disk
- **Network Partition**: Agents can't communicate
- **Cascading Failure**: One failure triggers others
- **Recovery**: System recovers from failures

---

## 8. QUALITY GATES

| Metric | Gate | Action |
|--------|------|--------|
| Code Coverage | ≥85% | Fail if below |
| Test Pass Rate | ≥99% | Fail if below |
| Performance (p99) | <30s | Warn if exceeded |
| Load Test (50 agents) | ≥99% success | Fail if below |
| Mean Time to Recovery | <5 min | Monitor trend |

---

**Document Status**: Ready for Implementation ✅
**Next Step**: Directory Setup
