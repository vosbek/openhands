# Windows WSL2 Setup Guide

**Complete step-by-step setup for Windows users using WSL2 + Podman**

## 🚨 **IMPORTANT - WSL2 Users**

This guide is specifically for **Windows Subsystem for Linux 2 (WSL2)**.  
If you're using **Windows PowerShell directly**, use `SETUP-WINDOWS-POWERSHELL.md` instead.

---

## 📋 Prerequisites

### ✅ Required Software
- **Windows 10** (Version 2004, Build 19041) or **Windows 11**
- **WSL2** with Ubuntu 20.04+ or similar
- **Podman** (inside WSL2)
- **Git** (inside WSL2)

### ✅ Install WSL2 (if not already installed)

**In Windows PowerShell as Administrator:**
```powershell
# Install WSL2
wsl --install

# Or install specific distribution
wsl --install -d Ubuntu-22.04

# Restart computer when prompted
```

**Verify WSL2 installation:**
```powershell
wsl --list --verbose
```
Expected: Should show your Ubuntu distribution with VERSION 2

---

## 🔧 Setup WSL2 Environment

### 1. Configure WSL2 for Optimal Performance

**In WSL2 terminal:**
```bash
# Create WSL configuration file
sudo tee /etc/wsl.conf > /dev/null << 'EOF'
[automount]
root = /
options = "metadata,uid=1000,gid=1000,umask=22,fmask=11"
enabled = true

[interop]
enabled = false
appendWindowsPath = false

[network]
generateHosts = true
generateResolvConf = true
EOF
```

**In Windows, create `.wslconfig` file:**
```powershell
# Navigate to your Windows user directory
cd $env:USERPROFILE

# Create .wslconfig file
@"
[wsl2]
memory=8GB
processors=4
localhostForwarding=true
swap=2GB

[experimental]
autoMemoryReclaim=gradual
networkingMode=mirrored
dnsTunneling=true
firewall=true
autoProxy=true
"@ | Out-File -FilePath ".wslconfig" -Encoding UTF8
```

**Restart WSL2:**
```powershell
# In Windows PowerShell
wsl --shutdown
# Wait 10 seconds, then reopen WSL2 terminal
```

### 2. Install Prerequisites in WSL2

**In WSL2 terminal:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git unzip podman

# Verify installations
podman --version
git --version
```

---

## 📁 Step 1: Download Project Files

### Choose Workspace Location

**Option A: WSL2 Native Filesystem (Recommended for Performance)**
```bash
cd ~
mkdir -p projects
cd projects
```

**Option B: Windows Drive (Easier Windows Access)**
```bash
cd /mnt/c/Users/$(whoami)
mkdir -p Documents/dev-projects
cd Documents/dev-projects
```

⚠️ **Note**: Using `/mnt/c/` allows easy file access from Windows but is slower for development.

### Copy Project Files
```bash
# If you have the files from Claude Code, copy them here
# Expected location: ~/projects/openhands-universal-dev/ or similar

# Verify structure
ls -la openhands-universal-dev/
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
# OR if you have VS Code installed in Windows:
code .universal-dev.env
```

**Configure these essential settings:**

<details>
<summary><strong>Basic WSL2 Configuration</strong></summary>

```bash
# Container Runtime
CONTAINER_RUNTIME=podman

# Network Configuration (use 0.0.0.0 for Windows access)
HTTP_PORT=3000
JUPYTER_PORT=8888
CODE_SERVER_PORT=8080
DEBUG_PORT=5000
BIND_ADDRESS=0.0.0.0

# Git Configuration
GIT_USER_NAME="Your Full Name"
GIT_USER_EMAIL="your.email@company.com"
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
```
</details>

<details>
<summary><strong>Enterprise Configuration</strong></summary>

```bash
# Proxy Configuration
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,.company.com,.local

# Corporate Package Registries
NPM_REGISTRY=https://artifactory.company.com/npm/
PIP_INDEX_URL=https://artifactory.company.com/pypi/simple/
```
</details>

---

## 🔐 Step 3: AWS Setup in WSL2

### Install and Configure AWS CLI

**In WSL2:**
```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
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

---

## 🏢 Step 4: Enterprise Setup (Optional)

### 4.1 Corporate Certificates

**Copy Windows certificates to WSL2:**
```bash
# Create certificates directory
mkdir -p certs

# Copy Windows system certificates
sudo cp /mnt/c/Windows/System32/config/systemprofile/AppData/Roaming/Microsoft/Windows/Cookies/*.crt certs/ 2>/dev/null || true

# Copy certificates from Windows certificate store (if exported)
cp /mnt/c/path/to/exported/certificates/*.crt certs/

# Copy Linux system certificates
sudo cp /etc/ssl/certs/*.crt certs/ 2>/dev/null || true
```

### 4.2 SSH Keys Setup

**Copy SSH keys from Windows to WSL2:**
```bash
# If SSH keys are in Windows
cp /mnt/c/Users/$(whoami)/.ssh/* ~/.ssh/ 2>/dev/null || true

# Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub
```

---

## ✅ Step 5: WSL2-Specific Configuration

### 5.1 Configure Podman for WSL2
```bash
# Set up rootless Podman
podman system migrate

# Configure for WSL2 networking
echo 'export PODMAN_SOCKET="unix:///run/user/$(id -u)/podman/podman.sock"' >> ~/.bashrc
source ~/.bashrc
```

