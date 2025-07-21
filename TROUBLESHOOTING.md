# Troubleshooting Guide for Universal Development Environment

This guide provides solutions for common issues encountered when using the Universal Development Environment across different platforms and enterprise environments.

## 🚨 Common Issues

### Platform Detection and Setup

#### Issue: Script fails to detect platform correctly
```bash
Error: Unknown platform detected
```

**Solution:**
```bash
# Check your current OS type
echo $OSTYPE

# For WSL users, check if WSL is properly configured
grep -i microsoft /proc/version

# Manual platform override
export DEV_ENV_PLATFORM=ubuntu  # or wsl, macos, etc.
./dev-env.sh start
```

#### Issue: Podman not found or not configured
```bash
Error: Podman is not installed
```

**Solution by Platform:**

**Ubuntu/Debian:**
```bash
# Install Podman
sudo apt update
sudo apt install -y podman

# Configure rootless containers
podman system migrate
```

**CentOS/RHEL/Fedora:**
```bash
# Install Podman
sudo dnf install -y podman

# Enable and start services
sudo systemctl enable --now podman.socket
```

**macOS:**
```bash
# Install via Homebrew
brew install podman

# Initialize Podman machine
podman machine init --cpus 2 --memory 4096
podman machine start
```

**Windows WSL2:**
```bash
# In WSL2 terminal
sudo apt update
sudo apt install -y podman

# Configure for WSL2
echo 'export PODMAN_SOCKET="unix:///run/user/$(id -u)/podman/podman.sock"' >> ~/.bashrc
source ~/.bashrc
```

### Container Build Issues

#### Issue: Build fails with network timeouts
```bash
Error: Unable to download packages
```

**Solution:**
```bash
# Check network connectivity
curl -I https://registry.npmjs.org/
curl -I https://pypi.org/simple/

# Configure proxy if needed
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1,.company.com

# Rebuild with proxy settings
./dev-env.sh build --rebuild
```

#### Issue: Certificate verification failures
```bash
Error: SSL certificate problem: unable to get local issuer certificate
```

**Solution:**
```bash
# Copy system certificates
mkdir -p certs
sudo cp /etc/ssl/certs/* ./certs/ 2>/dev/null || true

# For enterprise environments, copy custom CA certificates
cp /path/to/company/certs/* ./certs/

# Disable SSL verification temporarily (NOT RECOMMENDED for production)
export PYTHONHTTPSVERIFY=0
export NODE_TLS_REJECT_UNAUTHORIZED=0

# Rebuild with certificates
./dev-env.sh build --rebuild
```

#### Issue: Package registry access denied
```bash
Error: 403 Forbidden - Access denied to registry
```

**Solution:**
```bash
# Configure NPM authentication
npm config set //artifactory.company.com/:_authToken=${NPM_TOKEN}

# Configure pip authentication
echo "[global]
index-url = https://username:password@artifactory.company.com/pypi/simple/" > ~/.pip/pip.conf

# Update .env file with correct registries
cat >> .env << EOF
NPM_REGISTRY=https://artifactory.company.com/npm/
PIP_INDEX_URL=https://artifactory.company.com/pypi/simple/
EOF
```

### Runtime Issues

#### Issue: Container fails to start
```bash
Error: Container failed to start or exits immediately
```

**Solution:**
```bash
# Check container logs
podman logs universal-dev-env

# Check for port conflicts
netstat -tulpn | grep :8888
lsof -i :8888

# Use different ports
export JUPYTER_PORT=8889
export WEB_DEV_PORT=3001
./dev-env.sh start
```

#### Issue: Volume mounting failures
```bash
Error: Permission denied accessing mounted volumes
```

**Solution:**

**Linux (SELinux enabled):**
```bash
# Check SELinux context
ls -laZ ~/.dev-env/

# Fix SELinux labels
sudo restorecon -R ~/.dev-env/
sudo chcon -R -t container_file_t ~/.dev-env/

# Or disable SELinux temporarily
sudo setenforce 0
```

**macOS:**
```bash
# Ensure Podman machine has access to directories
podman machine set --rootful=false
podman machine stop
podman machine start

# Grant directory access in macOS System Preferences > Security & Privacy
```

**Windows WSL2:**
```bash
# Fix file permissions
sudo chown -R $(id -u):$(id -g) ~/.dev-env/
chmod -R 755 ~/.dev-env/

# Ensure WSL can access Windows drives
ls -la /mnt/c/
```

