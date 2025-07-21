# Universal Development Environment - Deployment Guide

**Easy deployment instructions for moving this environment to any machine**

## 📦 Package Contents

This organized package contains everything you need for a complete universal development environment:

```
openhands-universal-dev/
├── scripts/                     # Platform-specific startup scripts
│   ├── universal-dev-env.sh     # Linux/macOS/WSL2 script
│   ├── universal-dev-env.ps1    # Windows PowerShell script
│   ├── test-aws-bedrock.sh      # AWS Bedrock test (bash)
│   └── test-aws-bedrock.ps1     # AWS Bedrock test (PowerShell)
├── container/                   # Container build files
│   ├── Containerfile           # Multi-stage container definition
│   └── entrypoint.sh           # Container initialization script
├── config/                     # Configuration templates
│   ├── templates/              # Cross-platform templates
│   │   ├── .env.template       # Main configuration template
│   │   ├── .npmrc             # NPM configuration
│   │   ├── pip.conf           # Python pip configuration
│   │   ├── .gitconfig         # Git configuration template
│   │   └── .bashrc            # Shell configuration
│   └── windows/               # Windows-specific templates
│       └── .env-windows.template
├── docs/                       # Documentation
│   ├── README.md               # Main documentation
│   ├── SETUP-WINDOWS-POWERSHELL.md  # Windows PowerShell setup
│   ├── SETUP-WINDOWS-WSL2.md  # Windows WSL2 setup
│   ├── SETUP-LINUX-MACOS.md   # Linux & macOS setup
│   └── TROUBLESHOOTING.md      # Comprehensive troubleshooting
├── examples/                   # Example configurations
│   ├── enterprise/             # Corporate environment examples
│   │   └── enterprise-config.env
│   └── personal/              # Personal development examples
│       └── personal-config.env
├── certs/                      # SSL certificates directory
│   └── README.md              # Certificate management guide
└── DEPLOYMENT.md              # This file
```

---

## 🚀 Quick Deployment

### Step 1: Transfer Files

**Method A: Copy to Target Machine**
```bash
# Copy entire directory to target machine
scp -r openhands-universal-dev/ user@target-machine:~/
```

**Method B: Archive and Transfer**
```bash
# Create archive
tar -czf openhands-universal-dev.tar.gz openhands-universal-dev/

# Transfer archive
scp openhands-universal-dev.tar.gz user@target-machine:~/

# Extract on target machine
tar -xzf openhands-universal-dev.tar.gz
```

### Step 2: Choose Setup Guide Based on Target Platform

| Target Platform | Setup Guide |
|-----------------|-------------|
| **Windows PowerShell** | `docs/SETUP-WINDOWS-POWERSHELL.md` |
| **Windows WSL2** | `docs/SETUP-WINDOWS-WSL2.md` |
| **Linux/Ubuntu** | `docs/SETUP-LINUX-MACOS.md` |
| **macOS** | `docs/SETUP-LINUX-MACOS.md` |

### Step 3: Follow Platform-Specific Guide

Each setup guide provides complete step-by-step instructions for:
- Installing prerequisites
- Configuring the environment
- Setting up AWS Bedrock integration
- Building and starting the development environment

---

## 🎯 Platform-Specific Deployment

### Windows PowerShell Deployment

**Prerequisites:**
- Windows 10/11 (Build 19041+)
- Podman Desktop or Podman CLI
- PowerShell 5.1+

**Quick Start:**
```powershell
# 1. Copy files to Windows machine
# 2. Navigate to directory
cd C:\path\to\openhands-universal-dev

# 3. Generate configuration
.\scripts\universal-dev-env.ps1 config

# 4. Edit configuration
notepad .universal-dev.env

# 5. Start environment
.\scripts\universal-dev-env.ps1 start
```

### Linux/macOS Deployment

**Prerequisites:**
- Ubuntu 20.04+ / macOS 11+
- Podman or Docker
- Bash shell

**Quick Start:**
```bash
# 1. Copy files to target machine
# 2. Navigate to directory
cd ~/openhands-universal-dev

# 3. Make scripts executable
chmod +x scripts/*.sh

# 4. Generate configuration
./scripts/universal-dev-env.sh config

# 5. Edit configuration
nano .universal-dev.env

# 6. Start environment
./scripts/universal-dev-env.sh start
```

### WSL2 Deployment

**Prerequisites:**
- Windows 10/11 with WSL2
- Ubuntu or similar distribution in WSL2
- Podman installed in WSL2

**Quick Start:**
```bash
# 1. Copy files to WSL2 filesystem
# 2. Navigate to directory
cd ~/openhands-universal-dev

# 3. Configure WSL2 (see SETUP-WINDOWS-WSL2.md)
# 4. Generate configuration
./scripts/universal-dev-env.sh config

# 5. Edit configuration
nano .universal-dev.env

# 6. Start environment
./scripts/universal-dev-env.sh start
```

---

## ⚙️ Configuration Examples

### Personal Development Setup

**Use the personal example:**
```bash
# Copy personal configuration example
cp examples/personal/personal-config.env .universal-dev.env

# Edit with your details
nano .universal-dev.env
```

**Required changes:**
- Set your Git user name and email
- Configure AWS credentials or profile
- Optional: Add GitHub token for private repos

### Enterprise Environment Setup

**Use the enterprise example:**
```bash
# Copy enterprise configuration example
cp examples/enterprise/enterprise-config.env .universal-dev.env

# Edit with your corporate details
nano .universal-dev.env
```

**Required changes:**
- Configure corporate proxy settings
- Set corporate package registry URLs
- Add corporate certificates to `certs/` directory
- Configure corporate Git settings
- Set up corporate AWS profile

