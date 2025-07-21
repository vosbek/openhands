#!/bin/bash

set -euo pipefail

# Universal Development Environment Entrypoint
# Enhanced startup script with comprehensive environment setup
# Version: 2.0.0

readonly SCRIPT_NAME="Universal Dev Environment"
readonly VERSION="2.0.0"

# Logging functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

info() {
    log "INFO: $*"
}

warn() {
    log "WARN: $*"
}

error() {
    log "ERROR: $*"
    exit 1
}

success() {
    log "SUCCESS: $*"
}

# Environment detection
detect_environment() {
    local platform="${PLATFORM:-unknown}"
    local container_runtime="podman"
    
    if command -v docker &> /dev/null; then
        container_runtime="docker"
    fi
    
    info "Platform: $platform"
    info "Container Runtime: $container_runtime"
    info "User: $(whoami) (UID: $(id -u), GID: $(id -g))"
    info "Home: $HOME"
    info "Shell: $SHELL"
}

# AWS Configuration with enhanced Bedrock support
configure_aws() {
    info "Configuring AWS environment..."
    
    # Set up AWS directory structure
    mkdir -p ~/.aws
    
    # Configure AWS CLI if credentials are available
    if [[ -f "/home/developer/.aws/credentials" ]] || [[ -n "${AWS_ACCESS_KEY_ID:-}" ]]; then
        # Set default region
        if [[ -n "${AWS_REGION:-}" ]]; then
            aws configure set region "$AWS_REGION" 2>/dev/null || true
            success "AWS region set to: $AWS_REGION"
        fi
        
        if [[ -n "${AWS_BEDROCK_REGION:-}" ]]; then
            aws configure set region "$AWS_BEDROCK_REGION" --profile bedrock 2>/dev/null || true
            success "AWS Bedrock region set to: $AWS_BEDROCK_REGION"
        fi
        
        # Test AWS connectivity
        if aws sts get-caller-identity &>/dev/null; then
            local aws_identity
            aws_identity=$(aws sts get-caller-identity --output json 2>/dev/null || echo '{}')
            local aws_user
            aws_user=$(echo "$aws_identity" | jq -r '.Arn // "unknown"' 2>/dev/null || echo "unknown")
            success "AWS authenticated as: $aws_user"
            
            # Test Bedrock access
            test_bedrock_access
        else
            warn "AWS credentials configured but authentication failed"
        fi
    else
        warn "No AWS credentials found. Bedrock integration will not be available."
        info "To configure AWS:"
        info "  1. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
        info "  2. Or mount ~/.aws/credentials file"
        info "  3. Or configure AWS profile"
    fi
}

# Test AWS Bedrock access
test_bedrock_access() {
    local bedrock_region="${AWS_BEDROCK_REGION:-${AWS_REGION:-us-east-1}}"
    
    info "Testing AWS Bedrock access in region: $bedrock_region"
    
    if aws bedrock list-foundation-models --region "$bedrock_region" &>/dev/null; then
        local model_count
        model_count=$(aws bedrock list-foundation-models --region "$bedrock_region" --output json 2>/dev/null | jq '.modelSummaries | length' 2>/dev/null || echo "unknown")
        success "Bedrock accessible with $model_count foundation models available"
        
        # Check for specific Claude models
        if aws bedrock list-foundation-models --region "$bedrock_region" --output json 2>/dev/null | jq -r '.modelSummaries[].modelId' | grep -q "anthropic.claude"; then
            success "Anthropic Claude models are available"
        else
            warn "Anthropic Claude models may not be available in your account/region"
        fi
    else
        warn "AWS Bedrock not accessible. Check permissions and region."
        info "Required IAM permissions:"
        info "  - bedrock:ListFoundationModels"
        info "  - bedrock:InvokeModel"
        info "  - bedrock:InvokeModelWithResponseStream"
    fi
}

