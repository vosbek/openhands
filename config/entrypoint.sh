#!/bin/bash

set -euo pipefail

echo "🚀 Starting Universal Development Environment..."

# Configure Git if environment variables are set
if [ -n "${GIT_USER_NAME:-}" ]; then
    git config --global user.name "$GIT_USER_NAME"
    echo "✓ Git user.name set to: $GIT_USER_NAME"
fi

if [ -n "${GIT_USER_EMAIL:-}" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
    echo "✓ Git user.email set to: $GIT_USER_EMAIL"
fi

# Configure NPM registry if custom registry is specified
if [ -n "${NPM_REGISTRY:-}" ] && [ "$NPM_REGISTRY" != "https://registry.npmjs.org/" ]; then
    npm config set registry "$NPM_REGISTRY"
    echo "✓ NPM registry set to: $NPM_REGISTRY"
fi

# Configure NPM proxy settings if specified
if [ -n "${HTTP_PROXY:-}" ]; then
    npm config set proxy "$HTTP_PROXY"
    echo "✓ NPM HTTP proxy set to: $HTTP_PROXY"
fi

if [ -n "${HTTPS_PROXY:-}" ]; then
    npm config set https-proxy "$HTTPS_PROXY"
    echo "✓ NPM HTTPS proxy set to: $HTTPS_PROXY"
fi

# Update certificate store if custom certificates are available
if [ -d "/certs" ] && [ "$(ls -A /certs 2>/dev/null)" ]; then
    echo "🔒 Updating certificate store..."
    sudo cp -r /certs/* /usr/local/share/ca-certificates/ 2>/dev/null || true
    sudo update-ca-certificates >/dev/null 2>&1 || true
    echo "✓ Certificate store updated"
fi

# Set up AWS CLI configuration if AWS directory is mounted
if [ -d "/home/developer/.aws" ] && [ -n "${AWS_REGION:-}" ]; then
    aws configure set region "$AWS_REGION" >/dev/null 2>&1 || true
    echo "✓ AWS region set to: $AWS_REGION"
fi

# Set up SSH permissions if SSH directory is mounted
if [ -d "/home/developer/.ssh" ]; then
    chmod 700 /home/developer/.ssh
    find /home/developer/.ssh -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
    find /home/developer/.ssh -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
    echo "✓ SSH permissions configured"
fi

# Create workspace directories if they don't exist
mkdir -p /workspace/{projects,scripts,data,docs}
mkdir -p /config/{user,system}
mkdir -p /cache/{pip,npm,maven}

# Set ownership of user directories
sudo chown -R developer:developer /home/developer 2>/dev/null || true

# Configure Jupyter if starting Jupyter Lab
if [[ "${1:-}" == *"jupyter"* ]] || [[ "${1:-}" == *"lab"* ]]; then
    echo "🔬 Configuring Jupyter Lab..."
    
    # Generate Jupyter config if it doesn't exist
    if [ ! -f "/home/developer/.jupyter/jupyter_lab_config.py" ]; then
        mkdir -p /home/developer/.jupyter
        cat > /home/developer/.jupyter/jupyter_lab_config.py << 'EOF'
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.root_dir = '/workspace'
c.LabApp.default_url = '/lab'
EOF
        echo "✓ Jupyter Lab configuration created"
    fi
fi

# Start health check service in background if running interactively
if [[ "${1:-}" == "/bin/bash" ]] || [[ "${1:-}" == "bash" ]] || [ $# -eq 0 ]; then
    # Start a simple health check service
    (
        while true; do
            echo "$(date): Development environment healthy" > /tmp/health.log
            sleep 30
        done
    ) &
fi

# Print environment information
echo ""
echo "🌟 Environment Ready!"
echo "================================"
echo "Platform: ${DEV_ENV_PLATFORM:-unknown}"
echo "User: $(whoami)"
echo "Home: $HOME"
echo "Workspace: /workspace"
echo "Config: /config"
echo "Cache: /cache"
echo ""

# Show available tools
echo "📦 Available Tools:"
echo "  - Java: $(java -version 2>&1 | head -n 1 | cut -d'"' -f2)"
echo "  - Python: $(python --version | cut -d' ' -f2)"
echo "  - Node.js: $(node --version)"
echo "  - NPM: $(npm --version)"
echo "  - Maven: $(mvn --version | head -n 1 | cut -d' ' -f3)"
echo "  - Git: $(git --version | cut -d' ' -f3)"
echo "  - AWS CLI: $(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)"
echo ""

# Show network configuration if proxy is set
if [ -n "${HTTP_PROXY:-}" ] || [ -n "${HTTPS_PROXY:-}" ]; then
    echo "🌐 Proxy Configuration:"
    [ -n "${HTTP_PROXY:-}" ] && echo "  HTTP Proxy: $HTTP_PROXY"
    [ -n "${HTTPS_PROXY:-}" ] && echo "  HTTPS Proxy: $HTTPS_PROXY"
    [ -n "${NO_PROXY:-}" ] && echo "  No Proxy: $NO_PROXY"
    echo ""
fi

# Show AWS configuration if available
if [ -n "${AWS_PROFILE:-}" ] || [ -n "${AWS_REGION:-}" ]; then
    echo "☁️  AWS Configuration:"
    [ -n "${AWS_PROFILE:-}" ] && echo "  Profile: $AWS_PROFILE"
    [ -n "${AWS_REGION:-}" ] && echo "  Region: $AWS_REGION"
    [ -n "${AWS_BEDROCK_REGION:-}" ] && echo "  Bedrock Region: $AWS_BEDROCK_REGION"
    echo ""
fi

# Show quick start commands
echo "🚀 Quick Start Commands:"
echo "  jl                    - Start Jupyter Lab"
echo "  code /workspace       - Open VS Code (if code-server is running)"
echo "  git clone <repo>      - Clone a repository"
echo "  mvn archetype:generate - Create new Maven project"
echo "  npm create <template> - Create new Node.js project"
echo ""

echo "Ready for development! 🎉"
echo ""

# Execute the provided command or start bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    exec "$@"
fi