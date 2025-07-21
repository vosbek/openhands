# Universal Containerized Development Environment

A cross-platform containerized development environment designed for enterprise environments with support for Java, Python, Node.js, and AWS Bedrock integration.

## 🚀 Quick Start

```bash
# Make the startup script executable
chmod +x dev-env.sh

# Start the development environment
./dev-env.sh start
```

## 📋 Prerequisites

### All Platforms
- **Podman** (required) - Container runtime
- **Internet access** (for initial setup)
- **4GB+ RAM** (recommended)
- **10GB+ free disk space**

### Platform-Specific Requirements

#### Windows with WSL2
```powershell
# Install WSL2 if not already installed
wsl --install

# Install Podman in WSL2
sudo apt update
sudo apt install -y podman
```

#### Ubuntu (Native/AWS Workspaces)
```bash
# Install Podman
sudo apt update
sudo apt install -y podman

# Configure rootless containers (recommended)
podman system migrate
```

#### macOS
```bash
# Install Podman via Homebrew
brew install podman

# Initialize Podman machine
podman machine init
podman machine start
```

## 🛠️ Configuration

### Environment Variables

Copy `.env.template` to `.env` and customize:

```bash
cp .env.template .env
# Edit .env with your settings
```

#### Essential Configuration

```bash
# Enterprise Proxy (if required)
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,.company.com

# Package Registries
NPM_REGISTRY=https://artifactory.company.com/npm/
PIP_INDEX_URL=https://artifactory.company.com/pypi/simple/

# AWS Configuration
AWS_PROFILE=default
AWS_REGION=us-east-1
AWS_BEDROCK_REGION=us-east-1

# Git Configuration
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@company.com"
```

### Certificate Management

For enterprise environments with custom certificates:

```bash
# Copy certificates to the certs directory
mkdir -p certs
cp /path/to/your/certificates/* certs/

# Certificates will be automatically installed in the container
```

## 🎯 Usage

### Basic Commands

```bash
# Start development environment
./dev-env.sh start

# Build container image only
./dev-env.sh build

# Start with shell access
./dev-env.sh shell

# Force rebuild
./dev-env.sh start --rebuild

# Clean up containers and images
./dev-env.sh clean

# Show help
./dev-env.sh help
```

### Using Podman Compose (Alternative)

```bash
# Start all services
podman-compose -f podman-compose.yml up -d

# Start with Jupyter Lab
podman-compose -f podman-compose.yml --profile jupyter up -d

# Stop all services
podman-compose -f podman-compose.yml down
```

## 🏗️ Project Structure

```
.
├── dev-env.sh              # Main startup script
├── Containerfile           # Container build configuration
├── podman-compose.yml      # Multi-service orchestration
├── .env.template           # Environment configuration template
├── config/                 # Configuration files
│   ├── .bashrc            # Shell configuration
│   ├── .gitconfig         # Git configuration template
│   ├── .npmrc             # NPM configuration
│   ├── pip.conf           # Python package configuration
│   └── entrypoint.sh      # Container entry point
├── scripts/               # Utility scripts
│   └── setup-env.sh       # Environment setup script
├── certs/                 # Custom certificates (create if needed)
└── DEV-ENV-README.md      # This file
```

## 📁 Workspace Layout

Once started, your development environment includes:

```
/workspace/                 # Main workspace (persisted)
├── projects/              # Your development projects
│   ├── java/             # Java projects
│   ├── python/           # Python projects
│   ├── nodejs/           # Node.js projects
│   └── scripts/          # Utility scripts
├── data/                  # Data files and datasets
│   ├── input/            # Input data
│   ├── output/           # Generated output
│   └── temp/             # Temporary files
├── docs/                  # Documentation
│   ├── notes/            # Personal notes
│   └── references/       # Reference materials
└── config/               # Local configuration
    ├── local/            # User-specific config
    └── templates/        # Project templates
```

## 🛠️ Development Tools

### Included Tools

- **Java 17** - OpenJDK with development kit
- **Python 3.10+** - Latest stable with pip
- **Node.js 18** - LTS version with npm
- **Maven 3.9+** - Java build tool
- **Git** - Version control
- **AWS CLI** - Cloud services
- **Jupyter Lab** - Interactive development
- **Vim/Nano** - Text editors

### Quick Commands

```bash
# Create new projects
create-java-project my-app
create-python-project my-script
create-node-project my-web-app

# Development shortcuts
jl                    # Start Jupyter Lab
gs                    # Git status
dev-info             # Show environment info
backup-workspace     # Backup workspace data

# Container management
restart-jupyter      # Restart Jupyter Lab
```

