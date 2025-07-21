# Universal Development Environment for Windows PowerShell + Podman
# Bulletproof cross-platform setup with enterprise support
# Version: 2.0.0

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet("start", "build", "clean", "config", "validate", "shell", "help")]
    [string]$Command = "start",
    
    [switch]$Rebuild,
    [switch]$CleanImages,
    [switch]$Debug,
    [string]$ConfigFile = ""
)

# Script configuration
$Script:DEV_ENV_VERSION = "2.0.0"
$Script:CONTAINER_NAME = "openhands-universal-dev"
$Script:IMAGE_NAME = "openhands-universal-dev:latest"
$Script:SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:PROJECT_DIR = Split-Path -Parent $Script:SCRIPT_DIR
$Script:CONFIG_FILE = if ($ConfigFile) { $ConfigFile } else { Join-Path $Script:PROJECT_DIR ".universal-dev.env" }

# Logging functions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }  
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] $Level`: $Message" -ForegroundColor $color
}

function Write-Info { param([string]$Message) Write-Log $Message "INFO" }
function Write-Warn { param([string]$Message) Write-Log $Message "WARN" }
function Write-Error { param([string]$Message) Write-Log $Message "ERROR" }
function Write-Success { param([string]$Message) Write-Log $Message "SUCCESS" }

# Platform detection for Windows
function Test-WindowsEnvironment {
    Write-Info "Detecting Windows environment..."
    
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $windowsVersion = $osInfo.Version
    $buildNumber = $osInfo.BuildNumber
    
    Write-Info "Windows Version: $($osInfo.Caption)"
    Write-Info "Build Number: $buildNumber"
    
    # Check if running in PowerShell (not WSL)
    if ($env:WSL_DISTRO_NAME) {
        Write-Error "You're running in WSL. Use the bash version: universal-dev-env.sh"
        exit 1
    }
    
    # Check for Windows 10/11 with container support
    if ($buildNumber -lt 19041) {
        Write-Warn "Windows build $buildNumber may have limited container support. Recommended: 19041+"
    }
    
    Write-Success "Windows environment verified"
}

# Enhanced Podman verification for Windows
function Test-PodmanInstallation {
    Write-Info "Verifying Podman installation..."
    
    # Check if Podman is installed
    try {
        $podmanVersion = & podman --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Podman not found"
        }
        Write-Success "Podman found: $podmanVersion"
    }
    catch {
        Write-Error "Podman is not installed or not in PATH"
        Write-Info "Install Podman Desktop from: https://podman-desktop.io/"
        Write-Info "Or use Winget: winget install podman"
        exit 1
    }
    
    # Check if Podman is functional
    try {
        $podmanInfo = & podman info --format json 2>$null | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) {
            throw "Podman not functional"
        }
        
        $machineState = $podmanInfo.host.remoteSocket.exists
        if (-not $machineState) {
            Write-Warn "Podman machine may not be running"
            Write-Info "Starting Podman machine..."
            & podman machine start 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Warn "Could not start Podman machine automatically"
                Write-Info "Try: podman machine init && podman machine start"
            }
        }
        
        Write-Success "Podman verification complete"
    }
    catch {
        Write-Error "Podman is installed but not functional: $_"
        Write-Info "Try: podman machine init && podman machine start"
        exit 1
    }
}

# Smart directory setup for Windows
function Initialize-Directories {
    Write-Info "Setting up directory structure..."
    
    # Use Windows-appropriate paths
    $baseDir = Join-Path $env:USERPROFILE ".openhands-universal"
    
    $directories = @(
        (Join-Path $baseDir "workspace"),
        (Join-Path $baseDir "config"),
        (Join-Path $baseDir "cache"),
        (Join-Path $baseDir "certs"),
        (Join-Path $baseDir "ssh"),
        (Join-Path $baseDir "aws"),
        (Join-Path $baseDir "logs"),
        (Join-Path $baseDir "backups")
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Info "Created directory: $dir"
        }
    }
    
    # Set global variable for other functions
    $Script:OPENHANDS_BASE_DIR = $baseDir
    
    # Create convenient desktop shortcut to workspace
    $workspaceDir = Join-Path $baseDir "workspace"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "OpenHands Workspace.lnk"
    
    if (-not (Test-Path $shortcutPath)) {
        try {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $workspaceDir
            $shortcut.Description = "OpenHands Universal Development Workspace"
            $shortcut.Save()
            Write-Info "Created desktop shortcut to workspace"
        }
        catch {
            Write-Warn "Could not create desktop shortcut: $_"
        }
    }
    
    Write-Success "Directory structure created at: $baseDir"
}

# Windows certificate management
function Copy-WindowsCertificates {
    Write-Info "Setting up SSL certificates..."
    
    $certDir = Join-Path $Script:OPENHANDS_BASE_DIR "certs"
    
    # Export certificates from Windows certificate store
    try {
        # Get trusted root certificates
        $certs = Get-ChildItem -Path Cert:\LocalMachine\Root
        $certCount = 0
        
        foreach ($cert in $certs) {
            try {
                $certPath = Join-Path $certDir "$($cert.Thumbprint).crt"
                $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
                $certPem = [Convert]::ToBase64String($certBytes)
                
                $pemContent = @"
-----BEGIN CERTIFICATE-----
$($certPem -replace '.{64}', "`$&`n")
-----END CERTIFICATE-----
"@
                
                Set-Content -Path $certPath -Value $pemContent -Encoding ASCII
                $certCount++
            }
            catch {
                # Skip problematic certificates
            }
        }
        
        Write-Success "Exported $certCount certificates from Windows certificate store"
    }
    catch {
        Write-Warn "Could not export Windows certificates: $_"
    }
    
    # Copy custom certificates from project certs directory
    $projectCertDir = Join-Path $Script:PROJECT_DIR "certs"
    if (Test-Path $projectCertDir) {
        try {
            Copy-Item -Path (Join-Path $projectCertDir "*") -Destination $certDir -Force
            $customCerts = (Get-ChildItem $projectCertDir).Count
            Write-Info "Copied $customCerts custom certificates"
        }
        catch {
            Write-Warn "Could not copy custom certificates: $_"
        }
    }
}

# SSH key management for Windows
function Copy-SSHKeys {
    Write-Info "Setting up SSH keys..."
    
    $sshDir = Join-Path $Script:OPENHANDS_BASE_DIR "ssh"
    $windowsSSHDir = Join-Path $env:USERPROFILE ".ssh"
    
    if (Test-Path $windowsSSHDir) {
        try {
            Copy-Item -Path (Join-Path $windowsSSHDir "*") -Destination $sshDir -Recurse -Force
            
            # Set appropriate permissions (Windows equivalent)
            $acl = Get-Acl $sshDir
            $acl.SetAccessRuleProtection($true, $false)
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
            )
            $acl.SetAccessRule($accessRule)
            Set-Acl -Path $sshDir -AclObject $acl
            
            Write-Success "SSH keys configured"
        }
        catch {
            Write-Warn "Could not copy SSH keys: $_"
        }
    }
    else {
        Write-Warn "No SSH directory found at $windowsSSHDir"
        
        # Create minimal SSH config
        $sshConfig = @"
# OpenHands Universal Development Environment SSH Config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile NUL
    LogLevel QUIET

Host github.com
    HostName github.com
    User git
    IdentitiesOnly yes

Host *.amazonaws.com
    StrictHostKeyChecking yes
"@
        Set-Content -Path (Join-Path $sshDir "config") -Value $sshConfig
    }
}

# AWS credentials setup for Windows
function Initialize-AWSCredentials {
    Write-Info "Setting up AWS credentials..."
    
    $awsDir = Join-Path $Script:OPENHANDS_BASE_DIR "aws"
    $windowsAWSDir = Join-Path $env:USERPROFILE ".aws"
    
    # Method 1: Copy existing AWS configuration
    if (Test-Path $windowsAWSDir) {
        try {
            Copy-Item -Path (Join-Path $windowsAWSDir "*") -Destination $awsDir -Recurse -Force
            Write-Success "Existing AWS credentials copied"
            return
        }
        catch {
            Write-Warn "Could not copy AWS credentials: $_"
        }
    }
    
    # Method 2: Check for environment variables
    if ($env:AWS_ACCESS_KEY_ID -and $env:AWS_SECRET_ACCESS_KEY) {
        $credentialsContent = @"
[default]
aws_access_key_id = $($env:AWS_ACCESS_KEY_ID)
aws_secret_access_key = $($env:AWS_SECRET_ACCESS_KEY)
"@
        
        if ($env:AWS_SESSION_TOKEN) {
            $credentialsContent += "`naws_session_token = $($env:AWS_SESSION_TOKEN)"
        }
        
        Set-Content -Path (Join-Path $awsDir "credentials") -Value $credentialsContent
        
        $configContent = @"
[default]
region = $($env:AWS_REGION ?? "us-east-1")
output = json
"@
        Set-Content -Path (Join-Path $awsDir "config") -Value $configContent
        
        Write-Success "AWS credentials created from environment variables"
        return
    }
    
    # Method 3: Create template
    Write-Warn "No AWS credentials found. Creating template..."
    
    $credentialsTemplate = @"
[default]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE
# aws_session_token = YOUR_SESSION_TOKEN_HERE  # Uncomment for temporary credentials

[bedrock-profile]
aws_access_key_id = YOUR_BEDROCK_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_BEDROCK_SECRET_KEY_HERE
"@
    
    $configTemplate = @"
[default]
region = us-east-1
output = json

[profile bedrock-profile]
region = us-east-1
output = json
"@
    
    Set-Content -Path (Join-Path $awsDir "credentials") -Value $credentialsTemplate
    Set-Content -Path (Join-Path $awsDir "config") -Value $configTemplate
    
    Write-Info "AWS credential templates created. Please edit $awsDir\credentials with your actual credentials."
}

# Load configuration with Windows-specific handling
function Import-Configuration {
    Write-Info "Loading configuration..."
    
    if (Test-Path $Script:CONFIG_FILE) {
        Write-Info "Loading configuration from $($Script:CONFIG_FILE)"
        
        # Parse .env file (PowerShell doesn't have built-in support)
        Get-Content $Script:CONFIG_FILE | ForEach-Object {
            if ($_ -match '^([^#][^=]*?)=(.*)$') {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                # Remove quotes if present
                if ($value -match '^["''](.*)["'']$') {
                    $value = $matches[1]
                }
                
                # Set environment variable
                Set-Item -Path "env:$name" -Value $value
            }
        }
    }
    else {
        Write-Warn "Configuration file $($Script:CONFIG_FILE) not found. Using defaults."
    }
    
    # Set intelligent defaults
    if (-not $env:CONTAINER_RUNTIME) { $env:CONTAINER_RUNTIME = "podman" }
    if (-not $env:HTTP_PORT) { $env:HTTP_PORT = "3000" }
    if (-not $env:JUPYTER_PORT) { $env:JUPYTER_PORT = "8888" }
    if (-not $env:CODE_SERVER_PORT) { $env:CODE_SERVER_PORT = "8080" }
    if (-not $env:DEBUG_PORT) { $env:DEBUG_PORT = "5000" }
    if (-not $env:BIND_ADDRESS) { $env:BIND_ADDRESS = "0.0.0.0" }
    
    # Windows-specific defaults
    if (-not $env:WORKSPACE_DIR) { 
        $env:WORKSPACE_DIR = Join-Path $Script:OPENHANDS_BASE_DIR "workspace"
    }
    
    # Check for port conflicts
    Test-PortConflicts
    
    Write-Success "Configuration loaded successfully"
}

