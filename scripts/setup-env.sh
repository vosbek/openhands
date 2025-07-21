#!/bin/bash

set -euo pipefail

echo "🔧 Universal Development Environment Setup"
echo "=========================================="

# Function to install additional Python packages
install_python_packages() {
    local packages="${EXTRA_PYTHON_PACKAGES:-}"
    if [ -n "$packages" ]; then
        echo "📦 Installing additional Python packages: $packages"
        python -m pip install --user $packages
        echo "✓ Python packages installed"
    fi
}

# Function to install additional NPM packages
install_npm_packages() {
    local packages="${EXTRA_NPM_PACKAGES:-}"
    if [ -n "$packages" ]; then
        echo "📦 Installing additional NPM packages: $packages"
        npm install -g $packages
        echo "✓ NPM packages installed"
    fi
}

# Function to install additional system packages
install_system_packages() {
    local packages="${EXTRA_APT_PACKAGES:-}"
    if [ -n "$packages" ]; then
        echo "📦 Installing additional system packages: $packages"
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y $packages >/dev/null 2>&1
        sudo rm -rf /var/lib/apt/lists/*
        echo "✓ System packages installed"
    fi
}

# Function to configure Maven settings
configure_maven() {
    local maven_repo="${MAVEN_REPOSITORY_URL:-}"
    if [ -n "$maven_repo" ]; then
        echo "🔧 Configuring Maven repository: $maven_repo"
        mkdir -p ~/.m2
        cat > ~/.m2/settings.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
    <mirrors>
        <mirror>
            <id>enterprise-repo</id>
            <name>Enterprise Repository</name>
            <url>$maven_repo</url>
            <mirrorOf>central</mirrorOf>
        </mirror>
    </mirrors>
    
    <proxies>
EOF

        if [ -n "${HTTP_PROXY:-}" ]; then
            local proxy_host proxy_port
            proxy_host=$(echo "$HTTP_PROXY" | sed 's|http://||' | cut -d: -f1)
            proxy_port=$(echo "$HTTP_PROXY" | sed 's|http://||' | cut -d: -f2 | cut -d/ -f1)
            
            cat >> ~/.m2/settings.xml << EOF
        <proxy>
            <id>http-proxy</id>
            <active>true</active>
            <protocol>http</protocol>
            <host>$proxy_host</host>
            <port>$proxy_port</port>
        </proxy>
EOF
        fi

        cat >> ~/.m2/settings.xml << EOF
    </proxies>
</settings>
EOF
        echo "✓ Maven configured"
    fi
}

# Function to set up development workspace
setup_workspace() {
    echo "📁 Setting up development workspace structure..."
    
    mkdir -p /workspace/{
        projects/{java,python,nodejs,scripts},
        data/{input,output,temp},
        docs/{notes,references},
        config/{local,templates}
    }
    
    # Create useful template files
    cat > /workspace/config/templates/README.md << 'EOF'
# Project Name

## Description
Brief description of your project.

## Setup
1. Clone the repository
2. Install dependencies
3. Run the application

## Usage
Instructions on how to use the project.

## Contributing
Guidelines for contributing to the project.

## License
License information.
EOF

    cat > /workspace/config/templates/.gitignore << 'EOF'
# Compiled class file
*.class

# Log file
*.log

# BlueJ files
*.ctxt

# Mobile Tools for Java (J2ME)
.mtj.tmp/

# Package Files #
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# Virtual environments
venv/
env/
.env
.venv

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Node modules
node_modules/
npm-debug.log*

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Jupyter Notebook
.ipynb_checkpoints

# pytest
.pytest_cache/

# Coverage reports
htmlcov/
.tox/
.coverage
.coverage.*
.cache
.pytest_cache/
EOF

    echo "✓ Workspace structure created"
}

# Function to create useful aliases and functions
create_dev_shortcuts() {
    echo "⚡ Creating development shortcuts..."
    
    cat >> ~/.bashrc << 'EOF'

# Additional development shortcuts added by setup script
alias cdp='cd /workspace/projects'
alias cdd='cd /workspace/data'
alias cdn='cd /workspace/docs/notes'

# Quick project creation functions
create-java-project() {
    local name="${1:-my-java-project}"
    cd /workspace/projects/java
    mvn archetype:generate -DgroupId=com.example -DartifactId="$name" -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
    cd "$name"
    echo "✓ Java project '$name' created"
}

create-python-project() {
    local name="${1:-my-python-project}"
    mkdir -p "/workspace/projects/python/$name"
    cd "/workspace/projects/python/$name"
    python -m venv venv
    source venv/bin/activate
    pip install pytest black flake8
    echo "# $name" > README.md
    echo "def hello_world():" > main.py
    echo "    return 'Hello, World!'" >> main.py
    echo "✓ Python project '$name' created"
}

create-node-project() {
    local name="${1:-my-node-project}"
    mkdir -p "/workspace/projects/nodejs/$name"
    cd "/workspace/projects/nodejs/$name"
    npm init -y
    npm install --save-dev jest
    echo "console.log('Hello, World!');" > index.js
    echo "✓ Node.js project '$name' created"
}

# Git workflow shortcuts
git-quick-commit() {
    local message="${1:-Quick commit}"
    git add .
    git commit -m "$message"
}

git-sync() {
    git pull --rebase
    git push
}

# AWS shortcuts
aws-bedrock-test() {
    local region="${AWS_BEDROCK_REGION:-us-east-1}"
    aws bedrock list-foundation-models --region "$region" 2>/dev/null | jq '.modelSummaries[].modelName' || echo "Bedrock not accessible"
}

# Container shortcuts
restart-jupyter() {
    pkill -f jupyter || true
    nohup jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=/workspace > /tmp/jupyter.log 2>&1 &
    echo "✓ Jupyter Lab restarted on port 8888"
}

# System info shortcuts
dev-info() {
    echo "🖥️  Development Environment Information"
    echo "======================================"
    echo "Platform: ${DEV_ENV_PLATFORM:-unknown}"
    echo "User: $(whoami)"
    echo "PWD: $(pwd)"
    echo "Disk Usage: $(df -h /workspace | tail -n 1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
    echo "Memory Usage: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
    echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    echo "🔧 Tool Versions:"
    echo "Java: $(java -version 2>&1 | head -n 1 | cut -d'"' -f2)"
    echo "Python: $(python --version | cut -d' ' -f2)"
    echo "Node.js: $(node --version)"
    echo "Maven: $(mvn --version | head -n 1 | cut -d' ' -f3)"
    echo "Git: $(git --version | cut -d' ' -f3)"
    echo ""
    echo "🌐 Network:"
    [ -n "${HTTP_PROXY:-}" ] && echo "HTTP Proxy: $HTTP_PROXY"
    [ -n "${HTTPS_PROXY:-}" ] && echo "HTTPS Proxy: $HTTPS_PROXY"
    echo "NPM Registry: $(npm config get registry)"
    echo "PIP Index: $(pip config list | grep index-url || echo 'Default')"
}

# Backup shortcuts
backup-workspace() {
    local backup_dir="${BACKUP_DIR:-/workspace/backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$backup_dir"
    tar -czf "$backup_dir/workspace_backup_$timestamp.tar.gz" -C /workspace projects data docs
    echo "✓ Workspace backed up to $backup_dir/workspace_backup_$timestamp.tar.gz"
}

EOF

    echo "✓ Development shortcuts created"
}

# Function to configure health monitoring
setup_monitoring() {
    echo "📊 Setting up environment monitoring..."
    
    cat > /usr/local/bin/dev-health-check << 'EOF'
#!/bin/bash
echo "$(date): Development Environment Health Check"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h /workspace | tail -n 1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Processes: $(ps aux | wc -l)"
echo "---"
EOF
    
    chmod +x /usr/local/bin/dev-health-check
    echo "✓ Health monitoring configured"
}

# Main execution
main() {
    echo "Starting environment setup..."
    
    install_system_packages
    install_python_packages
    install_npm_packages
    configure_maven
    setup_workspace
    create_dev_shortcuts
    setup_monitoring
    
    echo ""
    echo "🎉 Environment setup complete!"
    echo ""
    echo "🚀 Quick start commands have been added:"
    echo "  create-java-project [name]    - Create new Java project"
    echo "  create-python-project [name]  - Create new Python project"
    echo "  create-node-project [name]    - Create new Node.js project"
    echo "  dev-info                      - Show environment information"
    echo "  backup-workspace              - Backup workspace data"
    echo "  restart-jupyter               - Restart Jupyter Lab"
    echo ""
    echo "📁 Workspace directories:"
    echo "  /workspace/projects/          - Your development projects"
    echo "  /workspace/data/              - Data files and datasets"
    echo "  /workspace/docs/              - Documentation and notes"
    echo "  /workspace/config/templates/  - Project templates"
    echo ""
    echo "Source your .bashrc to load new shortcuts:"
    echo "  source ~/.bashrc"
}

# Run main function
main "$@"