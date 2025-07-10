# OpenHands Critical Workflows and System Prompts Analysis

## Executive Summary

OpenHands employs a sophisticated system of workflows and prompts that enable AI agents to perform complex software development tasks. The platform uses microagents, specialized prompts, and structured workflows to guide agent behavior across diverse scenarios including code review, GitHub/GitLab integration, testing, and issue resolution.

---

## 1. Core Workflow Architecture

### Agent Execution Loop
```
User Input → Controller → Agent Selection → Action Generation → Runtime Execution → Observation → Memory Update → Repeat
```

### Workflow Components
- **Microagents**: Domain-specific knowledge and behavior templates
- **System Prompts**: Core agent behavior instructions
- **Message Formatting**: Structured communication with LLMs
- **Memory Management**: Context and conversation history handling
- **Action-Observation Loop**: Iterative task execution pattern

---

## 2. Microagent System and Prompt Architecture

### Microagent Types

#### Knowledge-Based Microagents
- **Trigger System**: Keyword-activated domain expertise
- **YAML Frontmatter**: Structured metadata and configuration
- **Version Control**: Versioned microagent capabilities
- **Agent Targeting**: Specific agent compatibility

#### Repository-Specific Microagents
- **Location**: `.openhands/microagents/repo.md`
- **Auto-Loading**: Automatically activated for repositories
- **Team Guidelines**: Project-specific conventions and practices

### Core Microagents Analysis

#### 1. GitHub Integration (`github.md`)
```yaml
---
name: github
type: knowledge
version: 1.0.0
agent: CodeActAgent
triggers:
- github
- git
---
```

**Key Instructions:**
- Use GitHub API over web browser
- Always use `create_pr` tool for pull requests
- Never push to main/master branches
- Handle authentication with `GITHUB_TOKEN`
- Automated branch creation and PR workflows

#### 2. GitLab Integration (`gitlab.md`)
```yaml
---
name: gitlab
type: knowledge
version: 1.0.0
agent: CodeActAgent
triggers:
- gitlab
- git
---
```

**Key Instructions:**
- Use GitLab API for operations
- Always use `create_mr` tool for merge requests
- OAuth2 token authentication pattern
- Similar branch protection as GitHub

#### 3. Code Review Microagent (`code-review.md`)
**Persona:** Expert software engineer and code reviewer

**Review Categories:**
1. **Style and Formatting**
   - Inconsistent indentation/spacing
   - Unused imports/variables
   - Naming convention violations
   - Documentation standards

2. **Clarity and Readability**
   - Complex nested logic
   - Single responsibility violations
   - Poor naming conventions
   - Missing documentation

3. **Security and Bug Patterns**
   - Unsanitized user input
   - Hardcoded credentials
   - Cryptographic misuse
   - Common vulnerabilities

**Output Format:**
```
[Line 42] :hammer_and_wrench: Issue description and solution
[Lines 78–85] :mag: Readability issue and recommendation
[Line 102] :closed_lock_with_key: Security risk and mitigation
```

---

## 3. System Message Formats and LLM Integration

### Message Architecture
```python
class Message(BaseModel):
    role: Literal['user', 'system', 'assistant', 'tool']
    content: list[TextContent | ImageContent]
    cache_enabled: bool = False
    vision_enabled: bool = False
    condensable: bool = True
    function_calling_enabled: bool = False
    tool_calls: list[ChatCompletionMessageToolCall] | None = None
```

### Serialization Strategy
- **String Serializer**: Simple text content for basic interactions
- **List Serializer**: Rich content for vision and function calling
- **litellm Compatibility**: Dictionary-based compatibility layer

### Content Types
- **TextContent**: Plain text instructions and responses
- **ImageContent**: Visual content for multi-modal interactions
- **Tool Calls**: Structured function calling capabilities

---

## 4. Critical Workflow Patterns

### 1. Issue Resolution Workflow

#### GitHub/GitLab Issue Resolution Process:
1. **Issue Analysis**: Parse issue description and context
2. **Repository Setup**: Clone and configure development environment
3. **Code Investigation**: Analyze existing codebase
4. **Solution Development**: Implement fixes iteratively
5. **Testing**: Run tests and validate changes
6. **PR Creation**: Create pull request with detailed description
7. **Review Integration**: Address feedback and comments

#### Key Commands:
```bash
# Automated issue resolution
python -m openhands.resolver.resolve_issue --selected-repo [OWNER]/[REPO] --issue-number [NUMBER]

# PR comment handling
python -m openhands.resolver.send_pull_request --issue-number PR_NUMBER --issue-type pr
```

### 2. Code Review Workflow

#### Review Process:
1. **Trigger Activation**: `/codereview` command or automatic detection
2. **Diff Analysis**: Examine code changes and context
3. **Pattern Detection**: Identify style, security, and quality issues
4. **Structured Feedback**: Generate categorized recommendations
5. **Line-Specific Comments**: Provide precise feedback locations

### 3. Git Integration Workflow

#### Branch Management:
```bash
# Standard workflow pattern
git remote -v && git branch  # Check current state
git checkout -b feature-branch  # Create new branch
git add . && git commit -m "Description"  # Stage and commit
git push -u origin feature-branch  # Push and track
```

#### Best Practices Enforcement:
- Never push directly to main/master
- Use descriptive branch names
- Create PRs/MRs for all changes
- Include comprehensive commit messages

---

## 5. Memory and Context Management

### Conversation Memory Workflow
1. **Event Streaming**: Capture all agent actions and observations
2. **History Condensation**: Summarize when context limits reached
3. **Knowledge Retrieval**: Access microagent knowledge on-demand
4. **Context Assembly**: Combine repository info, runtime state, and conversation

### Condenser Strategies
- **LLM Summarization**: AI-powered context compression
- **Recent Events**: Keep most recent interactions
- **Structured Summary**: Function-calling based summaries
- **Browser Output Masking**: Hide irrelevant browser content

---

## 6. Security and Safety Workflows

### Security Analysis Pattern
```python
class SecurityAnalyzer:
    async def on_event(self, event: Event) -> None:
        if isinstance(event, Action):
            event.security_risk = await self.security_risk(event)
            await self.act(event)
```

### Risk Assessment Areas
- **Code Injection**: Detect potential injection vulnerabilities
- **Credential Exposure**: Identify hardcoded secrets
- **Access Control**: Validate permission requirements
- **Input Validation**: Check for sanitization needs

### Safety Measures
- **Container Isolation**: Execute code in sandboxed environments
- **Permission Boundaries**: Restrict file system and network access
- **Action Validation**: Security review before execution

---

## 7. Integration Workflows

### GitHub Actions Integration
```yaml
# Workflow trigger patterns
on:
  issues:
    types: [labeled]  # 'fix-me' label
  issue_comment:
    types: [created]  # '@openhands-agent' mention
```

#### Automated Resolution Steps:
1. **Label Detection**: Monitor for 'fix-me' labels
2. **Environment Setup**: Configure tokens and API access
3. **Agent Execution**: Run OpenHands resolver
4. **Result Processing**: Create PRs or branches
5. **Feedback Provision**: Comment on issues with results

### API Integration Patterns
- **GitHub API**: Issues, PRs, comments, commits
- **GitLab API**: Merge requests, issues, project management
- **Bitbucket API**: Pull requests, repository access

---

## 8. Testing and Validation Workflows

### Integration Test Pattern
```python
class BaseIntegrationTest(ABC):
    INSTRUCTION: str
    
    @abstractmethod
    def initialize_runtime(cls, runtime: Runtime) -> None:
        """Setup test environment"""
    
    @abstractmethod
    def verify_result(cls, runtime: Runtime, histories: list[Event]) -> TestResult:
        """Validate test outcomes"""
```

### Test Categories
1. **t01_fix_simple_typo**: Basic file editing
2. **t02_add_bash_hello**: Command execution
3. **t03_jupyter_write_file**: Notebook interaction
4. **t04_git_staging**: Git workflow automation
5. **t05_simple_browsing**: Web browsing capabilities
6. **t06_github_pr_browsing**: GitHub integration
7. **t07_interactive_commands**: Interactive command handling

---

## 9. Evaluation and Benchmarking Workflows

### Benchmark Execution Pattern
```bash
# Standard evaluation command
./evaluation/benchmarks/[benchmark]/scripts/run_infer.sh [model_config] [git-version] [agent] [eval_limit]
```

### Evaluation Metadata
```python
class EvalMetadata(BaseModel):
    agent_class: str
    llm_config: LLMConfig
    max_iterations: int
    eval_output_dir: str
    dataset: str
    condenser_config: CondenserConfig
```

### Result Processing
- **JSONL Output**: Structured evaluation results
- **Metrics Tracking**: Performance and cost analysis
- **Visualization**: HuggingFace Space integration
- **Comparison**: Cross-model and cross-agent analysis

---

## 10. Error Handling and Recovery Workflows

### Retry Mechanism
```python
def _process_instance_wrapper(
    process_instance_func,
    instance,
    metadata,
    use_mp: bool,
    max_retries: int = 5
):
    for attempt in range(max_retries + 1):
        try:
            return process_instance_func(instance, metadata, use_mp)
        except Exception as e:
            if attempt == max_retries:
                raise RuntimeError(f'Maximum retries reached')
            time.sleep(5)
```

### Error Categories
- **Runtime Failures**: Container disconnection, timeouts
- **LLM Errors**: API failures, rate limiting
- **Validation Errors**: Input validation failures
- **Security Violations**: Blocked dangerous actions

---

## 11. Prompt Engineering Patterns

### System Prompt Structure
1. **Persona Definition**: Role and expertise specification
2. **Task Description**: Clear objective statement
3. **Context Provision**: Environmental and situational information
4. **Instruction Set**: Detailed behavior guidelines
5. **Output Format**: Expected response structure
6. **Constraints**: Limitations and safety boundaries