# Port conflict detection for Windows
function Test-PortConflicts {
    $ports = @($env:HTTP_PORT, $env:JUPYTER_PORT, $env:CODE_SERVER_PORT, $env:DEBUG_PORT)
    $conflicts = @()
    
    foreach ($port in $ports) {
        try {
            $listener = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            if ($listener) {
                $conflicts += $port
            }
        }
        catch {
            # Port is available
        }
    }
    
    if ($conflicts.Count -gt 0) {
        Write-Warn "Port conflicts detected: $($conflicts -join ', ')"
        
        # Auto-resolve conflicts
        foreach ($conflict in $conflicts) {
            $newPort = [int]$conflict + 1000
            
            switch ($conflict) {
                $env:HTTP_PORT { $env:HTTP_PORT = $newPort.ToString() }
                $env:JUPYTER_PORT { $env:JUPYTER_PORT = $newPort.ToString() }
                $env:CODE_SERVER_PORT { $env:CODE_SERVER_PORT = $newPort.ToString() }
                $env:DEBUG_PORT { $env:DEBUG_PORT = $newPort.ToString() }
            }
            
            Write-Info "Resolved port conflict: $conflict -> $newPort"
        }
    }
}

# Container image building for Windows
function Build-ContainerImage {
    Write-Info "Building universal development container..."
    
    $containerFile = Join-Path $Script:PROJECT_DIR "container\Containerfile"
    if (-not (Test-Path $containerFile)) {
        Write-Error "Containerfile not found at $containerFile"
        exit 1
    }
    
    $buildArgs = @()
    
    # Add proxy settings if configured
    if ($env:HTTP_PROXY) { $buildArgs += "--build-arg", "HTTP_PROXY=$($env:HTTP_PROXY)" }
    if ($env:HTTPS_PROXY) { $buildArgs += "--build-arg", "HTTPS_PROXY=$($env:HTTPS_PROXY)" }
    if ($env:NO_PROXY) { $buildArgs += "--build-arg", "NO_PROXY=$($env:NO_PROXY)" }
    
    # Add registry settings
    if ($env:NPM_REGISTRY) { $buildArgs += "--build-arg", "NPM_REGISTRY=$($env:NPM_REGISTRY)" }
    if ($env:PIP_INDEX_URL) { $buildArgs += "--build-arg", "PIP_INDEX_URL=$($env:PIP_INDEX_URL)" }
    if ($env:MAVEN_REPOSITORY_URL) { $buildArgs += "--build-arg", "MAVEN_REPOSITORY_URL=$($env:MAVEN_REPOSITORY_URL)" }
    
    # Build the image
    $buildCommand = @("podman", "build", "-t", $Script:IMAGE_NAME, "-f", $containerFile) + $buildArgs + @($Script:PROJECT_DIR)
    
    Write-Info "Building container image..."
    & $buildCommand[0] $buildCommand[1..($buildCommand.Length-1)]
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build container image"
        exit 1
    }
    
    Write-Success "Container image built successfully: $($Script:IMAGE_NAME)"
}

