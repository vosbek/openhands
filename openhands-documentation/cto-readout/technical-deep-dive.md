# Technical Deep Dive for the CTO: OpenHands

## 1. Technical Summary

OpenHands is a Python-based agentic framework that orchestrates a loop of **Plan -> Execute -> Verify** to accomplish software engineering tasks. It leverages a Large Language Model (LLM) for reasoning and planning, and a sandboxed container environment for safe execution of commands and code modifications. Its open architecture is its primary strength, allowing for deep integration into our specific environment, but also requires careful security and operational considerations.

This document provides a detailed analysis of its architecture, security model, integration with AWS Bedrock, and a technical roadmap for a production-ready deployment.

---

## 2. Core Architecture & Execution Flow

The system operates on a state machine model for each task:

1.  **Initialization:** The user provides a high-level goal (e.g., "Upgrade Flask to version 3.0 in the `billing-service` repository").
2.  **Planning Phase:**
    -   The Agent Controller packages the goal, along with context from the local filesystem, into a prompt for the LLM.
    -   The LLM (our Bedrock endpoint) returns a structured plan, typically as a sequence of shell commands, file edits, or thought processes.
    -   **Insight:** The quality of this plan is *highly* dependent on the chosen Bedrock model and the quality of the prompt engineering within OpenHands. Our initial focus will be on models with strong reasoning and tool-use capabilities (e.g., Anthropic's Claude 3 Sonnet/Haiku or Cohere's Command R+).
3.  **Execution Phase (The Sandbox):**
    -   For each step in the plan, the Task Executor spins up a **sandboxed Podman container**. This is the most critical security component.
    -   The workspace (e.g., a clone of a git repository) is mounted into this container.
    -   The command is executed within the container. File I/O, shell commands, etc., happen *inside* this isolated environment.
    -   The output (stdout, stderr, exit code) is captured.
4.  **Verification & Iteration:**
    -   The captured output is sent back to the LLM as new context.
    -   The LLM then decides on the next step: continue with the plan, modify the plan based on an error, or declare the task complete.
    -   This loop continues until the goal is achieved or a failure state is reached.

---

## 3. Security Model: A Deep Dive

The security of this system hinges entirely on the integrity of the sandbox. Here is a breakdown of the threats and our required controls:

-   **Threat: Container Escape.**
    -   **Risk:** A sophisticated command could exploit a kernel vulnerability to break out of the Podman container and gain access to the host machine, which has access to our network.
    -   **Required Controls:**
        1.  **Rootless Podman:** Run Podman in rootless mode to limit the potential damage of an escape.
        2.  **Minimal Base Image:** The `docker.all-hands.dev/all-hands-ai/runtime` image must be scanned for vulnerabilities (using a tool like Trivy or AWS ECR Scanning) and replaced with a custom, minimal, hardened image if necessary.
        3.  **Seccomp & AppArmor/SELinux:** We must define and apply strict `seccomp` and `AppArmor`/`SELinux` profiles to the sandbox containers, limiting the allowed syscalls to the absolute minimum required for software development tasks.
        4.  **Network Policies:** The sandbox container should have **NO network access by default**. Network access to specific, approved endpoints (e.g., our internal package repository, GitHub) must be explicitly granted via a proxy or firewall rules.

-   **Threat: Malicious LLM Output.**
    -   **Risk:** A compromised or poorly prompted LLM could generate a destructive command (e.g., `rm -rf /`).
    -   **Required Controls:**
        1.  **Human-in-the-Loop (Mandatory):** The platform **must not** allow for fully autonomous execution initially. A developer must approve every generated plan before it is executed.
        2.  **Command Deny-listing:** We will implement a regex-based filter to block a configurable list of dangerous commands (`rm -rf`, `chmod`, etc.) from ever being executed.

---

## 4. Integration with AWS Bedrock & VPC

Our setup will ensure maximum security and performance:

-   **VPC Endpoint for Bedrock:** To ensure that traffic to Bedrock never traverses the public internet, we will provision a **Bedrock VPC Endpoint**. The isolated machine running OpenHands will be placed in a VPC that has a route to this endpoint.
-   **IAM Roles for Service Accounts (IRSA) / EKS:** For a production deployment, we will not use static IAM user credentials. The OpenHands application will run in an EKS (or ECS) cluster, and we will assign a specific IAM role to its Kubernetes service account. The AWS SDK will automatically assume this role, eliminating the need to manage long-lived access keys.
-   **Model Selection:** The choice of model is critical. We need to balance performance, cost, and reasoning ability. We will benchmark:
    -   **Anthropic Claude 3 Sonnet/Haiku:** Excellent for complex reasoning and following instructions.
    -   **Cohere Command R+:** Optimized for retrieval-augmented generation (RAG) and tool use, which is a good fit for OpenHands' architecture.
    -   **Amazon Titan:** A more cost-effective option for simpler, more repetitive tasks.

---

## 5. Proposed Technical Roadmap & Milestones

-   **Q3: Secure Pilot Deployment**
    -   [ ] Deploy OpenHands on a single, locked-down EC2 instance within a private VPC.
    -   [ ] Implement all security controls outlined in Section 3 (Rootless Podman, Seccomp, Network Policies, Command Deny-listing).
    -   [ ] Configure integration with Bedrock via a VPC Endpoint and an initial IAM user.
    -   [ ] **Milestone:** Successfully automate the `dependency upgrade` sample project with full human-in-the-loop approval.

-   **Q4: Platform Hardening & EKS Migration**
    -   [ ] Containerize the OpenHands application itself.
    -   [ ] Deploy to a development EKS cluster.
    -   [ ] Replace IAM user credentials with IAM Roles for Service Accounts (IRSA).
    -   [ ] Develop a simple web UI for developers to submit tasks and review plans.
    -   **Milestone:** Two engineering teams can successfully use the platform for a limited set of approved tasks.

-   **2026-Q1: Internal Platform Launch**
    -   [ ] Implement robust logging, monitoring, and alerting (CloudWatch & Grafana).
    -   [ ] Implement cost-control measures (token usage limits, budgeting).
    -   [ ] Onboard additional teams and expand the library of available agentic tasks.
    -   **Milestone:** The platform is stable, secure, and available for wider internal use.