# Universal Development Environment - Complete Step-by-Step Setup Guide

**Version 2.0.0** | **Ultra-Detailed Instructions** | **Zero-Assumption Guide**

This guide assumes **ONLY** that Podman and Git are already installed. Everything else is covered in exhaustive detail.

---

## 📋 Pre-Flight Checklist

Before starting, verify these tools are available:

### ✅ Verify Podman Installation

**On ALL platforms, run:**
```bash
podman --version
```
**Expected output:** `podman version 4.x.x` or higher

**If this fails:**
- **Windows WSL2:** `sudo apt update && sudo apt install -y podman`
- **Ubuntu/Linux:** `sudo apt update && sudo apt install -y podman` 
- **macOS:** `brew install podman`

### ✅ Verify Git Installation

```bash
git --version
```
**Expected output:** `git version 2.x.x` or higher

### ✅ Platform-Specific Prerequisites

<details>
<summary><strong>🪟 Windows WSL2 Users - CRITICAL SETUP</strong></summary>

**1. Verify you're in WSL2 (not Windows PowerShell):**
```bash
uname -a
```
**Expected output should contain:** `microsoft` and `WSL2`

**2. If you see Windows paths, you're in the wrong terminal:**
```powershell
# ❌ WRONG - This is Windows PowerShell
PS C:\Users\YourName>
```

**3. Open WSL2 terminal:**
- Press `Win + R`, type `wsl`, press Enter
- OR open Windows Terminal and select Ubuntu

**4. Verify WSL2 filesystem:**
```bash
pwd
# Should show: /home/yourusername (NOT /mnt/c/...)
```

**5. Configure WSL2 for optimal performance:**
```bash
# Create/edit WSL configuration
sudo tee /etc/wsl.conf > /dev/null << 'EOF'
[automount]
root = /
options = "metadata,uid=1000,gid=1000,umask=22,fmask=11"
enabled = true

[interop]
enabled = false
appendWindowsPath = false
EOF
```

**6. Restart WSL2 (in Windows PowerShell):**
```powershell
wsl --shutdown
# Wait 10 seconds, then reopen WSL2 terminal
```
</details>

<details>
<summary><strong>🍎 macOS Users - CRITICAL SETUP</strong></summary>

**1. Verify Podman machine is running:**
```bash
podman machine list
```

**Expected output should show a running machine:**
```
NAME                     VM TYPE     CREATED      LAST UP            CPUS        MEMORY      DISK SIZE
podman-machine-default*  qemu        2 hours ago  Currently running  2           2.147GB     10.74GB
```

**2. If no machine exists or it's not running:**
```bash
# Create machine (if doesn't exist)
podman machine init --cpus 4 --memory 8192 --disk-size 50

# Start machine
podman machine start
```

**3. Test Podman functionality:**
```bash
podman run --rm hello-world
```
**Expected:** Should download and run successfully

**4. If you get permission errors:**
```bash
# Fix Podman socket permissions
podman system connection default podman-machine-default
```
</details>

<details>
<summary><strong>🐧 Ubuntu/Linux Users - CRITICAL SETUP</strong></summary>

**1. Configure rootless Podman (RECOMMENDED):**
```bash
# Set up rootless containers
podman system migrate

# Test rootless functionality
podman run --rm hello-world
```

**2. If you prefer rootful Podman:**
```bash
# Enable and start Podman socket (rootful)
sudo systemctl enable --now podman.socket
sudo systemctl enable --now podman-restart

# Test functionality
sudo podman run --rm hello-world
```

**3. For Enterprise/AWS Workspaces:**
```bash
# Check for corporate restrictions
echo $HTTP_PROXY
echo $HTTPS_PROXY

# If proxies are set, note them for later configuration
```
</details>

---

## 📁 Step 1: Download and Setup Project Files

### 1.1 Choose Your Workspace Location

<details>
<summary><strong>🪟 Windows WSL2 - Choose Location</strong></summary>

**RECOMMENDED (High Performance):**
```bash
# Use WSL2 native filesystem for best performance
cd ~
mkdir -p projects
cd projects
```

**ALTERNATIVE (Windows Integration):**
```bash
# Use Windows drive (slower but easier Windows access)
cd /mnt/c/Users/$(whoami)
mkdir -p Documents/dev-projects
cd Documents/dev-projects
```