# Configure Git with enhanced enterprise support
configure_git() {
    info "Configuring Git environment..."
    
    # Apply Git configuration from environment variables
    if [[ -n "${GIT_USER_NAME:-}" ]]; then
        git config --global user.name "$GIT_USER_NAME"
        success "Git user.name set to: $GIT_USER_NAME"
    fi
    
    if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
        git config --global user.email "$GIT_USER_EMAIL"
        success "Git user.email set to: $GIT_USER_EMAIL"
    fi
    
    # Configure Git for enterprise environments
    if [[ -n "${GITHUB_ENTERPRISE_URL:-}" ]]; then
        git config --global url."$GITHUB_ENTERPRISE_URL".insteadOf "https://github.com"
        success "Git configured for GitHub Enterprise: $GITHUB_ENTERPRISE_URL"
    fi
    
    # Configure credential helper
    git config --global credential.helper store
    
    # Set up safe directory (for mounted volumes)
    git config --global --add safe.directory '*'
    
    # Configure proxy if needed
    if [[ -n "${HTTP_PROXY:-}" ]]; then
        git config --global http.proxy "$HTTP_PROXY"
    fi
    
    if [[ -n "${HTTPS_PROXY:-}" ]]; then
        git config --global https.proxy "$HTTPS_PROXY"
    fi
    
    # Configure SSL settings
    if [[ "${DISABLE_SSL_VERIFICATION:-false}" == "true" ]]; then
        warn "SSL verification disabled for Git (not recommended for production)"
        git config --global http.sslVerify false
    fi
}

# Configure package managers for enterprise environments
configure_package_managers() {
    info "Configuring package managers..."
    
    # Configure NPM
    if [[ -n "${NPM_REGISTRY:-}" ]] && [[ "$NPM_REGISTRY" != "https://registry.npmjs.org/" ]]; then
        npm config set registry "$NPM_REGISTRY"
        success "NPM registry set to: $NPM_REGISTRY"
    fi
    
    # Configure NPM proxy settings
    if [[ -n "${HTTP_PROXY:-}" ]]; then
        npm config set proxy "$HTTP_PROXY"
        npm config set http-proxy "$HTTP_PROXY"
    fi
    
    if [[ -n "${HTTPS_PROXY:-}" ]]; then
        npm config set https-proxy "$HTTPS_PROXY"
    fi
    
    # Configure Python pip
    if [[ -n "${PIP_INDEX_URL:-}" ]] && [[ "$PIP_INDEX_URL" != "https://pypi.org/simple/" ]]; then
        pip config set global.index-url "$PIP_INDEX_URL"
        success "Python pip index set to: $PIP_INDEX_URL"
    fi
    
    # Configure pip proxy
    if [[ -n "${HTTP_PROXY:-}" ]]; then
        pip config set global.proxy "$HTTP_PROXY"
    fi
}