### 5.2 Fix File Permissions
```bash
# Fix ownership of project files
sudo chown -R $(id -u):$(id -g) ./openhands-universal-dev
chmod -R 755 ./openhands-universal-dev
```

---

## ✅ Step 6: Validation

### 6.1 Validate Configuration
```bash
./scripts/universal-dev-env.sh validate
```

**Expected output:**
```
[2024-XX-XX XX:XX:XX] INFO: Detected platform: wsl
[2024-XX-XX XX:XX:XX] SUCCESS: Environment validation passed
```

### 6.2 Test AWS Bedrock
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

## 🚀 Step 7: Build and Start

### 7.1 Build Container
```bash
./scripts/universal-dev-env.sh build
```

**This takes 5-15 minutes. Expected output:**
```
[2024-XX-XX XX:XX:XX] INFO: Building universal development container...
[2024-XX-XX XX:XX:XX] SUCCESS: Container image built successfully
```

### 7.2 Start Environment
```bash
./scripts/universal-dev-env.sh start
```

**You'll see the environment start and get a bash prompt:**
```
🚀 Universal Dev Environment v2.0.0
============================================
📊 System Information:
  Platform: wsl
  User: developer (UID: 1000, GID: 1000)

🔗 Access URLs:
  OpenHands Web UI: http://localhost:3000
  Jupyter Lab: http://localhost:8888
  Code Server: http://localhost:8080

SUCCESS: Environment ready for development! 🎉

developer@openhands-dev:/workspace$
```

---

## 🌐 Step 8: Access from Windows

### Web Interfaces

**Open in Windows browser:**
- **OpenHands**: http://localhost:3000
- **Jupyter Lab**: http://localhost:8888
- **Code Server**: http://localhost:8080

### File Access

**Windows File Explorer:**
```
# WSL2 native filesystem:
\\wsl$\Ubuntu-22.04\home\yourusername\projects\openhands-universal-dev

# Or if using Windows drive:
C:\Users\YourName\Documents\dev-projects\openhands-universal-dev
```

**VS Code Integration:**
```bash
# Install VS Code in Windows with WSL extension
# Then open project:
code .
```

---

## 🔧 WSL2-Specific Issues & Solutions

### Issue: Network connectivity from Windows
```bash
# Ensure binding to 0.0.0.0, not 127.0.0.1
export BIND_ADDRESS=0.0.0.0
./scripts/universal-dev-env.sh start
```

### Issue: File permission errors
```bash
# Fix WSL2 file permissions
sudo chown -R $(id -u):$(id -g) ~/.openhands-universal
chmod -R 755 ~/.openhands-universal
```

### Issue: Slow file access
```bash
# Use WSL2 native filesystem instead of /mnt/c/
# Move project to ~/projects/ instead of /mnt/c/Users/...
```

### Issue: Port conflicts with Windows
```powershell
# In Windows PowerShell, check for conflicts:
netstat -ano | findstr :3000

# Reset Windows NAT if needed:
Restart-Service -Name "winnat" -Force
```

### Issue: DNS resolution problems
```bash
# Fix WSL2 DNS
sudo tee /etc/resolv.conf > /dev/null << 'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Make it permanent
sudo tee -a /etc/wsl.conf > /dev/null << 'EOF'
[network]
generateResolvConf = false
EOF
```

---

## 📖 Daily Usage with WSL2

### Starting Work
```bash
# Open WSL2 terminal (Windows Terminal recommended)
cd ~/projects/openhands-universal-dev
./scripts/universal-dev-env.sh start
```

### Working with Files
```bash
# Edit files in WSL2
nano /workspace/project/file.py

# Or use VS Code from Windows
code /workspace/project/
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

---

## 🎯 Performance Optimization for WSL2

### Windows Configuration
```powershell
# In Windows PowerShell as Administrator
# Optimize WSL2 memory usage
wsl --shutdown
# Edit .wslconfig with optimal settings (already done above)
```

### WSL2 Configuration
```bash
# Add to ~/.bashrc for better performance
echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc
echo 'export BUILDAH_FORMAT=docker' >> ~/.bashrc
source ~/.bashrc
```

### File System Optimization
```bash
# Use WSL2 native filesystem for active development
# Keep only final results on Windows drives (/mnt/c/)

# Create symbolic link for easy Windows access
ln -sf ~/projects/openhands-universal-dev /mnt/c/Users/$(whoami)/openhands-dev-link
```

---

## 🆘 Getting Help

### Debug Mode
```bash
./scripts/universal-dev-env.sh start --debug
```

### WSL2 Diagnostics
```bash
# Check WSL2 status
wsl --status

# Check WSL2 version
wsl --version

# View WSL2 logs
dmesg | tail -20
```

### Reset WSL2 (if needed)
```powershell
# In Windows PowerShell as Administrator
wsl --shutdown
wsl --unregister Ubuntu-22.04
wsl --install -d Ubuntu-22.04
# Reconfigure everything
```

**For additional help, see:**
- `TROUBLESHOOTING.md` - Detailed troubleshooting
- `README.md` - General documentation

---

**Your WSL2 development environment is ready!** 🎉  
**Access from Windows browser at http://localhost:3000** 🌐