**⚠️ IMPORTANT:** Using `/mnt/c/` is slower but allows easy file access from Windows.
</details>

<details>
<summary><strong>🍎 macOS - Choose Location</strong></summary>

```bash
# Use home directory
cd ~
mkdir -p projects
cd projects
```
</details>

<details>
<summary><strong>🐧 Ubuntu/Linux - Choose Location</strong></summary>

```bash
# Use home directory
cd ~
mkdir -p projects
cd projects
```
</details>

### 1.2 Clone or Copy Project Files

**Method A: If you have the files from Claude Code:**
```bash
# Navigate to where you saved the files
cd /path/to/your/downloaded/files

# Copy all files to your chosen location
cp -r * ~/projects/openhands-universal-dev/
cd ~/projects/openhands-universal-dev/
```

**Method B: Create files manually (if needed):**
```bash
# Create project directory
mkdir -p ~/projects/openhands-universal-dev
cd ~/projects/openhands-universal-dev

# You'll need to copy the files provided by Claude Code:
# - universal-dev-env.sh
# - UniversalContainerfile  
# - .universal-dev.env.template
# - config/entrypoint-universal.sh
# - test-aws-bedrock.sh
# - UNIVERSAL-DEV-README.md
```

### 1.3 Verify File Structure

```bash
# Check that you have the essential files
ls -la
```

**Expected output should include:**
```
-rwxr-xr-x  1 user user  45123 date universal-dev-env.sh
-rw-r--r--  1 user user   8456 date UniversalContainerfile
-rw-r--r--  1 user user  12345 date .universal-dev.env.template
-rwxr-xr-x  1 user user   9876 date test-aws-bedrock.sh
drwxr-xr-x  2 user user   4096 date config/
```

### 1.4 Make Scripts Executable

```bash
# Make all scripts executable
chmod +x universal-dev-env.sh
chmod +x test-aws-bedrock.sh
chmod +x config/entrypoint-universal.sh
```

---

## ⚙️ Step 2: Generate and Configure Environment

### 2.1 Generate Configuration Template

```bash
# Generate the configuration file
./universal-dev-env.sh config
```

**Expected output:**
```
[2024-XX-XX XX:XX:XX] INFO: Generating configuration template...
[2024-XX-XX XX:XX:XX] SUCCESS: Configuration template created: .universal-dev.env
[2024-XX-XX XX:XX:XX] INFO: Please edit this file with your specific settings before running the environment.
```

**Verify configuration file was created:**
```bash
ls -la .universal-dev.env
```
**Expected:** File should exist and be readable

### 2.2 Configure Based on Your Environment

Choose the configuration scenario that matches your situation:

<details>
<summary><strong>🏢 Scenario A: Personal Development (Simple Setup)</strong></summary>

**Edit the configuration file:**
```bash
# Open configuration file for editing
nano .universal-dev.env
```

**Uncomment and configure these essential settings:**
```bash
# Container Runtime (leave as default)
CONTAINER_RUNTIME=podman

# Network Configuration (leave as default unless conflicts)
HTTP_PORT=3000
JUPYTER_PORT=8888
CODE_SERVER_PORT=8080
DEBUG_PORT=5000

# AWS Configuration (REQUIRED for Bedrock)
AWS_REGION=us-east-1
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0

# Personal Git Configuration
GIT_USER_NAME="Your Full Name"
GIT_USER_EMAIL="your.email@gmail.com"

# Uncomment ONE of these AWS credential methods:

# METHOD 1: AWS Profile (RECOMMENDED)
AWS_PROFILE=default

# METHOD 2: Direct Credentials (if no profile)
#AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
#AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**Save and exit:**
- In nano: `Ctrl+X`, then `Y`, then `Enter`
- In vim: `Esc`, then `:wq`, then `Enter`
</details>

<details>
<summary><strong>🏢 Scenario B: Enterprise Environment</strong></summary>

**Edit the configuration file:**
```bash
nano .universal-dev.env
```

**Configure these enterprise-specific settings:**
```bash
# Container Runtime
CONTAINER_RUNTIME=podman

# Network Configuration
HTTP_PORT=3000
JUPYTER_PORT=8888
CODE_SERVER_PORT=8080
DEBUG_PORT=5000

# Proxy Configuration (REQUIRED for most enterprises)
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,.company.com,.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16