# Container execution with Windows-specific handling
function Start-Container {
    param([string[]]$AdditionalArgs = @())
    
    Write-Info "Starting universal development environment..."
    
    # Convert Windows paths to container-compatible paths
    $workspaceMount = "$($Script:OPENHANDS_BASE_DIR)\workspace:/workspace:Z"
    $configMount = "$($Script:OPENHANDS_BASE_DIR)\config:/config:Z"
    $cacheMount = "$($Script:OPENHANDS_BASE_DIR)\cache:/cache:Z"
    $certsMount = "$($Script:OPENHANDS_BASE_DIR)\certs:/certs:ro,Z"
    $sshMount = "$($Script:OPENHANDS_BASE_DIR)\ssh:/home/developer/.ssh:ro,Z"
    $awsMount = "$($Script:OPENHANDS_BASE_DIR)\aws:/home/developer/.aws:ro,Z"
    $logsMount = "$($Script:OPENHANDS_BASE_DIR)\logs:/logs:Z"
    
    # Base run arguments
    $runArgs = @(
        "podman", "run",
        "--name", $Script:CONTAINER_NAME,
        "--rm",
        "--interactive",
        "--tty",
        "--hostname", "openhands-dev",
        "--env", "TERM=xterm-256color",
        "--env", "PLATFORM=windows",
        "--volume", $workspaceMount,
        "--volume", $configMount,
        "--volume", $cacheMount,
        "--volume", $certsMount,
        "--volume", $sshMount,
        "--volume", $awsMount,
        "--volume", $logsMount,
        "--publish", "$($env:HTTP_PORT):3000",
        "--publish", "$($env:JUPYTER_PORT):8888",
        "--publish", "$($env:CODE_SERVER_PORT):8080",
        "--publish", "$($env:DEBUG_PORT):5000"
    )
    
    # Environment variables
    $envVars = @(
        "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY",
        "AWS_PROFILE", "AWS_REGION", "AWS_BEDROCK_REGION", "AWS_BEDROCK_MODEL_ID",
        "GITHUB_TOKEN", "GITHUB_ENTERPRISE_URL",
        "GIT_USER_NAME", "GIT_USER_EMAIL",
        "NPM_REGISTRY", "PIP_INDEX_URL"
    )
    
    foreach ($var in $envVars) {
        $value = [Environment]::GetEnvironmentVariable($var)
        if ($value) {
            $runArgs += "--env", "$var=$value"
        }
    }
    
    # Security context
    $runArgs += @(
        "--security-opt", "seccomp=unconfined",
        "--cap-add", "SYS_PTRACE"
    )
    
    # Add the image name and any additional arguments
    $runArgs += $Script:IMAGE_NAME
    if ($AdditionalArgs) {
        $runArgs += $AdditionalArgs
    }
    
    # Display connection information
    Write-Info "Starting container with the following configuration:"
    Write-Info "  HTTP Server: http://localhost:$($env:HTTP_PORT)"
    Write-Info "  Jupyter Lab: http://localhost:$($env:JUPYTER_PORT)"
    Write-Info "  Code Server: http://localhost:$($env:CODE_SERVER_PORT)"
    Write-Info "  Debug Port: $($env:DEBUG_PORT)"
    Write-Info "  Workspace: $($Script:OPENHANDS_BASE_DIR)\workspace"
    
    # Execute container
    & $runArgs[0] $runArgs[1..($runArgs.Length-1)]
}