# Enhanced SSL certificate management
configure_ssl_certificates() {
    info "Configuring SSL certificates..."
    
    local cert_count=0
    
    # Install custom certificates if available
    if [[ -d "/certs" ]] && [[ "$(ls -A /certs 2>/dev/null)" ]]; then
        info "Installing custom SSL certificates..."
        
        # Copy certificates to system location
        sudo cp /certs/*.crt /usr/local/share/ca-certificates/ 2>/dev/null || true
        sudo cp /certs/*.pem /usr/local/share/ca-certificates/ 2>/dev/null || true
        
        # Update certificate store
        sudo update-ca-certificates >/dev/null 2>&1 || true
        
        cert_count=$(find /certs -type f \( -name "*.crt" -o -name "*.pem" \) | wc -l)
        success "Installed $cert_count custom SSL certificates"
        
        # Configure applications to use updated certificates
        export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
        export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
        export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
    fi
    
    # Handle SSL verification settings
    if [[ "${DISABLE_SSL_VERIFICATION:-false}" == "true" ]]; then
        warn "SSL verification disabled globally (not recommended for production)"
        export PYTHONHTTPSVERIFY=0
        export NODE_TLS_REJECT_UNAUTHORIZED=0
        export CURL_INSECURE=1
    fi
}

# Configure SSH with enhanced security
configure_ssh() {
    info "Configuring SSH environment..."
    
    if [[ -d "/home/developer/.ssh" ]] && [[ "$(ls -A /home/developer/.ssh 2>/dev/null)" ]]; then
        # Set correct permissions
        chmod 700 /home/developer/.ssh
        find /home/developer/.ssh -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
        find /home/developer/.ssh -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
        find /home/developer/.ssh -type f -name "config" -exec chmod 600 {} \; 2>/dev/null || true
        find /home/developer/.ssh -type f -name "known_hosts*" -exec chmod 600 {} \; 2>/dev/null || true
        
        success "SSH configuration loaded and secured"
        
        # Test SSH connectivity to common services
        test_ssh_connectivity
    else
        warn "No SSH configuration found"
        info "To enable SSH access, mount your ~/.ssh directory to /home/developer/.ssh"
    fi
}

# Test SSH connectivity
test_ssh_connectivity() {
    local services=("github.com" "gitlab.com")
    
    for service in "${services[@]}"; do
        if ssh -T git@"$service" -o ConnectTimeout=5 -o StrictHostKeyChecking=no >/dev/null 2>&1; then
            success "SSH connectivity verified for $service"
        fi
    done
}

# Configure development environment
configure_development_environment() {
    info "Configuring development environment..."
    
    # Set up workspace directories
    mkdir -p /workspace/{projects,scripts,data,docs,tmp}
    mkdir -p /config/{local,global}
    mkdir -p /cache/{npm,pip,maven,gradle}
    
    # Configure Java environment
    if [[ -n "${JAVA_OPTS:-}" ]]; then
        export JAVA_OPTS="$JAVA_OPTS"
        export MAVEN_OPTS="$JAVA_OPTS"
        export GRADLE_OPTS="$JAVA_OPTS"
        success "Java environment configured with: $JAVA_OPTS"
    fi
    
    # Configure Node.js environment
    if [[ -n "${NODE_OPTIONS:-}" ]]; then
        export NODE_OPTIONS="$NODE_OPTIONS"
        success "Node.js environment configured with: $NODE_OPTIONS"
    fi
    
    # Configure Python environment
    if [[ -n "${PYTHON_ENV:-}" ]]; then
        export PYTHON_ENV="$PYTHON_ENV"
        if [[ "$PYTHON_ENV" == "development" ]]; then
            export PYTHONPATH="/workspace:$PYTHONPATH"
            export PYTHONDONTWRITEBYTECODE=1
        fi
        success "Python environment set to: $PYTHON_ENV"
    fi
    
    # Set up file permissions
    sudo chown -R developer:developer /workspace /config /cache 2>/dev/null || true
}

# Configure Jupyter Lab
configure_jupyter() {
    info "Configuring Jupyter Lab..."
    
    # Generate Jupyter configuration if it doesn't exist
    if [[ ! -f "/home/developer/.jupyter/jupyter_lab_config.py" ]]; then
        mkdir -p /home/developer/.jupyter
        
        cat > /home/developer/.jupyter/jupyter_lab_config.py << 'EOF'
# Universal Development Environment Jupyter Configuration

# Server settings
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True
c.ServerApp.root_dir = '/workspace'

# Authentication
c.ServerApp.token = ''
c.ServerApp.password = ''

# Lab settings
c.LabApp.default_url = '/lab'

# File manager
c.ContentsManager.allow_hidden = True

# Security
c.ServerApp.allow_remote_access = True
c.ServerApp.allow_credentials = True

# Extensions
c.LabServerApp.blacklist_uris = []
c.LabServerApp.whitelist_uris = []
EOF
        
        success "Jupyter Lab configuration created"
    fi
    
    # Set Jupyter environment variables
    export JUPYTER_ENABLE_LAB=yes
    export JUPYTER_CONFIG_DIR=/home/developer/.jupyter
    export JUPYTER_DATA_DIR=/home/developer/.local/share/jupyter
}

# Start background services
start_services() {
    info "Starting background services..."
    
    # Start Jupyter Lab if requested
    if [[ "${START_JUPYTER:-false}" == "true" ]] || [[ "${1:-}" == *"jupyter"* ]]; then
        info "Starting Jupyter Lab..."
        nohup jupyter lab --config=/home/developer/.jupyter/jupyter_lab_config.py \
            >/logs/jupyter.log 2>&1 &
        success "Jupyter Lab started on port 8888"
    fi
    
    # Start health monitoring
    start_health_monitor
}

# Health monitoring service
start_health_monitor() {
    (
        while true; do
            {
                echo "$(date): Health Check"
                echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
                echo "Disk: $(df -h /workspace 2>/dev/null | tail -n 1 | awk '{print $3 "/" $2 " (" $5 " used)"}' || echo "N/A")"
                echo "Load: $(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')"
                echo "Processes: $(ps aux | wc -l)"
                echo "---"
            } >> /logs/health.log 2>&1
            sleep 60
        done
    ) &
}

# Display environment information
show_environment_info() {
    echo ""
    echo "🚀 $SCRIPT_NAME v$VERSION"
    echo "============================================"
    
    # System information
    echo "📊 System Information:"
    echo "  Platform: ${PLATFORM:-unknown}"
    echo "  User: $(whoami) (UID: $(id -u), GID: $(id -g))"
    echo "  Home: $HOME"
    echo "  Working Directory: $(pwd)"
    echo "  Shell: $SHELL"
    echo ""
    
    # Tool versions
    echo "🛠️  Development Tools:"
    echo "  Java: $(java -version 2>&1 | head -n 1 | cut -d'"' -f2)"
    echo "  Python: $(python --version | cut -d' ' -f2)"
    echo "  Node.js: $(node --version)"
    echo "  NPM: $(npm --version)"
    echo "  Maven: $(mvn --version 2>/dev/null | head -n 1 | cut -d' ' -f3 || echo 'Not available')"
    echo "  Git: $(git --version | cut -d' ' -f3)"
    echo "  AWS CLI: $(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)"
    echo ""
    
    # Network configuration
    echo "🌐 Network Configuration:"
    if [[ -n "${HTTP_PROXY:-}" ]] || [[ -n "${HTTPS_PROXY:-}" ]]; then
        echo "  Proxy Configuration:"
        [[ -n "${HTTP_PROXY:-}" ]] && echo "    HTTP Proxy: $HTTP_PROXY"
        [[ -n "${HTTPS_PROXY:-}" ]] && echo "    HTTPS Proxy: $HTTPS_PROXY"
        [[ -n "${NO_PROXY:-}" ]] && echo "    No Proxy: $NO_PROXY"
    else
        echo "  Direct internet connection"
    fi
    echo ""
    
    # AWS configuration
    if [[ -n "${AWS_PROFILE:-}" ]] || [[ -n "${AWS_REGION:-}" ]]; then
        echo "☁️  AWS Configuration:"
        [[ -n "${AWS_PROFILE:-}" ]] && echo "  Profile: $AWS_PROFILE"
        [[ -n "${AWS_REGION:-}" ]] && echo "  Region: $AWS_REGION"
        [[ -n "${AWS_BEDROCK_REGION:-}" ]] && echo "  Bedrock Region: $AWS_BEDROCK_REGION"
        [[ -n "${AWS_BEDROCK_MODEL_ID:-}" ]] && echo "  Bedrock Model: $AWS_BEDROCK_MODEL_ID"
        echo ""
    fi
    
    # Access URLs
    echo "🔗 Access URLs:"
    echo "  OpenHands Web UI: http://localhost:${HTTP_PORT:-3000}"
    echo "  Jupyter Lab: http://localhost:${JUPYTER_PORT:-8888}"
    echo "  Code Server: http://localhost:${CODE_SERVER_PORT:-8080}"
    echo ""
    
    # Quick commands
    echo "⚡ Quick Commands:"
    echo "  jl                     - Start Jupyter Lab"
    echo "  code /workspace        - Open VS Code"
    echo "  git clone <repo>       - Clone repository"
    echo "  aws bedrock list-foundation-models  - Test Bedrock"
    echo "  dev-info               - Show detailed environment info"
    echo ""
    
    # Workspace information
    echo "📁 Workspace Structure:"
    echo "  /workspace/            - Your development projects"
    echo "  /config/               - Configuration files"
    echo "  /cache/                - Package manager caches"
    echo "  /logs/                 - Application logs"
    echo ""
    
    success "Environment ready for development! 🎉"
    echo ""
}

# Create development helper functions
create_dev_helpers() {
    # Create helper scripts directory
    mkdir -p /home/developer/scripts
    
    # Create dev-info command
    cat > /home/developer/scripts/dev-info << 'EOF'
#!/bin/bash
echo "🖥️  Development Environment Information"
echo "======================================"
echo "Platform: ${PLATFORM:-unknown}"
echo "User: $(whoami) (UID: $(id -u), GID: $(id -g))"
echo "PWD: $(pwd)"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h /workspace 2>/dev/null | tail -n 1 | awk '{print $3 "/" $2 " (" $5 " used)"}' || echo "N/A")"
echo "Load: $(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')"
echo ""
echo "🔧 Tool Versions:"
echo "Java: $(java -version 2>&1 | head -n 1 | cut -d'"' -f2)"
echo "Python: $(python --version | cut -d' ' -f2)"
echo "Node.js: $(node --version)"
echo "Maven: $(mvn --version 2>/dev/null | head -n 1 | cut -d' ' -f3 || echo 'Not available')"
echo "Git: $(git --version | cut -d' ' -f3)"
echo "AWS CLI: $(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)"
echo ""
echo "🌐 Network:"
[[ -n "${HTTP_PROXY:-}" ]] && echo "HTTP Proxy: $HTTP_PROXY"
[[ -n "${HTTPS_PROXY:-}" ]] && echo "HTTPS Proxy: $HTTPS_PROXY"
echo "NPM Registry: $(npm config get registry)"
echo ""
echo "☁️  AWS:"
aws sts get-caller-identity 2>/dev/null | jq -r '"User: " + (.Arn // "Not authenticated")' || echo "Not authenticated"
[[ -n "${AWS_REGION:-}" ]] && echo "Region: $AWS_REGION"
[[ -n "${AWS_BEDROCK_REGION:-}" ]] && echo "Bedrock Region: $AWS_BEDROCK_REGION"
EOF
    
    chmod +x /home/developer/scripts/dev-info
    
    # Add to PATH
    echo 'export PATH="$HOME/scripts:$PATH"' >> /home/developer/.bashrc
}

# Main execution function
main() {
    info "Starting $SCRIPT_NAME v$VERSION..."
    
    # Detect environment
    detect_environment
    
    # Configure all components
    configure_ssl_certificates
    configure_aws
    configure_git
    configure_package_managers
    configure_ssh
    configure_development_environment
    configure_jupyter
    
    # Create helper functions
    create_dev_helpers
    
    # Start services
    start_services "$@"
    
    # Show environment information
    show_environment_info
    
    # Execute the provided command or start bash
    if [[ $# -eq 0 ]]; then
        exec /bin/bash
    else
        exec "$@"
    fi
}

# Error handling
trap 'error "Script failed at line $LINENO"' ERR

# Execute main function
main "$@"