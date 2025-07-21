# Universal Development Environment for OpenHands

**Version 2.0.0** - Bulletproof cross-platform containerized development environment with comprehensive enterprise support and AWS Bedrock integration.

## 🚀 Ultra-Quick Start

```bash
# 1. Generate configuration
./universal-dev-env.sh config

# 2. Edit configuration (REQUIRED)
nano .universal-dev.env

# 3. Start environment
./universal-dev-env.sh start
```

**That's it!** Your development environment is ready.

## 📋 What You Get

- **OpenHands-ready development environment** with all dependencies
- **AWS Bedrock integration** for LLM development
- **Enterprise proxy/certificate support**
- **Cross-platform compatibility** (Windows/WSL2, Ubuntu, macOS)
- **Zero-configuration networking** with smart port detection
- **Comprehensive toolchain**: Java 21, Python 3.12, Node.js 20, Maven, Git, AWS CLI

## 🎯 Key Features

### ✅ Platform Support
- **Windows WSL2**: Optimized paths, performance, and networking
- **Ubuntu/Linux**: Native support with rootless containers
- **macOS**: Podman machine integration
- **AWS Workspaces**: Enterprise environment ready

### ✅ Enterprise Ready
- **HTTP/HTTPS Proxy** support with authentication
- **Custom SSL certificates** automatic installation
- **Private package registries** (NPM, PyPI, Maven)
- **Air-gapped environments** support
- **Corporate firewall** compatibility

### ✅ AWS Bedrock Integration
- **Complete credential chain** support (profiles, keys, session tokens)
- **Multi-region** Bedrock testing and validation
- **Model availability** checking and fallbacks
- **Comprehensive testing** with `./test-aws-bedrock.sh`

### ✅ Developer Experience
- **Smart port conflict** detection and resolution
- **Auto-certificate** discovery and installation
- **SSH key** management and mounting
- **Real-time health** monitoring
- **Comprehensive logging** and debugging

## 📖 Prerequisites

### Required
- **Podman** (recommended) or Docker
- **4GB+ RAM**
- **10GB+ disk space**

### Platform-Specific Setup

<details>
<summary><strong>Windows WSL2</strong> (Click to expand)</summary>

```powershell
# Install WSL2 and Ubuntu
wsl --install

# In WSL2 terminal:
sudo apt update && sudo apt install -y podman
```

**Important**: Always run commands from within WSL2, not Windows PowerShell.
</details>

<details>
<summary><strong>Ubuntu/Linux</strong> (Click to expand)</summary>

```bash
# Install Podman
sudo apt update && sudo apt install -y podman

# Configure rootless containers (recommended)
podman system migrate
```
</details>

<details>
<summary><strong>macOS</strong> (Click to expand)</summary>

```bash
# Install Podman
brew install podman

# Initialize and start Podman machine
podman machine init --cpus 4 --memory 8192
podman machine start
```
</details>

## 🛠️ Configuration

### 1. Generate Configuration Template

```bash
./universal-dev-env.sh config
```

This creates `.universal-dev.env` with all available options.

### 2. Essential Configuration

Edit `.universal-dev.env` and configure these critical sections:

<details>
<summary><strong>AWS Bedrock Setup</strong> (Click to expand)</summary>

**Option A: AWS Profile (Recommended)**
```bash
AWS_PROFILE=your-bedrock-profile
AWS_REGION=us-east-1
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0
```

**Option B: Direct Credentials**
```bash
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_SESSION_TOKEN=your_session_token  # For temporary credentials
AWS_REGION=us-east-1
```

**Test Bedrock Access:**
```bash
./test-aws-bedrock.sh --quick
```
</details>

<details>
<summary><strong>Enterprise Environment</strong> (Click to expand)</summary>

```bash
# Proxy Configuration
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,.company.com,.local

# Custom Package Registries
NPM_REGISTRY=https://artifactory.company.com/npm/
PIP_INDEX_URL=https://artifactory.company.com/pypi/simple/
MAVEN_REPOSITORY_URL=https://artifactory.company.com/maven/

# Git Configuration
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@company.com"
GITHUB_ENTERPRISE_URL=https://github.company.com/api/v3
```

**Certificate Management:**
1. Copy your corporate certificates to `certs/` directory
2. They'll be automatically installed in the container
</details>

<details>
<summary><strong>Development Settings</strong> (Click to expand)</summary>

```bash
# Port Configuration (auto-detects conflicts)
HTTP_PORT=3000          # OpenHands web interface
JUPYTER_PORT=8888       # Jupyter Lab
CODE_SERVER_PORT=8080   # VS Code Server
DEBUG_PORT=5000         # Debug/development

# Performance Tuning
JAVA_OPTS="-Xmx4g -Xms1g -XX:+UseG1GC"
NODE_OPTIONS="--max-old-space-size=8192"
MEMORY_LIMIT=8g
CPU_LIMIT=4.0
```
</details>