### Dynamic Prompt Assembly
```python
def get_prompt(self, state: State) -> str:
    components = [
        self.base_system_prompt,
        self.get_repository_context(),
        self.get_microagent_knowledge(),
        self.format_conversation_history(state),
        self.get_current_task_context()
    ]
    return '\n'.join(components)
```

### Microagent Integration
- **Trigger Matching**: Keyword-based activation
- **Knowledge Injection**: Domain-specific information addition
- **Behavior Modification**: Agent behavior customization
- **Tool Availability**: Specialized tool access

---

## 12. Critical System Prompts

### CodeActAgent Core Prompt Pattern
```
You are a helpful assistant that can interact with a computer to solve tasks.
<IMPORTANT>
* When asked to complete a task, you should use the tools available to you to complete the task.
* You should NEVER ask for clarification or additional information to complete a task.
* You have access to the following tools: [tool_list]
</IMPORTANT>
```

### User Response Patterns
```python
def codeact_user_response(state: State, encapsulate_solution: bool = False) -> str:
    msg = (
        'Please continue working on the task on whatever approach you think is suitable.\n'
        'When you think you have solved the question, please use the finish tool.\n'
        'IMPORTANT: YOU SHOULD NEVER ASK FOR HUMAN HELP.\n'
    )
    return msg
```

### Memory Integration
```
Current working directory: {workspace_path}
Repository Information:
{repository_context}

Microagent Knowledge:
{microagent_instructions}

Current Task:
{user_instruction}
```

---

## 13. Workflow Strengths and Capabilities

### Technical Strengths
1. **Modular Design**: Composable microagent system
2. **Rich Context**: Comprehensive environmental awareness
3. **Safety Integration**: Built-in security analysis
4. **Flexible Execution**: Multiple runtime environments
5. **Comprehensive Testing**: Multi-layer validation

### Workflow Capabilities
1. **Multi-Platform Integration**: GitHub, GitLab, Bitbucket support
2. **Automated Issue Resolution**: End-to-end problem solving
3. **Code Review Automation**: Structured feedback generation
4. **Testing Integration**: Comprehensive evaluation framework
5. **Real-time Adaptation**: Dynamic prompt and behavior adjustment

---

## 14. Areas for Improvement

### Workflow Enhancement Opportunities

#### 1. Prompt Engineering
- **Dynamic Prompt Optimization**: AI-powered prompt improvement
- **Context Relevance**: Better filtering of relevant information
- **Multi-modal Integration**: Enhanced image and audio processing
- **Personalization**: User-specific prompt adaptation

#### 2. Error Recovery
- **Intelligent Retry**: Context-aware retry strategies
- **Graceful Degradation**: Fallback behavior patterns
- **Error Learning**: Pattern recognition for common failures
- **User Guidance**: Better error explanation and guidance

#### 3. Workflow Optimization
- **Parallel Execution**: Concurrent task processing
- **Resource Management**: Better compute resource utilization
- **Cache Optimization**: Intelligent caching strategies
- **Performance Monitoring**: Real-time performance tracking

#### 4. Integration Enhancement
- **API Standardization**: Unified integration patterns
- **Webhook Support**: Real-time event processing
- **Enterprise Features**: RBAC and audit trails
- **Monitoring Integration**: Comprehensive observability

---

## 15. Security Considerations in Workflows

### Prompt Injection Prevention
- **Input Sanitization**: Clean user inputs before processing
- **Context Isolation**: Separate system and user content
- **Output Validation**: Verify generated content safety
- **Behavior Monitoring**: Track unusual agent behavior

### Credential Management
- **Environment Variables**: Secure credential storage
- **Token Rotation**: Automatic credential refresh
- **Scope Limitation**: Minimal permission principles
- **Audit Logging**: Comprehensive access tracking

### Container Security
- **Isolation Boundaries**: Strong container isolation
- **Resource Limits**: Prevent resource exhaustion
- **Network Controls**: Restricted network access
- **File System Protection**: Limited file access

---

## Conclusion

OpenHands demonstrates a sophisticated and well-architected workflow system that effectively combines AI agent capabilities with robust software development practices. The microagent system provides excellent extensibility, while the structured prompt engineering ensures consistent and reliable agent behavior.

The platform's strength lies in its comprehensive integration with modern development workflows, particularly Git-based platforms, and its ability to handle complex, multi-step software development tasks. The security-conscious design and comprehensive testing framework demonstrate enterprise-ready maturity.

Key areas for future development include enhanced prompt engineering, improved error recovery mechanisms, and expanded integration capabilities. The foundation provided by the current workflow architecture positions OpenHands well for continued evolution and enhancement.

---

*Analysis Date: 2025-07-10*
*Analysis Method: Code Review and Documentation Analysis*
*Scope: Complete workflow system including microagents, prompts, and integration patterns*
*System Maturity: HIGH - Well-architected with comprehensive capabilities*