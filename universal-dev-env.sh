#!/bin/bash

set -euo pipefail

# Universal Development Environment for OpenHands
# Bulletproof cross-platform setup with enterprise support
# Version: 2.0.0

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEV_ENV_VERSION="2.0.0"
readonly CONTAINER_NAME="openhands-universal-dev"
readonly IMAGE_NAME="openhands-universal-dev:latest"
readonly CONFIG_FILE="${SCRIPT_DIR}/.universal-dev.env"

# Logging functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

warn() {
    log "WARN: $*"
}

info() {
    log "INFO: $*"
}

success() {
    log "SUCCESS: $*"
}

# Platform detection with improved accuracy
detect_platform() {
    local platform=""
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            platform="wsl"
            info "Detected: Windows WSL2"
        elif grep -qi ubuntu /etc/os-release 2>/dev/null; then
            if [[ -n "${AWS_EXECUTION_ENV:-}" ]] || [[ -n "${AWS_BATCH_JOB_ID:-}" ]]; then
                platform="aws-workspace"
                info "Detected: AWS Workspaces Ubuntu"
            else
                platform="ubuntu"
                info "Detected: Ubuntu Linux"
            fi
        else
            platform="linux"
            info "Detected: Generic Linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        platform="macos"
        info "Detected: macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        platform="windows"
        info "Detected: Windows (not WSL)"
        error "Please use WSL2. Run: wsl --install"
    else
        platform="unknown"
        warn "Unknown platform: $OSTYPE"
    fi
    
    echo "$platform"
}

# Enhanced Podman verification
check_podman() {
    info "Verifying Podman installation..."
    
    if ! command -v podman &> /dev/null; then
        error "Podman is not installed. Installation instructions:

Ubuntu/WSL2:    sudo apt update && sudo apt install -y podman
macOS:          brew install podman && podman machine init && podman machine start
CentOS/RHEL:    sudo dnf install -y podman"
    fi
    
    # Check if Podman is functional
    if ! podman info &> /dev/null; then
        warn "Podman is installed but not functional. Attempting to fix..."
        
        local platform
        platform=$(detect_platform)
        
        case "$platform" in
            "macos")
                if ! podman machine list | grep -q "Currently running"; then
                    info "Starting Podman machine..."
                    podman machine start || error "Failed to start Podman machine"
                fi
                ;;
            "wsl"|"ubuntu"|"linux")
                # Check for rootless setup
                if [[ ! -d "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/containers" ]]; then
                    info "Setting up rootless Podman..."
                    podman system migrate || warn "System migration failed"
                fi
                ;;
        esac
        
        # Verify again
        if ! podman info &> /dev/null; then
            error "Podman is not working properly. Please check your installation."
        fi
    fi
    
    success "Podman verification complete"
}

# Smart directory setup with platform-specific handling
setup_directories() {
    info "Setting up directory structure..."
    
    local platform
    platform=$(detect_platform)
    
    # Base directory structure
    local base_dir
    case "$platform" in
        "wsl")
            # Use WSL2 native filesystem for better performance
            base_dir="$HOME/.openhands-universal"
            
            # Create Windows convenience link if possible
            if [[ -d "/mnt/c/Users" ]]; then
                local windows_user
                windows_user=$(ls /mnt/c/Users | grep -v "Public\|Default" | head -n1)
                if [[ -n "$windows_user" ]] && [[ -d "/mnt/c/Users/$windows_user" ]]; then
                    local windows_link="/mnt/c/Users/$windows_user/openhands-universal"
                    if [[ ! -L "$windows_link" ]] && [[ ! -d "$windows_link" ]]; then
                        ln -sf "$base_dir" "$windows_link" 2>/dev/null || true
                        info "Created Windows convenience link: C:\\Users\\$windows_user\\openhands-universal"
                    fi
                fi
            fi
            ;;
        *)
            base_dir="$HOME/.openhands-universal"
            ;;
    esac
    
    local dirs=(
        "$base_dir/workspace"
        "$base_dir/config"
        "$base_dir/cache"
        "$base_dir/certs"
        "$base_dir/ssh"
        "$base_dir/aws"
        "$base_dir/logs"
        "$base_dir/backups"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
    done
    
    # Set base directory in environment
    export OPENHANDS_BASE_DIR="$base_dir"
    
    success "Directory structure created at: $base_dir"
}