# Package Registries (configure with your corporate URLs)
NPM_REGISTRY=https://artifactory.company.com/artifactory/api/npm/npm-virtual/
PIP_INDEX_URL=https://artifactory.company.com/artifactory/api/pypi/pypi-virtual/simple/
MAVEN_REPOSITORY_URL=https://artifactory.company.com/artifactory/maven-virtual/

# AWS Configuration
AWS_REGION=us-east-1
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0

# Corporate Git Configuration
GIT_USER_NAME="Your Full Name"
GIT_USER_EMAIL="your.name@company.com"
GITHUB_ENTERPRISE_URL=https://github.company.com/api/v3

# AWS Credentials (use corporate method)
AWS_PROFILE=corp-bedrock-profile
```

**Save and exit**
</details>

<details>
<summary><strong>🔑 Scenario C: Direct AWS Credentials</strong></summary>

**Edit the configuration file:**
```bash
nano .universal-dev.env
```

**Configure with direct AWS credentials:**
```bash
# Container Runtime
CONTAINER_RUNTIME=podman

# Network Configuration  
HTTP_PORT=3000
JUPYTER_PORT=8888
CODE_SERVER_PORT=8080
DEBUG_PORT=5000

# AWS Configuration
AWS_REGION=us-east-1
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0

# Direct AWS Credentials
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Uncomment if using temporary credentials:
#AWS_SESSION_TOKEN=your_session_token_here

# Git Configuration
GIT_USER_NAME="Your Full Name"
GIT_USER_EMAIL="your.email@example.com"
```

**Save and exit**
</details>

---

## 🔐 Step 3: AWS Credentials Setup

Choose the method that applies to your situation:

<details>
<summary><strong>Method A: AWS CLI Profile (RECOMMENDED)</strong></summary>

**3.1 Install AWS CLI (if not already installed):**
```bash
# Check if AWS CLI is installed
aws --version

# If not installed:
# Ubuntu/WSL2:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS:
brew install awscli
```

**3.2 Configure AWS CLI:**
```bash
# Configure default profile
aws configure
```

**You'll be prompted to enter:**
```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

**3.3 Test AWS Configuration:**
```bash
# Test basic AWS access
aws sts get-caller-identity
```
**Expected output:**
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/YourUsername"
}
```

**3.4 Update configuration file:**
```bash
# Edit your .universal-dev.env file
nano .universal-dev.env

# Ensure this line is uncommented:
AWS_PROFILE=default
```
</details>

<details>
<summary><strong>Method B: Environment Variables Only</strong></summary>

**3.1 Set AWS credentials in environment:**
```bash
# Export AWS credentials (replace with your actual credentials)
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_REGION=us-east-1

# For temporary credentials, also set:
# export AWS_SESSION_TOKEN=your_session_token
```

**3.2 Test credentials:**
```bash
# Test basic AWS access
aws sts get-caller-identity
```

**3.3 Verify configuration file:**
```bash
# Edit your .universal-dev.env file
nano .universal-dev.env

# Ensure these lines are uncommented and correct:
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-east-1
```
</details>

<details>
<summary><strong>Method C: Manual Credential Files</strong></summary>

**3.1 Create AWS credentials directory:**
```bash
mkdir -p ~/.aws
```

**3.2 Create credentials file:**
```bash
# Create credentials file
cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[bedrock-profile]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
EOF
```

**3.3 Create config file:**
```bash
# Create config file
cat > ~/.aws/config << 'EOF'
[default]
region = us-east-1
output = json

[profile bedrock-profile]
region = us-east-1
output = json
EOF
```

**3.4 Set correct permissions:**
```bash
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

**3.5 Test configuration:**
```bash
aws sts get-caller-identity --profile default
```
</details>

---

## 🏢 Step 4: Enterprise Environment Setup (Optional)

**Skip this section if you're not in an enterprise environment.**

<details>
<summary><strong>4.1 Corporate Proxy Configuration</strong></summary>

**If your company uses a proxy, you MUST configure these:**

```bash
# Find your proxy settings (ask your IT department or check browser settings)
# Common locations to check:
echo $HTTP_PROXY
echo $HTTPS_PROXY

# Or check browser proxy settings:
# Windows: Internet Options > Connections > LAN Settings
# macOS: System Preferences > Network > Advanced > Proxies
```

**Update your .universal-dev.env file:**
```bash
nano .universal-dev.env

# Uncomment and configure these lines:
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,.company.com,.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16

# If proxy requires authentication:
HTTP_PROXY=http://username:password@proxy.company.com:8080
HTTPS_PROXY=http://username:password@proxy.company.com:8080
```
</details>

<details>
<summary><strong>4.2 Corporate SSL Certificates</strong></summary>

**If your company uses custom SSL certificates:**

**Method 1: Export from browser**
1. Open Chrome/Firefox
2. Go to any internal company website
3. Click the padlock icon > Certificate details
4. Export certificate as `.crt` or `.pem` file

**Method 2: Windows Certificate Store**
1. Press `Win+R`, type `certmgr.msc`
2. Navigate to "Trusted Root Certificate Authorities"
3. Right-click your company's certificate
4. Export as "Base-64 encoded X.509"

**Method 3: Ask your IT department**
- Request the corporate CA certificate bundle
- Common names: `company-ca.crt`, `root-ca.pem`

**Copy certificates to project:**
```bash
# Create certificates directory
mkdir -p certs

# Copy your corporate certificates
cp /path/to/your/certificates/*.crt certs/
cp /path/to/your/certificates/*.pem certs/

# Verify certificates were copied
ls -la certs/
```
</details>

<details>
<summary><strong>4.3 Corporate Package Repositories</strong></summary>

**If your company uses internal package repositories:**

```bash
# Edit configuration
nano .universal-dev.env

# Configure corporate repositories:
NPM_REGISTRY=https://artifactory.company.com/artifactory/api/npm/npm-virtual/
PIP_INDEX_URL=https://artifactory.company.com/artifactory/api/pypi/pypi-virtual/simple/
MAVEN_REPOSITORY_URL=https://artifactory.company.com/artifactory/maven-virtual/

# GitHub Enterprise (if applicable):
GITHUB_ENTERPRISE_URL=https://github.company.com/api/v3
```
</details>

---

## ✅ Step 5: Validation and Pre-Flight Check

### 5.1 Validate Configuration

```bash
# Run comprehensive validation
./universal-dev-env.sh validate
```

**Expected successful output:**
```
[2024-XX-XX XX:XX:XX] INFO: Validating environment setup...
[2024-XX-XX XX:XX:XX] INFO: Setting up directory structure...
[2024-XX-XX XX:XX:XX] SUCCESS: Directory structure created at: /home/user/.openhands-universal
[2024-XX-XX XX:XX:XX] INFO: Loading configuration...
[2024-XX-XX XX:XX:XX] SUCCESS: Configuration loaded successfully
[2024-XX-XX XX:XX:XX] SUCCESS: Environment validation passed
```

**If validation fails, you'll see specific error messages. Common fixes:**

<details>
<summary><strong>Fix: Container runtime not found</strong></summary>

```bash
# Error: Container runtime 'podman' not found
# Solution: Install or fix Podman

# Ubuntu/WSL2:
sudo apt update && sudo apt install -y podman

# macOS:
brew install podman
podman machine init
podman machine start

# Test:
podman --version
```
</details>

<details>
<summary><strong>Fix: AWS credentials not configured</strong></summary>

```bash
# Error: AWS credentials not configured - still contains placeholder values
# Solution: Replace placeholder values with real credentials

nano .universal-dev.env
# Change:
#AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_HERE
# To:
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
```
</details>

### 5.2 Test AWS Bedrock Connectivity

```bash
# Quick AWS test
./test-aws-bedrock.sh --quick
```

**Expected successful output:**
```
⚡ Quick AWS Bedrock Test
=========================
SUCCESS: ✅ AWS Authentication: OK
SUCCESS: ✅ Bedrock Access: OK (25 models available)
```

**If AWS test fails:**

<details>
<summary><strong>Fix: AWS Authentication Failed</strong></summary>

```bash
# Test basic AWS access
aws sts get-caller-identity

# If this fails, reconfigure AWS:
aws configure

# Or check environment variables:
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
echo $AWS_REGION
```
</details>

<details>
<summary><strong>Fix: Bedrock Access Failed</strong></summary>

```bash
# Run comprehensive Bedrock test
./test-aws-bedrock.sh

# Common issues:
# 1. Wrong region (Bedrock not available in all regions)
./test-aws-bedrock.sh --list-regions

# 2. Missing IAM permissions
# Contact your AWS administrator to add:
# - bedrock:ListFoundationModels
# - bedrock:InvokeModel

# 3. Bedrock not enabled in your account
# Go to AWS Console > Bedrock > Model access
```
</details>

---

## 🚀 Step 6: Build and Start Environment

### 6.1 Build Container Image

```bash
# Build the development environment container
./universal-dev-env.sh build
```

**This will take 5-15 minutes depending on your internet connection.**

**Expected output progression:**
```
[2024-XX-XX XX:XX:XX] INFO: Verifying Podman installation...
[2024-XX-XX XX:XX:XX] SUCCESS: Podman verification complete
[2024-XX-XX XX:XX:XX] INFO: Setting up directory structure...
[2024-XX-XX XX:XX:XX] INFO: Setting up SSL certificates...
[2024-XX-XX XX:XX:XX] INFO: Building universal development container...

STEP 1/25: FROM ubuntu:24.04 AS base
STEP 2/25: ARG HTTP_PROXY
STEP 3/25: ARG HTTPS_PROXY
...
[Container build progress]
...
STEP 25/25: LABEL maintainer="OpenHands Universal Dev Environment"
COMMIT openhands-universal-dev:latest

[2024-XX-XX XX:XX:XX] SUCCESS: Container image built successfully: openhands-universal-dev:latest
```

**If build fails, common solutions:**

<details>
<summary><strong>Fix: Network/Proxy Issues</strong></summary>

```bash
# Error: Failed to download packages
# Solution: Check proxy configuration

# Test basic connectivity:
curl -I https://registry.npmjs.org/

# If behind corporate proxy, ensure .universal-dev.env has:
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080

# Rebuild:
./universal-dev-env.sh build --rebuild
```
</details>

<details>
<summary><strong>Fix: Certificate Issues</strong></summary>

```bash
# Error: SSL certificate verification failed
# Solution: Add corporate certificates

# Copy certificates to certs/ directory:
mkdir -p certs
cp /path/to/corporate/certs/*.crt certs/

# Or temporarily disable SSL verification:
nano .universal-dev.env
# Add:
DISABLE_SSL_VERIFICATION=true

# Rebuild:
./universal-dev-env.sh build --rebuild
```
</details>

### 6.2 Start Development Environment

```bash
# Start the development environment
./universal-dev-env.sh start
```

**Expected output:**
```
[2024-XX-XX XX:XX:XX] INFO: Starting Universal Development Environment v2.0.0
[2024-XX-XX XX:XX:XX] INFO: Verifying Podman installation...
[2024-XX-XX XX:XX:XX] SUCCESS: Podman verification complete
[2024-XX-XX XX:XX:XX] INFO: Starting container with the following configuration:
[2024-XX-XX XX:XX:XX] INFO:   HTTP Server: http://localhost:3000
[2024-XX-XX XX:XX:XX] INFO:   Jupyter Lab: http://localhost:8888
[2024-XX-XX XX:XX:XX] INFO:   Code Server: http://localhost:8080
[2024-XX-XX XX:XX:XX] INFO:   Debug Port: 5000
[2024-XX-XX XX:XX:XX] INFO:   Workspace: /home/user/.openhands-universal/workspace

[Container starts and you'll see the environment initialization...]

🚀 Universal Dev Environment v2.0.0
============================================
📊 System Information:
  Platform: ubuntu
  User: developer (UID: 1000, GID: 1000)
  Home: /home/developer
  Working Directory: /workspace
  Shell: /bin/bash

🛠️  Development Tools:
  Java: 21.0.x
  Python: 3.12.x
  Node.js: v20.x.x
  NPM: 10.x.x
  Maven: 3.9.8
  Git: 2.x.x
  AWS CLI: 2.x.x

🌐 Network Configuration:
  Direct internet connection

☁️  AWS Configuration:
  Profile: default
  Region: us-east-1
  Bedrock Region: us-east-1
  Bedrock Model: anthropic.claude-3-5-sonnet-20241022-v2:0

🔗 Access URLs:
  OpenHands Web UI: http://localhost:3000
  Jupyter Lab: http://localhost:8888
  Code Server: http://localhost:8080

⚡ Quick Commands:
  jl                     - Start Jupyter Lab
  code /workspace        - Open VS Code
  git clone <repo>       - Clone repository
  aws bedrock list-foundation-models  - Test Bedrock
  dev-info               - Show detailed environment info

📁 Workspace Structure:
  /workspace/            - Your development projects
  /config/               - Configuration files
  /cache/                - Package manager caches
  /logs/                 - Application logs

SUCCESS: Environment ready for development! 🎉

developer@openhands-dev:/workspace$
```

**You should now be inside the container with a bash prompt!**

---

## 🧪 Step 7: Test Everything Works

### 7.1 Test Development Tools

**Inside the container, run these tests:**

```bash
# Test Java
java -version
# Expected: openjdk version "21.x.x"

# Test Python
python --version
# Expected: Python 3.12.x

# Test Node.js
node --version
# Expected: v20.x.x

# Test Maven
mvn --version
# Expected: Apache Maven 3.9.8

# Test Git
git --version
# Expected: git version 2.x.x

# Test AWS CLI
aws --version
# Expected: aws-cli/2.x.x
```

### 7.2 Test AWS Bedrock Integration

```bash
# Test AWS authentication
aws sts get-caller-identity
```
**Expected output:**
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012", 
    "Arn": "arn:aws:iam::123456789012:user/YourUsername"
}
```

```bash
# Test Bedrock access
aws bedrock list-foundation-models --region us-east-1 --output table
```
**Expected:** Table of available foundation models

### 7.3 Test Web Interfaces

**Open a new terminal on your host system (outside container) and test URLs:**

```bash
# Test OpenHands web interface
curl -I http://localhost:3000
# Expected: HTTP/1.1 200 OK (or connection established)

# Test Jupyter Lab
curl -I http://localhost:8888
# Expected: HTTP/1.1 200 OK (or connection established)
```

**Open in browser:**
- **OpenHands**: http://localhost:3000
- **Jupyter Lab**: http://localhost:8888
- **Code Server**: http://localhost:8080

### 7.4 Test File System

**Inside the container:**
```bash
# Test workspace access
ls -la /workspace
# Expected: Should show workspace directories

# Test file creation
echo "Hello World" > /workspace/test.txt
cat /workspace/test.txt
# Expected: Hello World

# Test permissions
whoami
# Expected: developer

id
# Expected: uid=1000(developer) gid=1000(developer)
```

---

## 🎯 Step 8: Common Development Workflows

### 8.1 Start Jupyter Lab

**Inside the container:**
```bash
# Start Jupyter Lab
jl
# OR
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root
```

**Access at:** http://localhost:8888

### 8.2 Clone and Work on a Project

```bash
# Navigate to projects directory
cd /workspace/projects

# Clone a repository
git clone https://github.com/your-username/your-repo.git
cd your-repo

# Set up Python virtual environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Set up Node.js project
npm install

# Build Java project
mvn clean compile
```

### 8.3 Test AWS Bedrock in Code

**Create a test Python script:**
```bash
# Create test script
cat > /workspace/test-bedrock.py << 'EOF'
import boto3
import json

# Initialize Bedrock client
bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')

# Test message
payload = {
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 100,
    "messages": [
        {
            "role": "user",
            "content": "Hello! Please confirm you're working by saying 'Bedrock is working properly.'"
        }
    ]
}

try:
    # Invoke model
    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-sonnet-20240229-v1:0',
        body=json.dumps(payload),
        contentType='application/json'
    )
    
    # Parse response
    response_body = json.loads(response['body'].read())
    print("Bedrock Response:", response_body['content'][0]['text'])
    
except Exception as e:
    print(f"Error: {e}")
EOF

# Run test
python /workspace/test-bedrock.py
```

**Expected output:**
```
Bedrock Response: Bedrock is working properly.
```

---

## 🔧 Step 9: Troubleshooting Common Issues

### 9.1 Container Won't Start

<details>
<summary><strong>Issue: Port conflicts</strong></summary>

**Symptoms:**
```
Error: port 3000 already in use
```

**Solution:**
```bash
# Check what's using the port
netstat -tulpn | grep :3000
# OR
lsof -i :3000