---

## 🔐 Security Considerations

### Credentials Management

**What to Include in Deployment:**
✅ Configuration templates  
✅ Certificate placeholders  
✅ Documentation  
✅ Scripts and container definitions  

**What NOT to Include:**
❌ Actual AWS credentials  
❌ Private keys  
❌ GitHub tokens  
❌ Corporate secrets  

### Best Practices

1. **Use Configuration Templates**: Never include actual credentials in deployed files
2. **Separate Certificates**: Add certificates after deployment on target machine
3. **Environment Variables**: Use environment variables for sensitive data
4. **AWS Profiles**: Prefer AWS CLI profiles over hardcoded credentials

---

## 🧪 Validation and Testing

### Post-Deployment Validation

**1. Validate Environment:**
```bash
# Linux/macOS/WSL2:
./scripts/universal-dev-env.sh validate

# Windows PowerShell:
.\scripts\universal-dev-env.ps1 validate
```

**2. Test AWS Bedrock:**
```bash
# Linux/macOS/WSL2:
./scripts/test-aws-bedrock.sh --quick

# Windows PowerShell:
.\scripts\test-aws-bedrock.ps1 -Quick
```

**3. Build and Test:**
```bash
# Build container
./scripts/universal-dev-env.sh build     # Linux/macOS/WSL2
.\scripts\universal-dev-env.ps1 build    # Windows PowerShell

# Start environment
./scripts/universal-dev-env.sh start     # Linux/macOS/WSL2
.\scripts\universal-dev-env.ps1 start    # Windows PowerShell
```

### Expected Results

**Successful deployment should show:**
- ✅ Environment validation passes
- ✅ AWS Bedrock authentication works
- ✅ Container builds successfully
- ✅ Web interfaces accessible (localhost:3000, localhost:8888)
- ✅ Development tools available inside container

---

## 🔧 Customization After Deployment

### Adding Corporate Certificates

**1. Obtain Certificates:**
- Export from Windows Certificate Store
- Get from IT department
- Export from browser

**2. Add to certs/ directory:**
```bash
# Copy certificates
cp /path/to/corporate/certs/*.crt certs/

# Rebuild container
./scripts/universal-dev-env.sh build --rebuild
```

### Configuring Enterprise Registries

**1. Get URLs from IT:**
- NPM registry: `https://artifactory.company.com/npm/`
- PyPI registry: `https://artifactory.company.com/pypi/simple/`
- Maven repository: `https://artifactory.company.com/maven/`

**2. Update configuration:**
```bash
# Edit .universal-dev.env
NPM_REGISTRY=https://artifactory.company.com/npm/
PIP_INDEX_URL=https://artifactory.company.com/pypi/simple/
MAVEN_REPOSITORY_URL=https://artifactory.company.com/maven/
```

### Setting Up AWS Bedrock

**1. Configure AWS CLI:**
```bash
# Install AWS CLI
# Linux: curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install
# macOS: brew install awscli
# Windows: winget install Amazon.AWSCLI

# Configure credentials
aws configure
```

**2. Test Bedrock Access:**
```bash
# Test authentication
aws sts get-caller-identity

# Test Bedrock
aws bedrock list-foundation-models --region us-east-1
```

---

## 🆘 Troubleshooting Deployment

### Common Deployment Issues

**Issue: Scripts not executable**
```bash
# Solution:
chmod +x scripts/*.sh
```

**Issue: Configuration file missing**
```bash
# Solution: Generate configuration
./scripts/universal-dev-env.sh config
```

**Issue: Podman not found**
```bash
# Solution: Install Podman
# Ubuntu: sudo apt install podman
# macOS: brew install podman
# Windows: winget install podman
```

**Issue: Certificate errors**
```bash
# Solution: Add corporate certificates
mkdir -p certs
cp /path/to/certs/*.crt certs/
```

### Platform-Specific Issues

**Windows:**
- Ensure PowerShell execution policy allows scripts
- Install Podman Desktop or Podman CLI
- Use Windows PowerShell, not Command Prompt

**macOS:**
- Install and start Podman machine
- Use Homebrew for package installation
- Check Podman machine status: `podman machine list`

**Linux:**
- Configure rootless Podman: `podman system migrate`
- Check SELinux settings if volume mounting fails
- Ensure user has proper permissions

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] Verify all files are present
- [ ] Check platform compatibility
- [ ] Ensure prerequisites are documented
- [ ] Remove any sensitive information

### During Deployment
- [ ] Copy all files to target machine
- [ ] Set correct file permissions
- [ ] Generate configuration file
- [ ] Configure platform-specific settings

### Post-Deployment
- [ ] Validate environment configuration
- [ ] Test AWS Bedrock connectivity
- [ ] Build container successfully
- [ ] Start environment and verify web access
- [ ] Test development tools inside container

### Documentation Handoff
- [ ] Provide appropriate setup guide
- [ ] Share troubleshooting documentation
- [ ] Document any custom configurations
- [ ] Provide contact information for support

---

## 🎉 Deployment Complete!

Once deployed, users will have:

✅ **Cross-platform development environment** ready to use  
✅ **AWS Bedrock integration** for LLM development  
✅ **Enterprise proxy and certificate support**  
✅ **Complete development toolchain** (Java, Python, Node.js, etc.)  
✅ **Web-based development interfaces** (Jupyter, VS Code)  
✅ **Comprehensive documentation** for troubleshooting  

**Start developing immediately with:**
- OpenHands Web UI: http://localhost:3000
- Jupyter Lab: http://localhost:8888
- VS Code Server: http://localhost:8080

**Happy developing!** 🚀