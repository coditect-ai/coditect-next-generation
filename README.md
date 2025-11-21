# CODITECT Next Generation: A Python-Based AI Agent Framework

**Status**: Active Development
**Version**: 2.0
**Last Updated**: November 21, 2025

---

## 🎯 Overview

CODITECT Next Generation is a powerful and flexible Python-based framework for building, managing, and evaluating autonomous AI agents. This framework provides the core components to create sophisticated agents that can perform complex tasks, learn from experience, and be integrated into larger systems.

This project has evolved from a high-level design concept to a practical, code-first framework. The `src` directory contains the core implementation of the agent framework.

---

## ✨ Features

*   **Flexible Agent Architecture**: A base `Agent` class that can be extended to create specialized agents for a wide range of tasks.
*   **Dynamic Agent Loading**: An `AgentLoader` that can dynamically discover and load agents from different modules.
*   **Robust Agent Evaluation**: An `AgentEvaluator` to assess the performance of agents against predefined criteria.
*   **Easy Configuration**: A simple and clear configuration system using `AgentConfig` objects.
*   **AI Assistant Integration**: Seamless integration with AI coding assistants like Claude and Gemini via the `.claude` and `.gemini` directories.
*   **Extensible and Modular**: The framework is designed to be easily extended with new agent capabilities and skills.

---

## 🚀 Getting Started

### Prerequisites

*   Python 3.8+
*   Git

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/coditect-ai/coditect-next-generation.git
    cd coditect-next-generation
    ```

2.  **Install dependencies:**
    The core dependencies for the CODITECT framework are located in the `.coditect` directory.
    ```bash
    pip install -r .coditect/requirements.txt
    ```

3.  **Set up AI Assistant Integration:**
    This framework is designed to be used with AI coding assistants. The `.coditect` directory contains a rich set of prompts, agents, and commands. To make these accessible to your AI assistant, create a symlink:

    *   **For Gemini:**
        ```bash
        ln -s .coditect .gemini
        ```
    *   **For Claude:**
        ```bash
        ln -s .coditect .claude
        ```

---

## 🤖 Agent Architecture

The core of the framework is the `Agent` base class. All specialized agents should inherit from this class and implement the `run` method.

Here is a simplified example of the base `Agent` class:

```python
from abc import ABC, abstractmethod

class Agent(ABC):
    """
    The base class for all agents.
    """
    def __init__(self, config):
        self.config = config

    @abstractmethod
    def run(self, task: str) -> str:
        """
        Runs the agent on a given task.

        Args:
            task: The task for the agent to perform.

        Returns:
            The result of the agent's work.
        """
        pass
```

---

##  usage

### Loading an Agent

The `AgentLoader` can be used to dynamically load agents from modules.

```python
from agent_loader import AgentLoader

# Create an agent loader
loader = AgentLoader(agent_dir="src/agents")

# Load a specific agent
coder_agent = loader.load_agent("coder_agent")

if coder_agent:
    print("Coder agent loaded successfully.")
```

### Running an Agent

Once an agent is loaded, you can run it on a task.

```python
task = "Write a Python function to calculate the factorial of a number."
result = coder_agent.run(task)
print(result)
```

### Evaluating an Agent

The `AgentEvaluator` can be used to assess the performance of an agent.

```python
from agent_evaluator import AgentEvaluator

# Create an evaluator
evaluator = AgentEvaluator(criteria=["correctness", "efficiency"])

# Evaluate the agent's performance on the task
evaluation = evaluator.evaluate(coder_agent, task)
print(evaluation)
```
---
## 🤝 Contributing

We welcome contributions to the CODITECT Next Generation framework! If you would like to contribute, please follow these steps:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix.
3.  Make your changes and write tests.
4.  Ensure all tests pass.
5.  Create a pull request with a clear description of your changes.

---

## 📜 License

This project is licensed under the [Your License Here].

---
© 2025 CODITECT. All rights reserved.