#### Issue: SSH key access problems
```bash
Error: Permission denied (publickey)
```

**Solution:**
```bash
# Check SSH key permissions
ls -la ~/.ssh/
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub

# Copy SSH keys to dev environment
cp -r ~/.ssh ~/.dev-env/ssh/
chmod -R 600 ~/.dev-env/ssh/

# Test SSH connection from container
./dev-env.sh shell
ssh -T git@github.com
```

## 🏢 Enterprise Environment Issues

### Proxy Configuration

#### Issue: HTTP/HTTPS proxy not working
```bash
Error: Connection timeout through proxy
```

**Solution:**
```bash
# Verify proxy settings
echo $HTTP_PROXY
echo $HTTPS_PROXY
echo $NO_PROXY

# Test proxy connectivity
curl -I --proxy $HTTP_PROXY https://registry.npmjs.org/

# Configure authentication if required
export HTTP_PROXY=http://username:password@proxy.company.com:8080
export HTTPS_PROXY=http://username:password@proxy.company.com:8080

# Update no_proxy for internal services
export NO_PROXY=localhost,127.0.0.1,.company.com,.local,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
```

#### Issue: SOCKS proxy configuration
```bash
Error: SOCKS proxy not supported
```

**Solution:**
```bash
# Use HTTP proxy converter
# Install proxychains or similar tool
sudo apt install proxychains4

# Configure proxychains
echo "socks5 127.0.0.1 1080" >> /etc/proxychains4.conf

# Run container through proxychains
proxychains4 ./dev-env.sh start
```

### Certificate Management

#### Issue: Corporate CA certificates not trusted
```bash
Error: Certificate verify failed: unable to get local issuer certificate
```

**Solution:**
```bash
# Extract certificates from browser/system
# For Firefox:
# Security > Certificates > View Certificates > Authorities > Export

# For Chrome/System:
# Copy from system certificate store

# Install certificates
mkdir -p certs
cp /path/to/corporate/ca.crt certs/
cp /path/to/intermediate.crt certs/

# For Windows, export from Certificate Manager:
# certmgr.msc > Trusted Root Certificate Authorities > Export as Base64

# Update container to include certificates
./dev-env.sh build --rebuild
```

#### Issue: Self-signed certificate errors
```bash
Error: Self-signed certificate in certificate chain
```

**Solution:**
```bash
# Temporarily disable SSL verification (NOT for production)
export NODE_TLS_REJECT_UNAUTHORIZED=0
export PYTHONHTTPSVERIFY=0
export GIT_SSL_NO_VERIFY=true

# Better solution: Add self-signed cert to trust store
openssl s_client -showcerts -servername domain.com -connect domain.com:443 < /dev/null 2>/dev/null | openssl x509 -outform PEM > domain.crt
cp domain.crt certs/
./dev-env.sh build --rebuild
```

### Network Access

#### Issue: Air-gapped environment setup
```bash
Error: Cannot reach external repositories
```

**Solution:**
```bash
# Pre-download container images on connected machine
podman save -o universal-dev-image.tar universal-dev:latest

# Transfer to air-gapped environment
podman load -i universal-dev-image.tar

# Configure local/mirror repositories
cat >> .env << EOF
NPM_REGISTRY=http://local-mirror.company.com/npm/
PIP_INDEX_URL=http://local-mirror.company.com/pypi/simple/
MAVEN_REPOSITORY_URL=http://local-mirror.company.com/maven/
EOF
```

#### Issue: DNS resolution problems
```bash
Error: Could not resolve hostname
```

**Solution:**
```bash
# Check DNS configuration
cat /etc/resolv.conf

# Configure custom DNS in container
podman run --dns=8.8.8.8 --dns=1.1.1.1 ...

# Or add to podman-compose.yml
# dns:
#   - 8.8.8.8
#   - 1.1.1.1

# For corporate DNS
export PODMAN_DNS="--dns=corporate.dns.server.com"
```

### Authentication Issues

#### Issue: AWS credentials not working
```bash
Error: Unable to locate credentials
```

**Solution:**
```bash
# Check AWS configuration
aws configure list

# Verify credentials file
cat ~/.aws/credentials
cat ~/.aws/config

# For AWS SSO
aws sso login --profile your-profile

# Test AWS access
aws sts get-caller-identity

# Configure in container
export AWS_PROFILE=your-profile
export AWS_REGION=us-east-1
./dev-env.sh start
```