# Generate configuration template
function New-ConfigurationTemplate {
    Write-Info "Generating Windows PowerShell configuration template..."
    
    $configTemplate = @"
# Universal Development Environment Configuration - Windows PowerShell
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
#AWS_BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0

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
# WINDOWS-SPECIFIC SETTINGS
# =============================================================================
# Workspace directory (Windows path)
#WORKSPACE_DIR=C:\Users\YourName\Documents\OpenHands

# Windows certificate store integration
#USE_WINDOWS_CERT_STORE=true

# =============================================================================
# DEVELOPMENT SETTINGS
# =============================================================================
#JAVA_OPTS="-Xmx4g -Xms1g"
#NODE_OPTIONS="--max-old-space-size=8192"
#PYTHON_ENV=development

# =============================================================================
# DEBUGGING
# =============================================================================
#DEBUG=false
#VERBOSE_LOGGING=false
"@

    Set-Content -Path $Script:CONFIG_FILE -Value $configTemplate
    Write-Success "Configuration template created: $($Script:CONFIG_FILE)"
    Write-Info "Please edit this file with your specific settings before running the environment."
}

# Environment validation
function Test-Environment {
    Write-Info "Validating environment setup..."
    
    $issues = @()
    
    # Check container runtime
    try {
        & $env:CONTAINER_RUNTIME --version | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $issues += "Container runtime '$($env:CONTAINER_RUNTIME)' not working"
        }
    }
    catch {
        $issues += "Container runtime '$($env:CONTAINER_RUNTIME)' not found"
    }
    
    # Check directories
    if (-not (Test-Path $Script:OPENHANDS_BASE_DIR)) {
        $issues += "Base directory not found: $($Script:OPENHANDS_BASE_DIR)"
    }
    
    # Check AWS configuration
    $awsCredentials = Join-Path $Script:OPENHANDS_BASE_DIR "aws\credentials"
    if (Test-Path $awsCredentials) {
        $credContent = Get-Content $awsCredentials -Raw
        if ($credContent -match "YOUR_ACCESS_KEY_HERE") {
            $issues += "AWS credentials not configured - still contains placeholder values"
        }
    }
    
    if ($issues.Count -gt 0) {
        Write-Warn "Environment validation found issues:"
        foreach ($issue in $issues) {
            Write-Warn "  - $issue"
        }
        return $false
    }
    
    Write-Success "Environment validation passed"
    return $true
}

# Cleanup function
function Remove-Environment {
    Write-Info "Cleaning up..."
    
    # Stop running container
    try {
        $containers = & podman ps -q --filter "name=$($Script:CONTAINER_NAME)" 2>$null
        if ($containers -and $LASTEXITCODE -eq 0) {
            Write-Info "Stopping container: $($Script:CONTAINER_NAME)"
            & podman stop $Script:CONTAINER_NAME | Out-Null
        }
    }
    catch {
        # Container not running
    }
    
    # Clean up images if requested
    if ($CleanImages) {
        Write-Info "Removing container image: $($Script:IMAGE_NAME)"
        try {
            & podman rmi $Script:IMAGE_NAME | Out-Null
        }
        catch {
            Write-Warn "Could not remove image: $_"
        }
    }
}

# Help function
function Show-Help {
    Write-Host @"
Universal Development Environment for Windows PowerShell v$($Script:DEV_ENV_VERSION)

USAGE:
    .\universal-dev-env.ps1 [COMMAND] [OPTIONS]

COMMANDS:
    start           Start the development environment (default)
    build           Build the container image only
    clean           Remove containers and optionally images
    config          Generate configuration template
    validate        Validate environment setup
    shell           Start container with shell access
    help            Show this help message

OPTIONS:
    -Rebuild        Force rebuild of container image
    -CleanImages    Remove images during cleanup
    -Debug          Enable debug output
    -ConfigFile     Use custom configuration file

EXAMPLES:
    .\universal-dev-env.ps1 start                    # Start with default configuration
    .\universal-dev-env.ps1 start -Rebuild          # Force rebuild and start
    .\universal-dev-env.ps1 build                   # Build container image only
    .\universal-dev-env.ps1 config                  # Generate configuration template
    .\universal-dev-env.ps1 clean -CleanImages      # Full cleanup including images

WINDOWS REQUIREMENTS:
    - Windows 10/11 (build 19041+)
    - Podman Desktop or Podman CLI
    - PowerShell 5.1 or PowerShell Core 7+

AWS BEDROCK SETUP:
    1. Install AWS CLI: winget install Amazon.AWSCLI
    2. Configure credentials: aws configure
    3. Set AWS_BEDROCK_REGION (default: us-east-1)
    4. Test with: .\test-aws-bedrock.ps1

For more information, see SETUP-WINDOWS-POWERSHELL.md
"@
}

# Main execution function
function Invoke-Main {
    if ($Debug) {
        $DebugPreference = "Continue"
    }
    
    Write-Info "Starting Universal Development Environment v$($Script:DEV_ENV_VERSION) for Windows PowerShell"
    
    # Detect and verify Windows environment
    Test-WindowsEnvironment
    
    try {
        switch ($Command.ToLower()) {
            "config" {
                New-ConfigurationTemplate
            }
            "validate" {
                Initialize-Directories
                Import-Configuration
                Test-Environment
            }
            "build" {
                Test-PodmanInstallation
                Initialize-Directories
                Copy-WindowsCertificates
                Import-Configuration
                Build-ContainerImage
            }
            "clean" {
                Remove-Environment
                Write-Info "Cleanup complete"
            }
            "shell" {
                Test-PodmanInstallation
                Initialize-Directories
                Copy-WindowsCertificates
                Copy-SSHKeys
                Initialize-AWSCredentials
                Import-Configuration
                
                if ($Rebuild -or -not (& podman image exists $Script:IMAGE_NAME 2>$null)) {
                    Build-ContainerImage
                }
                
                Start-Container @("/bin/bash")
            }
            "start" {
                Test-PodmanInstallation
                Initialize-Directories
                Copy-WindowsCertificates
                Copy-SSHKeys
                Initialize-AWSCredentials
                Import-Configuration
                
                if (-not (Test-Environment)) {
                    Write-Error "Environment validation failed. Please fix the issues above."
                    exit 1
                }
                
                if ($Rebuild -or -not (& podman image exists $Script:IMAGE_NAME 2>$null)) {
                    Build-ContainerImage
                }
                
                Start-Container
            }
            "help" {
                Show-Help
            }
            default {
                Write-Error "Unknown command: $Command. Use 'help' for usage information."
                exit 1
            }
        }
    }
    catch {
        Write-Error "Script failed: $_"
        exit 1
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Main
}