# Kill the process or use different ports
export HTTP_PORT=3001
export JUPYTER_PORT=8889
./universal-dev-env.sh start
```
</details>

<details>
<summary><strong>Issue: Podman permission errors</strong></summary>

**Symptoms:**
```
Error: cannot connect to Podman socket
```

**Solution:**
```bash
# For Linux/WSL2:
podman system migrate

# For macOS:
podman machine restart

# Check Podman status:
podman info
```
</details>

### 9.2 AWS/Bedrock Issues

<details>
<summary><strong>Issue: AWS authentication fails</strong></summary>

**Symptoms:**
```
Error: Unable to locate credentials
```

**Solution:**
```bash
# Test AWS configuration
aws configure list

# Reconfigure if needed
aws configure

# Test authentication
aws sts get-caller-identity

# Check environment variables
env | grep AWS
```
</details>

<details>
<summary><strong>Issue: Bedrock access denied</strong></summary>

**Symptoms:**
```
Error: User is not authorized to perform: bedrock:ListFoundationModels
```

**Solution:**
```bash
# Contact your AWS administrator to add these IAM permissions:
# - bedrock:ListFoundationModels
# - bedrock:InvokeModel
# - bedrock:InvokeModelWithResponseStream

# Or check if Bedrock is available in your region:
./test-aws-bedrock.sh --list-regions
```
</details>

### 9.3 Enterprise Environment Issues

<details>
<summary><strong>Issue: SSL certificate errors</strong></summary>

**Symptoms:**
```
Error: SSL certificate verification failed
```

**Solution:**
```bash
# Copy corporate certificates
mkdir -p certs
cp /path/to/corp/certs/*.crt certs/

# Rebuild container
./universal-dev-env.sh build --rebuild

# Or temporarily disable SSL verification
nano .universal-dev.env
# Add: DISABLE_SSL_VERIFICATION=true
```
</details>

<details>
<summary><strong>Issue: Proxy connection fails</strong></summary>

**Symptoms:**
```
Error: Failed to download packages
```

**Solution:**
```bash
# Check proxy configuration
echo $HTTP_PROXY
echo $HTTPS_PROXY

# Test proxy connectivity
curl -I --proxy $HTTP_PROXY https://registry.npmjs.org/

# Update .universal-dev.env with correct proxy settings
# If proxy requires authentication:
HTTP_PROXY=http://username:password@proxy.company.com:8080
```
</details>

---

## 📖 Step 10: Daily Usage Patterns

### 10.1 Starting Your Work Day

```bash
# Navigate to project directory
cd ~/projects/openhands-universal-dev

# Start development environment
./universal-dev-env.sh start

# Inside container - navigate to your project
cd /workspace/projects/your-project

# Activate virtual environment (if using Python)
source venv/bin/activate

# Start Jupyter Lab (if needed)
jl &

# Open VS Code (if needed)
code /workspace
```

### 10.2 Stopping Your Work

```bash
# Inside container - save your work
git add .
git commit -m "Work in progress"
git push

# Exit container
exit

# Container automatically stops and cleans up
```

### 10.3 Updating the Environment

```bash
# Pull updates (if you have a git repository)
git pull

# Rebuild container with updates
./universal-dev-env.sh clean --clean-images
./universal-dev-env.sh build

# Start with updated environment
./universal-dev-env.sh start
```

---

## 🎉 Congratulations!

You now have a fully functional, enterprise-ready development environment with:

✅ **Cross-platform compatibility** (Windows/WSL2, macOS, Ubuntu)  
✅ **AWS Bedrock integration** for LLM development  
✅ **Enterprise proxy and certificate support**  
✅ **Complete development toolchain** (Java, Python, Node.js, etc.)  
✅ **Web-based development interfaces** (Jupyter, VS Code)  
✅ **Comprehensive testing and validation**  

## 📞 Getting Help

If you encounter issues:

1. **Run validation:** `./universal-dev-env.sh validate`
2. **Test AWS setup:** `./test-aws-bedrock.sh --quick`
3. **Enable debug mode:** `./universal-dev-env.sh start --debug`
4. **Check logs:** Look in `~/.openhands-universal/logs/`

**Common commands for help:**
```bash
./universal-dev-env.sh help              # Show help
./universal-dev-env.sh validate          # Validate setup
./test-aws-bedrock.sh --help            # AWS Bedrock help
dev-info                                # Environment info (inside container)
```

Your development environment is ready! 🚀