# Enhanced certificate management
setup_certificates() {
    info "Setting up SSL certificates..."
    
    local cert_dir="$OPENHANDS_BASE_DIR/certs"
    local platform
    platform=$(detect_platform)
    
    case "$platform" in
        "wsl")
            # Copy both Linux and Windows certificates
            if [[ -d "/etc/ssl/certs" ]]; then
                cp /etc/ssl/certs/*.pem "$cert_dir/" 2>/dev/null || true
                cp /etc/ssl/certs/*.crt "$cert_dir/" 2>/dev/null || true
            fi
            
            # Look for Windows certificates
            local windows_cert_paths=(
                "/mnt/c/Windows/System32/config/systemprofile/AppData/Roaming/Microsoft/Windows/Cookies"
                "/mnt/c/Users/*/AppData/Roaming/Microsoft/SystemCertificates"
                "/mnt/c/ProgramData/Microsoft/Windows/SystemCertificates"
            )
            
            for cert_path in "${windows_cert_paths[@]}"; do
                if [[ -d "$cert_path" ]]; then
                    find "$cert_path" -name "*.crt" -exec cp {} "$cert_dir/" \; 2>/dev/null || true
                fi
            done
            ;;
        "ubuntu"|"linux")
            if [[ -d "/etc/ssl/certs" ]]; then
                cp /etc/ssl/certs/*.pem "$cert_dir/" 2>/dev/null || true
                cp /etc/ssl/certs/*.crt "$cert_dir/" 2>/dev/null || true
            fi
            if [[ -d "/usr/local/share/ca-certificates" ]]; then
                cp /usr/local/share/ca-certificates/*.crt "$cert_dir/" 2>/dev/null || true
            fi
            ;;
        "macos")
            # Export macOS system certificates
            if command -v security &> /dev/null; then
                security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > "$cert_dir/macos-system-certs.pem" 2>/dev/null || true
                security find-certificate -a -p /Library/Keychains/System.keychain > "$cert_dir/macos-user-certs.pem" 2>/dev/null || true
            fi
            ;;
    esac
    
    # Copy custom certificates from script directory
    if [[ -d "$SCRIPT_DIR/certs" ]]; then
        cp "$SCRIPT_DIR/certs"/* "$cert_dir/" 2>/dev/null || true
    fi
    
    # Set proper permissions
    find "$cert_dir" -type f -exec chmod 644 {} \;
    
    local cert_count
    cert_count=$(find "$cert_dir" -type f \( -name "*.crt" -o -name "*.pem" \) | wc -l)
    info "Found and configured $cert_count SSL certificates"
}

# Smart SSH key management
setup_ssh_keys() {
    info "Setting up SSH keys..."
    
    local ssh_dir="$OPENHANDS_BASE_DIR/ssh"
    
    if [[ -d "$HOME/.ssh" ]]; then
        # Copy SSH configuration and keys
        cp -r "$HOME/.ssh"/* "$ssh_dir/" 2>/dev/null || true
        
        # Set correct permissions
        chmod 700 "$ssh_dir"
        find "$ssh_dir" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \;
        find "$ssh_dir" -type f -name "*.pub" -exec chmod 644 {} \;
        find "$ssh_dir" -type f -name "config" -exec chmod 600 {} \;
        find "$ssh_dir" -type f -name "known_hosts*" -exec chmod 600 {} \;
        
        success "SSH keys configured"
    else
        warn "No SSH directory found at $HOME/.ssh"
        
        # Create minimal SSH config
        cat > "$ssh_dir/config" << EOF
# OpenHands Universal Development Environment SSH Config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET
    
Host github.com
    HostName github.com
    User git
    IdentitiesOnly yes
    
Host *.amazonaws.com
    StrictHostKeyChecking yes
EOF
        chmod 600 "$ssh_dir/config"
    fi
}

# AWS credentials setup with multiple methods
setup_aws_credentials() {
    info "Setting up AWS credentials..."
    
    local aws_dir="$OPENHANDS_BASE_DIR/aws"
    
    # Method 1: Copy existing AWS configuration
    if [[ -d "$HOME/.aws" ]]; then
        cp -r "$HOME/.aws"/* "$aws_dir/" 2>/dev/null || true
        chmod 600 "$aws_dir"/credentials* 2>/dev/null || true
        chmod 600 "$aws_dir"/config* 2>/dev/null || true
        success "Existing AWS credentials copied"
        return
    fi
    
    # Method 2: Check for environment variables
    if [[ -n "${AWS_ACCESS_KEY_ID:-}" ]] && [[ -n "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
        cat > "$aws_dir/credentials" << EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOF
        
        if [[ -n "${AWS_SESSION_TOKEN:-}" ]]; then
            echo "aws_session_token = ${AWS_SESSION_TOKEN}" >> "$aws_dir/credentials"
        fi
        
        cat > "$aws_dir/config" << EOF
[default]
region = ${AWS_REGION:-us-east-1}
output = json
EOF
        
        chmod 600 "$aws_dir/credentials"
        chmod 600 "$aws_dir/config"
        success "AWS credentials created from environment variables"
        return
    fi
    
    # Method 3: Create template
    warn "No AWS credentials found. Creating template..."
    cat > "$aws_dir/credentials" << 'EOF'
[default]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE
# aws_session_token = YOUR_SESSION_TOKEN_HERE  # Uncomment for temporary credentials

[bedrock-profile]
aws_access_key_id = YOUR_BEDROCK_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_BEDROCK_SECRET_KEY_HERE
EOF
    
    cat > "$aws_dir/config" << 'EOF'
[default]
region = us-east-1
output = json

[profile bedrock-profile]
region = us-east-1
output = json
EOF
    
    chmod 600 "$aws_dir/credentials"
    chmod 600 "$aws_dir/config"
    info "AWS credential templates created. Please edit $aws_dir/credentials with your actual credentials."
}

# Comprehensive configuration loading
load_configuration() {
    info "Loading configuration..."
    
    # Load from config file if it exists
    if [[ -f "$CONFIG_FILE" ]]; then
        info "Loading configuration from $CONFIG_FILE"
        set -a
        source "$CONFIG_FILE"
        set +a
    fi
    
    # Set intelligent defaults based on platform
    local platform
    platform=$(detect_platform)
    
    # Container runtime detection
    if [[ -z "${CONTAINER_RUNTIME:-}" ]]; then
        if command -v podman &> /dev/null; then
            export CONTAINER_RUNTIME="podman"
        elif command -v docker &> /dev/null; then
            export CONTAINER_RUNTIME="docker"
        else
            error "No container runtime found. Please install Podman or Docker."
        fi
    fi
    
    # Set default ports with conflict detection
    export HTTP_PORT="${HTTP_PORT:-3000}"
    export JUPYTER_PORT="${JUPYTER_PORT:-8888}"
    export CODE_SERVER_PORT="${CODE_SERVER_PORT:-8080}"
    export DEBUG_PORT="${DEBUG_PORT:-5000}"
    
    # Check for port conflicts
    check_port_conflicts
    
    # Platform-specific defaults
    case "$platform" in
        "wsl")
            export BIND_ADDRESS="${BIND_ADDRESS:-0.0.0.0}"
            export SOCKET_PATH="${SOCKET_PATH:-/run/user/$(id -u)/podman/podman.sock}"
            ;;
        "macos")
            export BIND_ADDRESS="${BIND_ADDRESS:-0.0.0.0}"
            export SOCKET_PATH="${SOCKET_PATH:-/var/run/docker.sock}"
            ;;
        *)
            export BIND_ADDRESS="${BIND_ADDRESS:-127.0.0.1}"
            export SOCKET_PATH="${SOCKET_PATH:-/run/user/$(id -u)/podman/podman.sock}"
            ;;
    esac
    
    # AWS Bedrock configuration
    setup_bedrock_config
    
    success "Configuration loaded successfully"
}

# Port conflict detection and resolution
check_port_conflicts() {
    local ports=("$HTTP_PORT" "$JUPYTER_PORT" "$CODE_SERVER_PORT" "$DEBUG_PORT")
    local conflicts=()
    
    for port in "${ports[@]}"; do
        if command -v ss &> /dev/null; then
            if ss -ln | grep -q ":$port "; then
                conflicts+=("$port")
            fi
        elif command -v netstat &> /dev/null; then
            if netstat -ln | grep -q ":$port "; then
                conflicts+=("$port")
            fi
        fi
    done
    
    if [[ ${#conflicts[@]} -gt 0 ]]; then
        warn "Port conflicts detected: ${conflicts[*]}"
        
        # Auto-resolve conflicts
        for conflict in "${conflicts[@]}"; do
            local new_port=$((conflict + 1000))
            
            case "$conflict" in
                "$HTTP_PORT") export HTTP_PORT="$new_port" ;;
                "$JUPYTER_PORT") export JUPYTER_PORT="$new_port" ;;
                "$CODE_SERVER_PORT") export CODE_SERVER_PORT="$new_port" ;;
                "$DEBUG_PORT") export DEBUG_PORT="$new_port" ;;
            esac
            
            info "Resolved port conflict: $conflict -> $new_port"
        done
    fi
}

# Enhanced Bedrock configuration
setup_bedrock_config() {
    info "Configuring AWS Bedrock integration..."
    
    # Check for Bedrock-specific environment variables
    if [[ -n "${AWS_BEDROCK_REGION:-}" ]]; then
        export AWS_REGION="${AWS_BEDROCK_REGION}"
    fi
    
    # Set Bedrock defaults
    export AWS_BEDROCK_REGION="${AWS_BEDROCK_REGION:-${AWS_REGION:-us-east-1}}"
    export AWS_BEDROCK_MODEL_ID="${AWS_BEDROCK_MODEL_ID:-anthropic.claude-3-sonnet-20240229-v1:0}"
    
    # Validate region for Bedrock availability
    local bedrock_regions=("us-east-1" "us-west-2" "eu-west-1" "ap-southeast-1" "ap-northeast-1")
    if [[ ! " ${bedrock_regions[*]} " =~ " ${AWS_BEDROCK_REGION} " ]]; then
        warn "AWS Bedrock may not be available in region: $AWS_BEDROCK_REGION"
        warn "Supported regions: ${bedrock_regions[*]}"
    fi
    
    # Create Bedrock test function
    cat > "$OPENHANDS_BASE_DIR/scripts/test-bedrock.sh" << 'EOF'
#!/bin/bash
echo "Testing AWS Bedrock connectivity..."

if command -v aws &> /dev/null; then
    if aws bedrock list-foundation-models --region "${AWS_BEDROCK_REGION:-us-east-1}" &> /dev/null; then
        echo "✓ AWS Bedrock is accessible"
        aws bedrock list-foundation-models --region "${AWS_BEDROCK_REGION:-us-east-1}" --output table
    else
        echo "✗ AWS Bedrock is not accessible"
        echo "Please check your AWS credentials and region configuration."
    fi
else
    echo "AWS CLI not found. Please install it to test Bedrock connectivity."
fi
EOF
    
    chmod +x "$OPENHANDS_BASE_DIR/scripts/test-bedrock.sh"
}

# Enhanced container image building
build_container_image() {
    info "Building universal development container..."
    
    local build_args=()
    
    # Add proxy settings if configured
    [[ -n "${HTTP_PROXY:-}" ]] && build_args+=(--build-arg "HTTP_PROXY=$HTTP_PROXY")
    [[ -n "${HTTPS_PROXY:-}" ]] && build_args+=(--build-arg "HTTPS_PROXY=$HTTPS_PROXY")
    [[ -n "${NO_PROXY:-}" ]] && build_args+=(--build-arg "NO_PROXY=$NO_PROXY")
    
    # Add registry settings
    [[ -n "${NPM_REGISTRY:-}" ]] && build_args+=(--build-arg "NPM_REGISTRY=$NPM_REGISTRY")
    [[ -n "${PIP_INDEX_URL:-}" ]] && build_args+=(--build-arg "PIP_INDEX_URL=$PIP_INDEX_URL")
    [[ -n "${MAVEN_REPOSITORY_URL:-}" ]] && build_args+=(--build-arg "MAVEN_REPOSITORY_URL=$MAVEN_REPOSITORY_URL")
    
    # Build the image
    if ! $CONTAINER_RUNTIME build \
        -t "$IMAGE_NAME" \
        -f "$SCRIPT_DIR/UniversalContainerfile" \
        "${build_args[@]}" \
        "$SCRIPT_DIR"; then
        error "Failed to build container image"
    fi
    
    success "Container image built successfully: $IMAGE_NAME"
}

# Smart container execution with platform optimization
run_container() {
    info "Starting universal development environment..."
    
    local platform
    platform=$(detect_platform)
    
    # Base run arguments
    local run_args=(
        --name "$CONTAINER_NAME"
        --rm
        --interactive
        --tty
        --hostname "openhands-dev"
        --env "TERM=${TERM:-xterm-256color}"
        --env "PLATFORM=$platform"
    )
    
    # Volume mounts
    run_args+=(
        --volume "$OPENHANDS_BASE_DIR/workspace:/workspace:Z"
        --volume "$OPENHANDS_BASE_DIR/config:/config:Z"
        --volume "$OPENHANDS_BASE_DIR/cache:/cache:Z"
        --volume "$OPENHANDS_BASE_DIR/certs:/certs:ro,Z"
        --volume "$OPENHANDS_BASE_DIR/ssh:/home/developer/.ssh:ro,Z"
        --volume "$OPENHANDS_BASE_DIR/aws:/home/developer/.aws:ro,Z"
        --volume "$OPENHANDS_BASE_DIR/logs:/logs:Z"
    )
    
    # Port mappings
    run_args+=(
        --publish "$HTTP_PORT:3000"
        --publish "$JUPYTER_PORT:8888"
        --publish "$CODE_SERVER_PORT:8080"
        --publish "$DEBUG_PORT:5000"
    )
    
    # Environment variables
    local env_vars=(
        "HTTP_PROXY" "HTTPS_PROXY" "NO_PROXY"
        "AWS_PROFILE" "AWS_REGION" "AWS_BEDROCK_REGION" "AWS_BEDROCK_MODEL_ID"
        "GITHUB_TOKEN" "GITHUB_ENTERPRISE_URL"
        "GIT_USER_NAME" "GIT_USER_EMAIL"
        "NPM_REGISTRY" "PIP_INDEX_URL"
    )
    
    for var in "${env_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            run_args+=(--env "$var=${!var}")
        fi
    done
    
    # Platform-specific configurations
    case "$platform" in
        "wsl")
            run_args+=(--env "WSL_DISTRO_NAME=${WSL_DISTRO_NAME:-Ubuntu}")
            # Better network configuration for WSL2
            run_args+=(--add-host "host.docker.internal:host-gateway")
            ;;
        "macos")
            if [[ -S "/var/run/docker.sock" ]]; then
                run_args+=(--volume "/var/run/docker.sock:/var/run/docker.sock:Z")
            fi
            ;;
    esac
    
    # Security context
    run_args+=(
        --security-opt "seccomp=unconfined"
        --cap-add "SYS_PTRACE"
        --env "SANDBOX_USER_ID=$(id -u)"
        --env "SANDBOX_GROUP_ID=$(id -g)"
    )
    
    # Execute container
    info "Starting container with the following configuration:"
    info "  HTTP Server: http://localhost:$HTTP_PORT"
    info "  Jupyter Lab: http://localhost:$JUPYTER_PORT"
    info "  Code Server: http://localhost:$CODE_SERVER_PORT"
    info "  Debug Port: $DEBUG_PORT"
    info "  Workspace: $OPENHANDS_BASE_DIR/workspace"
    
    exec $CONTAINER_RUNTIME run "${run_args[@]}" "$IMAGE_NAME" "$@"
}

# Generate comprehensive configuration file
generate_config_template() {
    info "Generating configuration template..."
    
    cat > "$CONFIG_FILE" << 'EOF'
# Universal Development Environment Configuration
# Copy this file to .universal-dev.env and customize

# =============================================================================
# CONTAINER RUNTIME
# =============================================================================
CONTAINER_RUNTIME=podman

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================
HTTP_PORT=3000
JUPYTER_PORT=8888
CODE_SERVER_PORT=8080
DEBUG_PORT=5000
BIND_ADDRESS=0.0.0.0

# =============================================================================
# PROXY SETTINGS (Enterprise environments)
# =============================================================================
#HTTP_PROXY=http://proxy.company.com:8080
#HTTPS_PROXY=http://proxy.company.com:8080
#NO_PROXY=localhost,127.0.0.1,.company.com,.local

# =============================================================================
# PACKAGE REGISTRIES
# =============================================================================
#NPM_REGISTRY=https://artifactory.company.com/npm/
#PIP_INDEX_URL=https://artifactory.company.com/pypi/simple/
#MAVEN_REPOSITORY_URL=https://artifactory.company.com/maven/

# =============================================================================
# AWS CONFIGURATION
# =============================================================================
#AWS_PROFILE=default
#AWS_REGION=us-east-1
#AWS_BEDROCK_REGION=us-east-1
#AWS_BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

# For direct credential configuration (not recommended - use AWS profiles instead):
#AWS_ACCESS_KEY_ID=your_access_key
#AWS_SECRET_ACCESS_KEY=your_secret_key
#AWS_SESSION_TOKEN=your_session_token

# =============================================================================
# GIT CONFIGURATION
# =============================================================================
#GIT_USER_NAME="Your Name"
#GIT_USER_EMAIL="your.email@company.com"
#GITHUB_TOKEN=ghp_your_token
#GITHUB_ENTERPRISE_URL=https://github.company.com/api/v3

# =============================================================================
# DEVELOPMENT SETTINGS
# =============================================================================
#JAVA_OPTS="-Xmx4g -Xms1g"
#NODE_OPTIONS="--max-old-space-size=8192"
#PYTHON_ENV=development

# =============================================================================
# SECURITY SETTINGS
# =============================================================================
#SSL_VERIFY=true
#DISABLE_SSL_VERIFICATION=false

# =============================================================================
# DEBUGGING
# =============================================================================
#DEBUG=false
#VERBOSE_LOGGING=false
EOF
    
    success "Configuration template created: $CONFIG_FILE"
    info "Please edit this file with your specific settings before running the environment."
}

# Health check and validation
validate_environment() {
    info "Validating environment setup..."
    
    local issues=()
    
    # Check container runtime
    if ! command -v "$CONTAINER_RUNTIME" &> /dev/null; then
        issues+=("Container runtime '$CONTAINER_RUNTIME' not found")
    fi
    
    # Check directories
    if [[ ! -d "$OPENHANDS_BASE_DIR" ]]; then
        issues+=("Base directory not found: $OPENHANDS_BASE_DIR")
    fi
    
    # Check AWS configuration
    if [[ -f "$OPENHANDS_BASE_DIR/aws/credentials" ]]; then
        if grep -q "YOUR_ACCESS_KEY_HERE" "$OPENHANDS_BASE_DIR/aws/credentials"; then
            issues+=("AWS credentials not configured - still contains placeholder values")
        fi
    fi
    
    # Check port availability
    check_port_conflicts
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        warn "Environment validation found issues:"
        for issue in "${issues[@]}"; do
            warn "  - $issue"
        done
        return 1
    fi
    
    success "Environment validation passed"
    return 0
}

# Cleanup function
cleanup() {
    info "Cleaning up..."
    
    # Stop running container
    if $CONTAINER_RUNTIME ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        info "Stopping container: $CONTAINER_NAME"
        $CONTAINER_RUNTIME stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
    
    # Clean up images if requested
    if [[ "${CLEAN_IMAGES:-false}" == "true" ]]; then
        info "Removing container image: $IMAGE_NAME"
        $CONTAINER_RUNTIME rmi "$IMAGE_NAME" >/dev/null 2>&1 || true
    fi
}

# Help function
show_help() {
    cat << EOF
Universal Development Environment for OpenHands v$DEV_ENV_VERSION

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    start           Start the development environment (default)
    build           Build the container image only
    clean           Remove containers and optionally images
    config          Generate configuration template
    validate        Validate environment setup
    shell           Start container with shell access
    help            Show this help message

OPTIONS:
    --rebuild       Force rebuild of container image
    --clean-images  Remove images during cleanup
    --debug         Enable debug output
    --config FILE   Use custom configuration file

EXAMPLES:
    $0 start                    # Start with default configuration
    $0 start --rebuild          # Force rebuild and start
    $0 build                    # Build container image only
    $0 config                   # Generate configuration template
    $0 clean --clean-images     # Full cleanup including images

CONFIGURATION:
    Configuration is loaded from .universal-dev.env in the script directory.
    Run '$0 config' to generate a template configuration file.

AWS BEDROCK SETUP:
    1. Configure AWS credentials in ~/.aws/ or environment variables
    2. Set AWS_BEDROCK_REGION (default: us-east-1)
    3. Set AWS_BEDROCK_MODEL_ID (default: anthropic.claude-3-sonnet-20240229-v1:0)
    4. Test with: ./test-bedrock.sh (created in base directory)

TROUBLESHOOTING:
    - Run with --debug for detailed output
    - Check logs in: \$BASE_DIR/logs/
    - Validate setup: $0 validate

For more information, see TROUBLESHOOTING.md
EOF
}

# Main execution function
main() {
    local command="${1:-start}"
    local rebuild=false
    local debug=false
    local custom_config=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --rebuild)
                rebuild=true
                shift
                ;;
            --clean-images)
                export CLEAN_IMAGES=true
                shift
                ;;
            --debug)
                debug=true
                set -x
                shift
                ;;
            --config)
                custom_config="$2"
                shift 2
                ;;
            -h|--help|help)
                show_help
                exit 0
                ;;
            start|build|clean|config|validate|shell)
                command="$1"
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Override config file if specified
    if [[ -n "$custom_config" ]]; then
        CONFIG_FILE="$custom_config"
    fi
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Detect platform early
    local platform
    platform=$(detect_platform)
    
    case "$command" in
        "config")
            generate_config_template
            ;;
        "validate")
            setup_directories
            load_configuration
            validate_environment
            ;;
        "build")
            check_podman
            setup_directories
            setup_certificates
            load_configuration
            build_container_image
            ;;
        "clean")
            cleanup
            info "Cleanup complete"
            ;;
        "shell")
            check_podman
            setup_directories
            setup_certificates
            setup_ssh_keys
            setup_aws_credentials
            load_configuration
            
            if [[ "$rebuild" == true ]] || ! $CONTAINER_RUNTIME image exists "$IMAGE_NAME"; then
                build_container_image
            fi
            
            run_container /bin/bash
            ;;
        "start")
            info "Starting Universal Development Environment v$DEV_ENV_VERSION"
            
            check_podman
            setup_directories
            setup_certificates
            setup_ssh_keys
            setup_aws_credentials
            load_configuration
            
            if ! validate_environment; then
                error "Environment validation failed. Please fix the issues above."
            fi
            
            if [[ "$rebuild" == true ]] || ! $CONTAINER_RUNTIME image exists "$IMAGE_NAME"; then
                build_container_image
            fi
            
            run_container "$@"
            ;;
        *)
            error "Unknown command: $command. Use 'help' for usage information."
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF