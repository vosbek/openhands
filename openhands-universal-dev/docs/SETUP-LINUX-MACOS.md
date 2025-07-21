# Linux & macOS Setup Guide

**Complete step-by-step setup for Linux and macOS users**

## 📋 Prerequisites

### ✅ Required Software
- **Linux**: Ubuntu 20.04+, CentOS 8+, or similar
- **macOS**: macOS 11+ (Big Sur or newer)
- **Podman** or Docker
- **Git**
- **Bash shell**

### ✅ Verify Prerequisites

**Check Podman/Docker:**
```bash
podman --version
# OR
docker --version
```

**Check Git:**
```bash
git --version
```

---

## 🔧 Install Missing Prerequisites

### Install Podman

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y podman
```

**CentOS/RHEL/Fedora:**
```bash
sudo dnf install -y podman
```

**macOS:**
```bash
# Install via Homebrew
brew install podman

# Initialize Podman machine
podman machine init --cpus 4 --memory 8192
podman machine start
```

### Install Git (if missing)

**Ubuntu/Debian:**
```bash
sudo apt install -y git
```

**CentOS/RHEL/Fedora:**
```bash
sudo dnf install -y git
```

**macOS:**
```bash
# Via Homebrew
brew install git

# Or install Xcode Command Line Tools
xcode-select --install
```

---

## 📁 Step 1: Download Project Files

**Navigate to your preferred directory:**
```bash
cd ~
mkdir -p projects
cd projects

# If you have the files from Claude Code:
# Copy/extract them to: ~/projects/openhands-universal-dev/

# Verify structure
ls -la openhands-universal-dev/
```

Expected structure:
```
openhands-universal-dev/
├── scripts/
│   ├── universal-dev-env.sh
│   └── test-aws-bedrock.sh
├── container/
├── config/
├── docs/
└── examples/
```

---

## ⚙️ Step 2: Configure Environment

### 2.1 Make Scripts Executable
```bash
cd openhands-universal-dev
chmod +x scripts/*.sh
```

### 2.2 Generate Configuration
```bash
./scripts/universal-dev-env.sh config
```

### 2.3 Edit Configuration
```bash
# Use your preferred editor
nano .universal-dev.env
# OR
vim .universal-dev.env
# OR
code .universal-dev.env
```

**Configure these essential settings:**

<details>
<summary><strong>Basic Configuration</strong></summary>

```bash
# Container Runtime
CONTAINER_RUNTIME=podman

# Network Configuration
HTTP_PORT=3000
JUPYTER_PORT=8888
CODE_SERVER_PORT=8080
DEBUG_PORT=5000

# Git Configuration
GIT_USER_NAME="Your Full Name"
GIT_USER_EMAIL="your.email@example.com"
```
</details>

<details>
<summary><strong>AWS Configuration</strong></summary>

**Method 1: AWS Profile (Recommended)**
```bash
AWS_PROFILE=default
AWS_REGION=us-east-1
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0
```

**Method 2: Direct Credentials**
```bash
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-east-1
AWS_BEDROCK_REGION=us-east-1
```
</details>

<details>
<summary><strong>Enterprise Configuration (if applicable)</strong></summary>

```bash
# Proxy Configuration
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,.company.com,.local

# Corporate Package Registries
NPM_REGISTRY=https://artifactory.company.com/npm/
PIP_INDEX_URL=https://artifactory.company.com/pypi/simple/
MAVEN_REPOSITORY_URL=https://artifactory.company.com/maven/

# GitHub Enterprise
GITHUB_ENTERPRISE_URL=https://github.company.com/api/v3
```
</details>

---

## 🔐 Step 3: AWS Setup

### Option A: AWS CLI Profile Setup

**Install AWS CLI:**

**Ubuntu/Debian:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**macOS:**
```bash
brew install awscli
```

**Configure AWS CLI:**
```bash
aws configure
```

Enter your credentials:
- AWS Access Key ID: `AKIAIOSFODNN7EXAMPLE`
- AWS Secret Access Key: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
- Default region: `us-east-1`
- Default output format: `json`

**Test AWS Configuration:**
```bash
aws sts get-caller-identity
```

### Option B: Environment Variables
```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_REGION=us-east-1

# Test
aws sts get-caller-identity
```

---

## 🏢 Step 4: Enterprise Setup (Optional)

### 4.1 Corporate Certificates

**Copy certificates to certs directory:**
```bash
mkdir -p certs

# Copy from system certificate store
sudo cp /etc/ssl/certs/*.crt certs/ 2>/dev/null || true
sudo cp /usr/local/share/ca-certificates/*.crt certs/ 2>/dev/null || true

# Or copy custom certificates provided by IT
cp /path/to/corporate/certificates/*.crt certs/
```

### 4.2 SSH Keys Setup
```bash
# SSH keys are automatically copied from ~/.ssh
# Ensure your SSH keys exist and have correct permissions
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub
```

---

## ✅ Step 5: Validation

### 5.1 Validate Configuration
```bash
./scripts/universal-dev-env.sh validate
```

**Expected output:**
```
[2024-XX-XX XX:XX:XX] INFO: Validating environment setup...
[2024-XX-XX XX:XX:XX] SUCCESS: Environment validation passed
```

### 5.2 Test AWS Bedrock
```bash
./scripts/test-aws-bedrock.sh --quick
```

**Expected output:**
```
⚡ Quick AWS Bedrock Test
=========================
SUCCESS: ✅ AWS Authentication: OK
SUCCESS: ✅ Bedrock Access: OK (25 models available)
```

---

## 🚀 Step 6: Build and Start

### 6.1 Build Container
```bash
./scripts/universal-dev-env.sh build
```

**This takes 5-15 minutes. Expected output:**
```
[2024-XX-XX XX:XX:XX] INFO: Building universal development container...
STEP 1/25: FROM ubuntu:24.04 AS base
...
[2024-XX-XX XX:XX:XX] SUCCESS: Container image built successfully
```

### 6.2 Start Environment
```bash
./scripts/universal-dev-env.sh start
```

**You'll see the environment start and get a bash prompt inside the container:**
```
🚀 Universal Dev Environment v2.0.0
============================================
📊 System Information:
  Platform: ubuntu (or macos)
  User: developer (UID: 1000, GID: 1000)

🔗 Access URLs:
  OpenHands Web UI: http://localhost:3000
  Jupyter Lab: http://localhost:8888
  Code Server: http://localhost:8080

SUCCESS: Environment ready for development! 🎉

developer@openhands-dev:/workspace$
```

---

## 🧪 Step 7: Test Everything

### 7.1 Test Development Tools

**Inside the container:**
```bash
# Test all tools
java -version          # Expected: openjdk 21.x.x
python --version       # Expected: Python 3.12.x
node --version         # Expected: v20.x.x
mvn --version          # Expected: Apache Maven 3.9.x
git --version          # Expected: git version 2.x.x
aws --version          # Expected: aws-cli/2.x.x
```

### 7.2 Test AWS Bedrock

**Inside the container:**
```bash
# Test AWS authentication
aws sts get-caller-identity

# Test Bedrock access
aws bedrock list-foundation-models --region us-east-1 --output table
```

### 7.3 Test Web Interfaces

**Open in your browser:**
- **OpenHands**: http://localhost:3000
- **Jupyter Lab**: http://localhost:8888
- **Code Server**: http://localhost:8080

---

## 🔧 Platform-Specific Considerations

### Linux-Specific

**Rootless vs Rootful Podman:**
```bash
# Configure rootless (recommended)
podman system migrate

# Check configuration
podman info | grep rootless
```

**SELinux (if enabled):**
```bash
# Check SELinux status
sestatus

# If issues with volume mounts:
sudo setsebool -P container_manage_cgroup on
```

### macOS-Specific

**Podman Machine Management:**
```bash
# Check machine status
podman machine list

# Start machine if stopped
podman machine start

# Restart if having issues
podman machine restart
```

**Performance Considerations:**
```bash
# Allocate more resources to Podman machine
podman machine stop
podman machine init --cpus 4 --memory 8192 --disk-size 50
podman machine start
```

---

## 🔧 Common Issues & Solutions

### Issue: Podman permission errors
```bash
# Solution for Linux:
podman system migrate

# Solution for macOS:
podman machine restart
```

### Issue: Port conflicts
```bash
# Check what's using ports
netstat -tulpn | grep :3000
# OR on macOS:
lsof -i :3000

# Use different ports
export HTTP_PORT=3001
./scripts/universal-dev-env.sh start
```

### Issue: Container build fails with network errors
```bash
# Check connectivity
curl -I https://registry.npmjs.org/

# If behind proxy, ensure proxy settings in .universal-dev.env
# If SSL issues, copy certificates to certs/ directory
```

### Issue: AWS authentication fails
```bash
# Check AWS configuration
aws configure list

# Reconfigure if needed
aws configure

# Check environment variables
env | grep AWS
```

---

## 📖 Daily Usage

### Starting Work
```bash
cd ~/projects/openhands-universal-dev
./scripts/universal-dev-env.sh start
```

### Stopping Work
```bash
# Inside container - save your work
git add .
git commit -m "Work in progress"
git push

# Exit container
exit
```

### Updating Environment
```bash
# Rebuild with latest updates
./scripts/universal-dev-env.sh clean --clean-images
./scripts/universal-dev-env.sh build
```

---

## 🎯 Advanced Usage

### Using Custom Commands
```bash
# Start with shell access
./scripts/universal-dev-env.sh shell

# Force rebuild
./scripts/universal-dev-env.sh start --rebuild

# Use custom config file
./scripts/universal-dev-env.sh start --config /path/to/custom.env
```

### Development Workflows
```bash
# Inside container - create new projects
cd /workspace/projects

# Clone a repository
git clone https://github.com/your-username/your-repo.git
cd your-repo

# Set up Python environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Set up Node.js project
npm install

# Build Java project
mvn clean compile
```

---

## 🆘 Getting Help

### Debug Mode
```bash
./scripts/universal-dev-env.sh start --debug
```

### Comprehensive AWS Test
```bash
./scripts/test-aws-bedrock.sh
```

### View Logs
```bash
# Check container logs
podman logs openhands-universal-dev

# Check application logs
tail -f ~/.openhands-universal/logs/*.log
```

### Show Help
```bash
./scripts/universal-dev-env.sh help
./scripts/test-aws-bedrock.sh --help
```

**For additional help, see:**
- `TROUBLESHOOTING.md` - Detailed troubleshooting
- `README.md` - General documentation

---

**Your Linux/macOS development environment is ready!** 🚀