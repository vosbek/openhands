# Windows PowerShell Setup Guide

**Complete step-by-step setup for Windows users using PowerShell + Podman**

## 🚨 **IMPORTANT - Windows PowerShell Users**

This guide is specifically for **Windows PowerShell + Podman Desktop/CLI** (NOT WSL2).  
If you're using WSL2, use `SETUP-WINDOWS-WSL2.md` instead.

---

## 📋 Prerequisites

### ✅ Required Software
- **Windows 10/11** (Build 19041 or higher recommended)
- **PowerShell 5.1** or **PowerShell Core 7+**
- **Podman Desktop** or **Podman CLI**
- **Git for Windows**

### ✅ Verify Prerequisites

**1. Check Windows Version:**
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsBuildLabEx
```

**2. Check PowerShell Version:**
```powershell
$PSVersionTable.PSVersion
```
Expected: 5.1 or higher

**3. Check Podman Installation:**
```powershell
podman --version
```
Expected: `podman version 4.x.x` or higher

**4. Check Git Installation:**
```powershell
git --version
```
Expected: `git version 2.x.x` or higher

---

## 🔧 Install Missing Prerequisites

### Install Podman (if missing)

**Option A: Podman Desktop (Recommended for beginners)**
1. Download from: https://podman-desktop.io/
2. Run installer as Administrator
3. Start Podman Desktop application
4. Initialize Podman machine when prompted

**Option B: Podman CLI via Winget**
```powershell
# Run as Administrator
winget install containers.podman
```

**Option C: Podman CLI via GitHub**
1. Download from: https://github.com/containers/podman/releases
2. Extract to `C:\Program Files\Podman`
3. Add to PATH environment variable

### Install Git (if missing)
```powershell
# Via Winget (recommended)
winget install Git.Git

# Or download from: https://git-scm.com/download/win
```

### Verify Podman Setup
```powershell
# Initialize Podman machine (if needed)
podman machine init --cpus 4 --memory 8192

# Start Podman machine
podman machine start

# Test functionality
podman run --rm hello-world
```

---

## 📁 Step 1: Download Project Files

**Option A: Direct Download**
1. Download all files from your source
2. Extract to: `C:\Dev\openhands-universal-dev`

**Option B: Git Clone (if available)**
```powershell
# Navigate to your dev directory
cd C:\Dev
git clone <repository-url> openhands-universal-dev
cd openhands-universal-dev
```

**Verify File Structure:**
```powershell
Get-ChildItem -Recurse | Select-Object Name, Directory
```

Expected structure:
```
openhands-universal-dev/
├── scripts/
│   ├── universal-dev-env.ps1
│   └── test-aws-bedrock.ps1
├── container/
├── config/
├── docs/
└── examples/
```

---

## ⚙️ Step 2: Configure Environment

### 2.1 Generate Configuration
```powershell
# Navigate to project directory
cd C:\Dev\openhands-universal-dev

# Generate configuration template
.\scripts\universal-dev-env.ps1 config
```

### 2.2 Edit Configuration

**Open configuration file:**
```powershell
# Use your preferred editor
notepad .universal-dev.env
# Or
code .universal-dev.env
# Or
vim .universal-dev.env
```

**Configure these essential settings:**

<details>
<summary><strong>Basic Configuration</strong></summary>

```powershell
# Container Runtime
CONTAINER_RUNTIME=podman

# Network Configuration
HTTP_PORT=3000
JUPYTER_PORT=8888
CODE_SERVER_PORT=8080
DEBUG_PORT=5000

# Git Configuration
GIT_USER_NAME="Your Full Name"
GIT_USER_EMAIL="your.email@company.com"

# AWS Configuration (choose ONE method below)
```
</details>

<details>
<summary><strong>AWS Configuration Method 1: AWS Profile (Recommended)</strong></summary>

```powershell
# First, configure AWS CLI
aws configure

# Then set in .universal-dev.env:
AWS_PROFILE=default
AWS_REGION=us-east-1
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0
```
</details>

<details>
<summary><strong>AWS Configuration Method 2: Direct Credentials</strong></summary>

```powershell
# Set in .universal-dev.env:
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-east-1
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0
```
</details>

<details>
<summary><strong>Enterprise Configuration</strong></summary>

```powershell
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
```powershell
# Install AWS CLI
winget install Amazon.AWSCLI

# Configure AWS CLI
aws configure
```

**You'll be prompted for:**
- AWS Access Key ID: `AKIAIOSFODNN7EXAMPLE`
- AWS Secret Access Key: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
- Default region: `us-east-1`
- Default output format: `json`

**Test AWS Configuration:**
```powershell
aws sts get-caller-identity
```

### Option B: Environment Variables
```powershell
# Set environment variables
$env:AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
$env:AWS_REGION = "us-east-1"

# Test
aws sts get-caller-identity
```

---

## 🏢 Step 4: Enterprise Setup (Optional)

### 4.1 Corporate Certificates

**Export from Windows Certificate Store:**
1. Press `Win+R`, type `certmgr.msc`, press Enter
2. Navigate: `Trusted Root Certificate Authorities > Certificates`
3. Right-click your corporate certificate
4. `All Tasks > Export`
5. Choose `Base-64 encoded X.509`
6. Save to `certs\company-ca.crt`

**Or copy from IT department:**
```powershell
# Copy certificates to certs directory
New-Item -ItemType Directory -Path "certs" -Force
Copy-Item "\\company-share\certificates\*.crt" "certs\"
```

### 4.2 Proxy Configuration

**Find your proxy settings:**
1. `Windows Settings > Network & Internet > Proxy`
2. Note the proxy server and port
3. Add to `.universal-dev.env` file

---

## ✅ Step 5: Validation

### 5.1 Validate Configuration
```powershell
.\scripts\universal-dev-env.ps1 validate
```

**Expected output:**
```
[2024-XX-XX XX:XX:XX] INFO: Validating environment setup...
[2024-XX-XX XX:XX:XX] SUCCESS: Environment validation passed
```

### 5.2 Test AWS Bedrock
```powershell
.\scripts\test-aws-bedrock.ps1 -Quick
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
```powershell
.\scripts\universal-dev-env.ps1 build
```

**This takes 5-15 minutes. Expected output:**
```
[2024-XX-XX XX:XX:XX] INFO: Building universal development container...
STEP 1/25: FROM ubuntu:24.04 AS base
...
[2024-XX-XX XX:XX:XX] SUCCESS: Container image built successfully
```

### 6.2 Start Environment
```powershell
.\scripts\universal-dev-env.ps1 start
```

**You'll see the environment start and get a bash prompt inside the container:**
```
🚀 Universal Dev Environment v2.0.0
============================================
📊 System Information:
  Platform: windows
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
java -version
python --version
node --version
mvn --version
git --version
aws --version
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

**In your Windows browser:**
- **OpenHands**: http://localhost:3000
- **Jupyter Lab**: http://localhost:8888  
- **Code Server**: http://localhost:8080

---

## 🔧 Common Issues & Solutions

### Issue: Podman machine not running
```powershell
# Solution:
podman machine start
```

### Issue: Port conflicts
```powershell
# Check what's using ports
Get-NetTCPConnection -LocalPort 3000

# Use different ports
$env:HTTP_PORT = "3001"
.\scripts\universal-dev-env.ps1 start
```

### Issue: Certificate errors
```powershell
# Add corporate certificates to certs/ directory
# Or temporarily disable SSL verification:
$env:DISABLE_SSL_VERIFICATION = "true"
```

### Issue: AWS authentication fails
```powershell
# Reconfigure AWS CLI
aws configure

# Or check environment variables
echo $env:AWS_ACCESS_KEY_ID
echo $env:AWS_SECRET_ACCESS_KEY
```

---

## 📖 Daily Usage

### Starting Work
```powershell
# Navigate to project
cd C:\Dev\openhands-universal-dev

# Start environment
.\scripts\universal-dev-env.ps1 start
```

### Stopping Work
```bash
# Inside container - save work
git add .
git commit -m "Work in progress"
git push

# Exit container
exit
```

### Updating Environment
```powershell
# Rebuild with latest updates
.\scripts\universal-dev-env.ps1 clean -CleanImages
.\scripts\universal-dev-env.ps1 build
```

---

## 🎯 Windows-Specific Tips

### File Access
- **Container workspace** maps to: `C:\Users\YourName\.openhands-universal\workspace`
- **Access from Windows**: Navigate in File Explorer
- **Desktop shortcut**: Automatically created to workspace

### PowerShell Integration
```powershell
# Set up aliases for convenience
Set-Alias -Name "dev" -Value "C:\Dev\openhands-universal-dev\scripts\universal-dev-env.ps1"

# Now you can use:
dev start
dev build
dev validate
```

### Windows Defender
Add exclusions for better performance:
1. Open Windows Security
2. Virus & threat protection > Exclusions
3. Add folder exclusion: `C:\Users\YourName\.openhands-universal`

---

## 🆘 Getting Help

### Debug Mode
```powershell
.\scripts\universal-dev-env.ps1 start -Debug
```

### Check Logs
```powershell
# View logs
Get-Content "C:\Users\$env:USERNAME\.openhands-universal\logs\*.log" -Tail 50
```

### Comprehensive Bedrock Test
```powershell
.\scripts\test-aws-bedrock.ps1
```

**For additional help, see:**
- `TROUBLESHOOTING.md` - Detailed troubleshooting
- `README.md` - General documentation
- Run: `.\scripts\universal-dev-env.ps1 help`

---

**Your Windows PowerShell development environment is ready!** 🎉