#### Issue: GitHub authentication failures
```bash
Error: Authentication failed for GitHub
```

**Solution:**
```bash
# For personal access token
export GITHUB_TOKEN=ghp_your_token

# For SSH keys
ssh-add ~/.ssh/id_ed25519

# Test GitHub access
ssh -T git@github.com

# For GitHub Enterprise
export GITHUB_ENTERPRISE_URL=https://github.company.com/api/v3
```

## 🔧 Performance Issues

### Memory and CPU

#### Issue: Container running out of memory
```bash
Error: Container killed (OOM)
```

**Solution:**
```bash
# Increase memory limits
cat >> .env << EOF
MEMORY_LIMIT=8g
JAVA_OPTS="-Xmx4g -Xms1g"
NODE_OPTIONS="--max-old-space-size=8192"
EOF

# Monitor memory usage
podman stats universal-dev-env

# Optimize Java heap size
export JAVA_OPTS="-Xmx2g -Xms512m -XX:+UseG1GC"
```

#### Issue: Slow container startup
```bash
Container takes too long to start
```

**Solution:**
```bash
# Use pre-built images where possible
podman pull universal-dev:latest

# Optimize Containerfile layers
# - Combine RUN commands
# - Use multi-stage builds
# - Cache dependencies

# Pre-warm package caches
mkdir -p ~/.dev-env/cache/{npm,pip,maven}
npm cache clean --force
pip cache purge
```

### Storage Issues

#### Issue: Disk space running low
```bash
Error: No space left on device
```

**Solution:**
```bash
# Clean up Podman images and containers
podman system prune -af

# Clean up workspace
find ~/.dev-env/ -name "*.log" -delete
find ~/.dev-env/ -name "__pycache__" -exec rm -rf {} +
find ~/.dev-env/ -name "node_modules" -exec rm -rf {} +

# Move cache to external storage
ln -s /external/storage/cache ~/.dev-env/cache
```

## 🐛 Debug Mode

### Enable Debug Output

```bash
# Enable debug mode
export DEBUG=true
./dev-env.sh start --debug

# Check logs
podman logs -f universal-dev-env

# Monitor container activity
podman top universal-dev-env

# Get detailed container info
podman inspect universal-dev-env
```

### Container Shell Access

```bash
# Access running container
./dev-env.sh shell

# Or use podman directly
podman exec -it universal-dev-env /bin/bash

# Check processes
ps aux

# Check network connectivity
curl -I https://registry.npmjs.org/
ping google.com

# Check mounted volumes
mount | grep workspace
df -h
```

## 📞 Getting Help

### Information to Collect

When reporting issues, please provide:

1. **Platform Information:**
```bash
# System info
uname -a
cat /etc/os-release  # Linux
sw_vers              # macOS

# Podman version
podman --version
podman info
```

2. **Environment Configuration:**
```bash
# Environment variables (redact sensitive info)
env | grep -E "(PROXY|REGISTRY|AWS)" | sed 's/=.*/=***/'

# Container status
podman ps -a
podman images
```

3. **Error Messages:**
```bash
# Container logs
podman logs universal-dev-env

# Build logs
./dev-env.sh build --debug 2>&1 | tee build.log
```

4. **Network Information:**
```bash
# Connectivity test
curl -I https://registry.npmjs.org/
curl -I https://pypi.org/simple/

# DNS resolution
nslookup registry.npmjs.org
```

### Support Resources

- **Container Issues:** Check [Podman documentation](https://docs.podman.io/)
- **Enterprise Setup:** Review your organization's container policies
- **AWS Integration:** Check [AWS CLI documentation](https://docs.aws.amazon.com/cli/)
- **Platform-specific:** Refer to platform documentation (WSL, macOS, Ubuntu)

### Emergency Workarounds

If you need to get working quickly:

```bash
# Bypass SSL verification (temporary)
export PYTHONHTTPSVERIFY=0
export NODE_TLS_REJECT_UNAUTHORIZED=0
export GIT_SSL_NO_VERIFY=true

# Use public registries (if allowed)
unset NPM_REGISTRY
unset PIP_INDEX_URL

# Minimal container run
podman run -it --rm ubuntu:22.04 bash

# Local development without container
# Install tools directly on host system
```

**Remember:** These workarounds are temporary solutions. Always implement proper security practices for production use.

---

For additional help, check the main [README](DEV-ENV-README.md) or open an issue with the information collected above.