## 🌐 Network Configuration

### Enterprise Environments

The environment supports:

- **HTTP/HTTPS Proxies** - Automatic configuration
- **Custom Certificate Authorities** - Automatic installation
- **Private Package Registries** - NPM, PyPI, Maven
- **Air-gapped Networks** - Offline-capable post-setup

### Port Mappings

- **8888** - Jupyter Lab
- **3000** - Web development server
- **8080** - Application server
- **5000** - Custom application port

## ☁️ AWS Bedrock Integration

### Setup

1. Configure AWS credentials:
```bash
# Option 1: Use AWS profile
AWS_PROFILE=your-profile

# Option 2: Mount AWS credentials
# The script automatically mounts ~/.aws if it exists
```

2. Set Bedrock configuration:
```bash
AWS_BEDROCK_REGION=us-east-1
AWS_BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0
```

3. Test connectivity:
```bash
aws-bedrock-test
```

## 🔧 Platform-Specific Setup

### Windows with WSL2

```bash
# In WSL2 terminal
cd /mnt/c/your/project/directory
./dev-env.sh start
```

**Notes:**
- Mount Windows directories under `/mnt/c/`
- Podman runs in WSL2 context
- File permissions may need adjustment

### Ubuntu (Native)

```bash
# Direct execution
./dev-env.sh start
```

**Notes:**
- Rootless Podman recommended
- SELinux labels handled automatically
- SystemD integration available

### AWS Workspaces Ubuntu

```bash
# May require proxy configuration
export HTTP_PROXY=http://proxy:8080
export HTTPS_PROXY=http://proxy:8080
./dev-env.sh start
```

**Notes:**
- Proxy settings typically required
- Custom certificates often needed
- Limited internet access

### macOS

```bash
# Ensure Podman machine is running
podman machine start
./dev-env.sh start
```

**Notes:**
- Podman machine required
- Volume mounting differs from Linux
- Performance considerations for large projects

## 🚨 Troubleshooting

### Common Issues

#### Podman Not Found
```bash
# Install Podman for your platform
# Ubuntu/Debian:
sudo apt install podman

# macOS:
brew install podman
```

#### Permission Denied
```bash
# Make script executable
chmod +x dev-env.sh

# Fix ownership (if needed)
sudo chown -R $USER:$USER .
```

#### Network Issues
```bash
# Test basic connectivity
curl -I https://registry.npmjs.org/

# Check proxy settings
echo $HTTP_PROXY

# Verify DNS resolution
nslookup registry.npmjs.org
```

#### Container Build Fails
```bash
# Clean and rebuild
./dev-env.sh clean
./dev-env.sh build --rebuild

# Check logs
podman logs universal-dev-env
```

#### Certificate Issues
```bash
# Copy system certificates
sudo cp /etc/ssl/certs/* ./certs/

# Rebuild with certificates
./dev-env.sh build --rebuild
```

### Enterprise-Specific Issues

See the [Troubleshooting Guide](TROUBLESHOOTING.md) for detailed enterprise environment solutions.

## 🔒 Security Considerations

- **No hardcoded credentials** - All sensitive data via environment variables
- **Certificate validation** - Custom CA support for enterprise environments
- **Least privilege** - Non-root user in container
- **Network isolation** - Controlled port exposure
- **Volume mounting** - Read-only where appropriate

## 🚀 Performance Optimization

### Resource Allocation

```bash
# In .env file
MEMORY_LIMIT=4g
CPU_LIMIT=2.0
JAVA_OPTS="-Xmx2g -Xms512m"
NODE_OPTIONS="--max-old-space-size=4096"
```

### Cache Optimization

```bash
# Pre-populate caches
./dev-env.sh shell
npm install -g commonly-used-packages
pip install commonly-used-packages
```

## 🔄 Updates and Maintenance

### Updating the Environment

```bash
# Pull latest changes
git pull

# Rebuild container with latest updates
./dev-env.sh clean
./dev-env.sh build
```

### Backup and Restore

```bash
# Backup workspace
backup-workspace

# Restore from backup
tar -xzf backup.tar.gz -C /workspace/
```

## 📚 Additional Resources

- [Podman Documentation](https://docs.podman.io/)
- [AWS Bedrock User Guide](https://docs.aws.amazon.com/bedrock/)
- [Enterprise Integration Guide](ENTERPRISE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test across platforms
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review platform-specific documentation
3. Open an issue with:
   - Platform information
   - Error messages
   - Configuration (redacted)
   - Steps to reproduce

---

**Ready to develop!** 🎉 Start with `./dev-env.sh start` and begin your cross-platform development journey.