## 🎮 Usage

### Basic Commands

```bash
# Start development environment
./universal-dev-env.sh start

# Build container image only
./universal-dev-env.sh build

# Start with shell access
./universal-dev-env.sh shell

# Force rebuild and start
./universal-dev-env.sh start --rebuild

# Validate configuration
./universal-dev-env.sh validate

# Generate fresh config
./universal-dev-env.sh config

# Clean up everything
./universal-dev-env.sh clean --clean-images

# Get help
./universal-dev-env.sh help
```

### AWS Bedrock Testing

```bash
# Quick connectivity test
./test-aws-bedrock.sh --quick

# Comprehensive test
./test-aws-bedrock.sh

# Test specific region/model
./test-aws-bedrock.sh --region us-west-2 --model anthropic.claude-instant-v1

# List supported regions and models
./test-aws-bedrock.sh --list-regions
./test-aws-bedrock.sh --list-models
```

## 🌐 Access URLs

Once started, access your development environment:

- **OpenHands Web UI**: http://localhost:3000
- **Jupyter Lab**: http://localhost:8888
- **VS Code Server**: http://localhost:8080
- **Debug Port**: localhost:5000

## 📁 Workspace Structure

Your development environment organizes files as follows:

```
~/.openhands-universal/          # Base directory
├── workspace/                   # Your development projects
│   ├── projects/               # Source code projects
│   ├── scripts/                # Utility scripts
│   ├── data/                   # Data files and datasets
│   └── docs/                   # Documentation
├── config/                     # Configuration files
├── cache/                      # Package manager caches
├── certs/                      # SSL certificates
├── ssh/                        # SSH keys and config
├── aws/                        # AWS credentials and config
├── logs/                       # Application logs
└── backups/                    # Workspace backups
```

## 🛠️ Development Tools

### Pre-installed Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Java | 21 (LTS) | JVM development |
| Python | 3.12 | Latest stable Python |
| Node.js | 20 (LTS) | JavaScript runtime |
| Maven | 3.9.8 | Java build tool |
| Git | Latest | Version control |
| AWS CLI | v2 | Cloud services |
| Jupyter Lab | Latest | Interactive development |
| Docker CLI | Latest | Container management |
| kubectl | Latest | Kubernetes management |
| Terraform | 1.8.5 | Infrastructure as code |

### Development Packages

**Python:**
- boto3, awscli, requests
- jupyterlab, notebook, ipykernel
- black, flake8, pytest, mypy
- pandas, numpy, matplotlib, seaborn

**Node.js:**
- typescript, ts-node, @types/node
- create-react-app, @angular/cli, @vue/cli
- eslint, prettier, nodemon, pm2

**Global Tools:**
- yarn, pnpm (package managers)
- kubectl (Kubernetes)
- terraform (Infrastructure)

## 🔧 Advanced Configuration

### Custom Certificates

For enterprise environments with custom CA certificates:

1. **Copy certificates to certs directory:**
```bash
mkdir -p certs
cp /path/to/your/certificates/*.crt certs/
cp /path/to/your/certificates/*.pem certs/
```

2. **Certificates are automatically installed** during container startup

3. **Verify installation:**
```bash
./universal-dev-env.sh shell
curl -I https://your-corporate-site.com
```

### SSH Key Management

```bash
# SSH keys are automatically copied from ~/.ssh
ls -la ~/.ssh/

# Test SSH connectivity (in container)
./universal-dev-env.sh shell
ssh -T git@github.com
```

### Environment Variables

All environment variables from `.universal-dev.env` are automatically loaded. You can also set them directly:

```bash
export AWS_PROFILE=my-profile
export HTTP_PROXY=http://proxy:8080
./universal-dev-env.sh start
```

### Custom Container Builds

To customize the container image, modify `UniversalContainerfile` and rebuild:

```bash
# Edit Containerfile
nano UniversalContainerfile

# Rebuild with changes
./universal-dev-env.sh build --rebuild
```

## 🚨 Troubleshooting

### Common Issues

<details>
<summary><strong>Podman/Container Issues</strong></summary>

```bash
# Check Podman status
podman info

# Fix common issues
podman system migrate           # Reset rootless setup
podman machine restart         # macOS: restart machine
sudo systemctl restart podman  # Linux: restart service

# Clean and rebuild
./universal-dev-env.sh clean --clean-images
./universal-dev-env.sh build
```
</details>

<details>
<summary><strong>Port Conflicts</strong></summary>

The system automatically detects and resolves port conflicts. If you see warnings:

```bash
# Check what's using your ports
netstat -tulpn | grep :3000
lsof -i :3000

# Manually specify different ports
export HTTP_PORT=3001
export JUPYTER_PORT=8889
./universal-dev-env.sh start
```
</details>

<details>
<summary><strong>AWS Bedrock Issues</strong></summary>

```bash
# Test AWS configuration
aws sts get-caller-identity

# Test Bedrock access
./test-aws-bedrock.sh --quick

# Common fixes:
# 1. Check region availability
./test-aws-bedrock.sh --list-regions

# 2. Verify IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USERNAME

# 3. Check model availability
./test-aws-bedrock.sh --list-models
```
</details>

<details>
<summary><strong>Certificate Issues</strong></summary>

```bash
# Test certificate installation
./universal-dev-env.sh shell
curl -I https://registry.npmjs.org/

# Debug certificate issues
openssl s_client -connect registry.npmjs.org:443 -showcerts

# For corporate environments, export certificates:
# 1. From browser: Settings > Security > Certificates > Export
# 2. From Windows: certmgr.msc > Export as Base64
# 3. Copy to certs/ directory
```
</details>

<details>
<summary><strong>Windows WSL2 Issues</strong></summary>

```bash
# Fix WSL2 path issues
export WORKSPACE_DIR="/mnt/c/Users/YourName/Documents/projects"

# Fix permission issues
sudo chown -R $(id -u):$(id -g) ~/.openhands-universal
chmod -R 755 ~/.openhands-universal

# Restart WSL2 if needed
# In Windows PowerShell:
wsl --shutdown
wsl
```
</details>

### Validation and Debugging

```bash
# Validate entire setup
./universal-dev-env.sh validate

# Enable debug mode
./universal-dev-env.sh start --debug

# Check logs
tail -f ~/.openhands-universal/logs/*.log

# Get environment info (inside container)
./universal-dev-env.sh shell
dev-info
```

## 🔒 Security Considerations

- **No hardcoded credentials** - All sensitive data via environment variables or mounted files
- **Rootless containers** - Enhanced security with user namespaces
- **Read-only mounts** - Certificates and SSH keys mounted read-only
- **Certificate validation** - Automatic corporate CA certificate installation
- **Secure defaults** - SSL verification enabled by default

## 🚀 Performance Optimization

### Resource Allocation

```bash
# In .universal-dev.env
MEMORY_LIMIT=8g                    # Container memory limit
CPU_LIMIT=4.0                     # CPU cores
JAVA_OPTS="-Xmx4g -Xms1g"         # Java heap size
NODE_OPTIONS="--max-old-space-size=8192"  # Node.js memory
```

### Platform-Specific Optimizations

**Windows WSL2:**
- Use WSL2 native filesystem (avoid /mnt/c/ for active development)
- Configure .wslconfig for optimal performance
- Use Windows Terminal for better experience

**macOS:**
- Allocate sufficient resources to Podman machine
- Use Docker Desktop if you prefer (change CONTAINER_RUNTIME=docker)
- Consider using external volumes for large projects

**Linux:**
- Use rootless Podman for better security
- Configure systemd for auto-start if desired
- Use SSD storage for workspace directories

## 🔄 Updates and Maintenance

### Updating the Environment

```bash
# Pull latest changes (if using git)
git pull

# Rebuild with latest updates
./universal-dev-env.sh clean --clean-images
./universal-dev-env.sh build

# Update tools inside container
./universal-dev-env.sh shell
sudo apt update && sudo apt upgrade
pip install --upgrade pip boto3 awscli
npm update -g
```

### Backup and Restore

```bash
# Manual backup
tar -czf openhands-backup-$(date +%Y%m%d).tar.gz ~/.openhands-universal/workspace

# Restore from backup
tar -xzf openhands-backup-YYYYMMDD.tar.gz -C ~/

# Automated backup (configure in .universal-dev.env)
ENABLE_BACKUP=true
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test on multiple platforms
4. Submit a pull request

## 📞 Support

**Getting Help:**

1. **Check this README** for common solutions
2. **Run validation:** `./universal-dev-env.sh validate`
3. **Test AWS setup:** `./test-aws-bedrock.sh`
4. **Enable debug mode:** `./universal-dev-env.sh start --debug`

**Reporting Issues:**

Include the following information:
- Platform (Windows WSL2, Ubuntu, macOS)
- Error messages (with debug output)
- Configuration (redacted for sensitive data)
- Output of `./universal-dev-env.sh validate`

## 📄 License

This project is licensed under the MIT License.

---

**Ready to develop with OpenHands!** 🎉

Start with `./universal-dev-env.sh config` then `./universal-dev-env.sh start`