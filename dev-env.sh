#!/bin/bash

set -euo pipefail

DEV_ENV_VERSION="1.0.0"
CONTAINER_NAME="universal-dev-env"
IMAGE_NAME="universal-dev:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

detect_platform() {
    local platform=""
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            platform="wsl"
        elif grep -qi ubuntu /etc/os-release 2>/dev/null; then
            platform="ubuntu"
        else
            platform="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        platform="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        platform="windows"
    else
        platform="unknown"
    fi
    
    echo "$platform"
}

check_podman() {
    if ! command -v podman &> /dev/null; then
        error "Podman is not installed. Please install Podman first."
    fi
    
    if ! podman info &> /dev/null; then
        error "Podman is not running or not configured properly."
    fi
    
    info "Podman check passed"
}

setup_directories() {
    local dirs=(
        "$HOME/.dev-env/data"
        "$HOME/.dev-env/config"
        "$HOME/.dev-env/cache"
        "$HOME/.dev-env/certs"
        "$HOME/.dev-env/ssh"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        info "Created directory: $dir"
    done
}

copy_certificates() {
    local cert_dir="$HOME/.dev-env/certs"
    local platform
    platform=$(detect_platform)
    
    case "$platform" in
        "ubuntu"|"linux"|"wsl")
            if [[ -d "/etc/ssl/certs" ]]; then
                cp -r /etc/ssl/certs/* "$cert_dir/" 2>/dev/null || true
            fi
            if [[ -d "/usr/local/share/ca-certificates" ]]; then
                cp -r /usr/local/share/ca-certificates/* "$cert_dir/" 2>/dev/null || true
            fi
            ;;
        "macos")
            if command -v security &> /dev/null; then
                security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > "$cert_dir/system-certs.pem" 2>/dev/null || true
            fi
            ;;
    esac
    
    info "Certificates copied to $cert_dir"
}

load_config() {
    local config_file="$SCRIPT_DIR/.env"
    if [[ -f "$config_file" ]]; then
        info "Loading configuration from $config_file"
        set -a
        source "$config_file"
        set +a
    else
        warn "Configuration file $config_file not found. Using defaults."
    fi
}

build_image() {
    local dockerfile="$SCRIPT_DIR/Containerfile"
    
    if [[ ! -f "$dockerfile" ]]; then
        error "Containerfile not found at $dockerfile"
    fi
    
    info "Building container image: $IMAGE_NAME"
    
    local build_args=()
    
    if [[ -n "${HTTP_PROXY:-}" ]]; then
        build_args+=(--build-arg "HTTP_PROXY=$HTTP_PROXY")
    fi
    
    if [[ -n "${HTTPS_PROXY:-}" ]]; then
        build_args+=(--build-arg "HTTPS_PROXY=$HTTPS_PROXY")
    fi
    
    if [[ -n "${NO_PROXY:-}" ]]; then
        build_args+=(--build-arg "NO_PROXY=$NO_PROXY")
    fi
    
    if [[ -n "${NPM_REGISTRY:-}" ]]; then
        build_args+=(--build-arg "NPM_REGISTRY=$NPM_REGISTRY")
    fi
    
    if [[ -n "${PIP_INDEX_URL:-}" ]]; then
        build_args+=(--build-arg "PIP_INDEX_URL=$PIP_INDEX_URL")
    fi
    
    podman build \
        -t "$IMAGE_NAME" \
        -f "$dockerfile" \
        "${build_args[@]}" \
        "$SCRIPT_DIR" || error "Failed to build container image"
    
    info "Container image built successfully"
}

setup_ssh() {
    local ssh_dir="$HOME/.dev-env/ssh"
    
    if [[ -d "$HOME/.ssh" ]]; then
        cp -r "$HOME/.ssh"/* "$ssh_dir/" 2>/dev/null || true
        chmod 700 "$ssh_dir"
        find "$ssh_dir" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \;
        find "$ssh_dir" -type f -name "*.pub" -exec chmod 644 {} \;
        info "SSH keys copied to $ssh_dir"
    else
        warn "No SSH directory found at $HOME/.ssh"
    fi
}

run_container() {
    local platform
    platform=$(detect_platform)
    
    local run_args=(
        --name "$CONTAINER_NAME"
        --rm
        -it
        --hostname "dev-env"
        -v "$HOME/.dev-env/data:/workspace:Z"
        -v "$HOME/.dev-env/config:/config:Z"
        -v "$HOME/.dev-env/cache:/cache:Z"
        -v "$HOME/.dev-env/certs:/certs:ro,Z"
        -v "$HOME/.dev-env/ssh:/home/developer/.ssh:ro,Z"
        -e "TERM=${TERM:-xterm-256color}"
        -e "DEV_ENV_PLATFORM=$platform"
    )
    
    if [[ -n "${HTTP_PROXY:-}" ]]; then
        run_args+=(-e "HTTP_PROXY=$HTTP_PROXY")
        run_args+=(-e "http_proxy=$HTTP_PROXY")
    fi
    
    if [[ -n "${HTTPS_PROXY:-}" ]]; then
        run_args+=(-e "HTTPS_PROXY=$HTTPS_PROXY")
        run_args+=(-e "https_proxy=$HTTPS_PROXY")
    fi
    
    if [[ -n "${NO_PROXY:-}" ]]; then
        run_args+=(-e "NO_PROXY=$NO_PROXY")
        run_args+=(-e "no_proxy=$NO_PROXY")
    fi
    
    if [[ -n "${AWS_PROFILE:-}" ]]; then
        run_args+=(-e "AWS_PROFILE=$AWS_PROFILE")
    fi
    
    if [[ -n "${AWS_REGION:-}" ]]; then
        run_args+=(-e "AWS_REGION=$AWS_REGION")
    fi
    
    if [[ -d "$HOME/.aws" ]]; then
        run_args+=(-v "$HOME/.aws:/home/developer/.aws:ro,Z")
    fi
    
    if [[ "$platform" == "macos" ]] && [[ -S "/var/run/docker.sock" ]]; then
        run_args+=(-v "/var/run/docker.sock:/var/run/docker.sock:Z")
    fi
    
    info "Starting development container"
    podman run "${run_args[@]}" "$IMAGE_NAME" "$@"
}

cleanup() {
    info "Cleaning up..."
    if podman ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        podman stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
}

show_help() {
    cat << EOF
Universal Development Environment v$DEV_ENV_VERSION

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    start       Start the development environment (default)
    build       Build the container image only
    clean       Remove container and image
    shell       Start container with shell access
    help        Show this help message

Options:
    --rebuild   Force rebuild of container image
    --debug     Enable debug output

Environment Configuration:
    Create a .env file in the same directory as this script to configure:
    - HTTP_PROXY, HTTPS_PROXY, NO_PROXY
    - NPM_REGISTRY, PIP_INDEX_URL
    - AWS_PROFILE, AWS_REGION

Supported Platforms:
    - Windows with WSL2
    - Ubuntu (native)
    - AWS Workspaces Ubuntu
    - macOS

Requirements:
    - Podman installed and running
    - Internet access (for initial setup)

For troubleshooting, see the troubleshooting guide.
EOF
}

main() {
    local command="${1:-start}"
    local rebuild=false
    local debug=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --rebuild)
                rebuild=true
                shift
                ;;
            --debug)
                debug=true
                set -x
                shift
                ;;
            -h|--help|help)
                show_help
                exit 0
                ;;
            start|build|clean|shell)
                command="$1"
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    trap cleanup EXIT
    
    local platform
    platform=$(detect_platform)
    info "Detected platform: $platform"
    
    case "$command" in
        "build")
            check_podman
            load_config
            build_image
            ;;
        "clean")
            check_podman
            info "Cleaning up containers and images"
            podman rm -f "$CONTAINER_NAME" 2>/dev/null || true
            podman rmi -f "$IMAGE_NAME" 2>/dev/null || true
            info "Cleanup complete"
            ;;
        "shell")
            check_podman
            load_config
            setup_directories
            copy_certificates
            setup_ssh
            
            if [[ "$rebuild" == true ]] || ! podman image exists "$IMAGE_NAME"; then
                build_image
            fi
            
            run_container /bin/bash
            ;;
        "start")
            check_podman
            load_config
            setup_directories
            copy_certificates
            setup_ssh
            
            if [[ "$rebuild" == true ]] || ! podman image exists "$IMAGE_NAME"; then
                build_image
            fi
            
            run_container "$@"
            ;;
        *)
            error "Unknown command: $command. Use 'help' for usage information."
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi