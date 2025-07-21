# AWS Bedrock Connectivity Test Script for Windows PowerShell
# Comprehensive testing for AWS Bedrock integration
# Version: 2.0.0

[CmdletBinding()]
param(
    [switch]$Quick,
    [string]$Region = "",
    [string]$Model = "",
    [switch]$ListRegions,
    [switch]$ListModels,
    [switch]$Help
)

# Configuration
$Script:AWS_REGIONS = @("us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1", "ap-northeast-1")
$Script:BEDROCK_MODELS = @(
    "anthropic.claude-3-5-sonnet-20241022-v2:0",
    "anthropic.claude-3-sonnet-20240229-v1:0",
    "anthropic.claude-3-haiku-20240307-v1:0",
    "anthropic.claude-instant-v1",
    "amazon.titan-text-express-v1",
    "cohere.command-text-v14",
    "ai21.j2-ultra-v1",
    "meta.llama2-70b-chat-v1"
)

# Logging functions with colors
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Write-Info { param([string]$Message) Write-Log $Message "INFO" }
function Write-Warn { param([string]$Message) Write-Log $Message "WARN" }
function Write-Error { param([string]$Message) Write-Log $Message "ERROR" }
function Write-Success { param([string]$Message) Write-Log $Message "SUCCESS" }

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    $missingTools = @()
    
    # Check AWS CLI
    try {
        & aws --version | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $missingTools += "aws-cli"
        }
    }
    catch {
        $missingTools += "aws-cli"
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.0 or higher required. Current version: $($PSVersionTable.PSVersion)"
        exit 1
    }
    
    if ($missingTools.Count -gt 0) {
        Write-Error "Missing required tools: $($missingTools -join ', ')"
        Write-Info "Install missing tools:"
        foreach ($tool in $missingTools) {
            switch ($tool) {
                "aws-cli" {
                    Write-Host "  AWS CLI: winget install Amazon.AWSCLI"
                }
            }
        }
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

# Display AWS configuration
function Show-AWSConfig {
    Write-Info "AWS Configuration:"
    
    # Check AWS CLI configuration
    try {
        $awsConfig = & aws configure list 2>$null
        if ($LASTEXITCODE -eq 0) {
            $awsConfig | ForEach-Object { Write-Host "  $_" }
        }
        else {
            Write-Warn "AWS CLI not configured"
            return $false
        }
    }
    catch {
        Write-Warn "AWS CLI not configured"
        return $false
    }
    
    # Check environment variables
    Write-Host ""
    Write-Info "Environment Variables:"
    $awsVars = @("AWS_PROFILE", "AWS_REGION", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN", "AWS_BEDROCK_REGION", "AWS_BEDROCK_MODEL_ID")
    
    foreach ($var in $awsVars) {
        $value = [Environment]::GetEnvironmentVariable($var)
        if ($value) {
            if ($var -like "*KEY*" -or $var -like "*TOKEN*") {
                Write-Host "  $var`: ******* (redacted)"
            }
            else {
                Write-Host "  $var`: $value"
            }
        }
    }
    
    return $true
}

# Test AWS authentication
function Test-AWSAuth {
    Write-Info "Testing AWS authentication..."
    
    try {
        $identity = & aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) {
            Write-Error "AWS authentication failed"
            Write-Info "Common solutions:"
            Write-Info "  1. Run: aws configure"
            Write-Info "  2. Set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
            Write-Info "  3. Use IAM roles or profiles"
            return $false
        }
        
        $userArn = $identity.Arn
        $accountId = $identity.Account
        
        Write-Success "Authenticated as: $userArn"
        Write-Info "Account ID: $accountId"
        return $true
    }
    catch {
        Write-Error "AWS authentication failed: $_"
        return $false
    }
}

# Test Bedrock access in specific region
function Test-BedrockRegion {
    param([string]$TestRegion)
    
    Write-Info "Testing Bedrock access in region: $TestRegion"
    
    try {
        $modelsOutput = & aws bedrock list-foundation-models --region $TestRegion --output json 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Cannot access Bedrock in region: $TestRegion"
            return $false
        }
        
        $models = $modelsOutput | ConvertFrom-Json
        $modelCount = $models.modelSummaries.Count
        
        Write-Success "Bedrock accessible in $TestRegion with $modelCount foundation models"
        
        # List available models (first 10)
        Write-Host "  Available models:"
        $models.modelSummaries | Select-Object -First 10 | ForEach-Object {
            Write-Host "    $($_.modelId)"
        }
        
        if ($modelCount -gt 10) {
            Write-Host "    ... and $($modelCount - 10) more"
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to access Bedrock in region $TestRegion`: $_"
        return $false
    }
}

# Test specific model availability
function Test-ModelAvailability {
    param([string]$TestRegion, [string]$ModelId)
    
    Write-Info "Testing model availability: $ModelId in $TestRegion"
    
    try {
        $modelsOutput = & aws bedrock list-foundation-models --region $TestRegion --output json 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $false
        }
        
        $models = $modelsOutput | ConvertFrom-Json
        $model = $models.modelSummaries | Where-Object { $_.modelId -eq $ModelId }
        
        if ($model) {
            Write-Success "Model $ModelId is available in $TestRegion"
            return $true
        }
        else {
            Write-Warn "Model $ModelId is not available in $TestRegion"
            return $false
        }
    }
    catch {
        Write-Warn "Could not check model availability: $_"
        return $false
    }
}

# Test model inference capability
function Test-ModelInference {
    param([string]$TestRegion, [string]$ModelId)
    
    Write-Info "Testing model inference: $ModelId"
    
    # Create test payload based on model type
    $payload = $null
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    try {
        if ($ModelId -like "anthropic.*") {
            $payload = @{
                anthropic_version = "bedrock-2023-05-31"
                max_tokens = 100
                messages = @(
                    @{
                        role = "user"
                        content = "Hello, can you confirm you're working? Please respond with just 'Yes, I am working properly.'"
                    }
                )
            } | ConvertTo-Json -Depth 10
        }
        elseif ($ModelId -like "amazon.titan-*") {
            $payload = @{
                inputText = "Hello, can you confirm you're working?"
                textGenerationConfig = @{
                    maxTokenCount = 50
                    temperature = 0.1
                }
            } | ConvertTo-Json -Depth 10
        }
        else {
            Write-Warn "Unknown model type for $ModelId, skipping inference test"
            return $false
        }
        
        # Test inference
        $invokeResult = & aws bedrock-runtime invoke-model --region $TestRegion --model-id $ModelId --body $payload --cli-binary-format raw-in-base64-out $tempFile 2>$null
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $tempFile)) {
            Write-Success "Model inference successful for $ModelId"
            
            # Try to extract response text
            try {
                $response = Get-Content $tempFile -Raw | ConvertFrom-Json
                $responseText = $null
                
                if ($ModelId -like "anthropic.*") {
                    $responseText = $response.content[0].text
                }
                elseif ($ModelId -like "amazon.titan-*") {
                    $responseText = $response.results[0].outputText
                }
                
                if ($responseText) {
                    Write-Info "Model response: $responseText"
                }
            }
            catch {
                Write-Info "Could not parse response text: $_"
            }
            
            return $true
        }
        else {
            Write-Error "Model inference failed for $ModelId"
            return $false
        }
    }
    catch {
        Write-Error "Model inference failed for $ModelId`: $_"
        return $false
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
}

# Test IAM permissions
function Test-IAMPermissions {
    param([string]$TestRegion)
    
    Write-Info "Testing IAM permissions for Bedrock..."
    
    $permissionErrors = @()
    
    # Test list-foundation-models (bedrock:ListFoundationModels)
    try {
        & aws bedrock list-foundation-models --region $TestRegion --output json 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $permissionErrors += "bedrock:ListFoundationModels"
        }
    }
    catch {
        $permissionErrors += "bedrock:ListFoundationModels"
    }
    
    # Test invoke-model with a simple model if available
    try {
        $modelsOutput = & aws bedrock list-foundation-models --region $TestRegion --output json 2>$null
        if ($LASTEXITCODE -eq 0) {
            $models = $modelsOutput | ConvertFrom-Json
            $testModel = $models.modelSummaries[0].modelId
            
            if ($testModel) {
                $minimalPayload = @{
                    inputText = "test"
                    textGenerationConfig = @{
                        maxTokenCount = 1
                    }
                } | ConvertTo-Json
                
                $tempFile = [System.IO.Path]::GetTempFileName()
                try {
                    & aws bedrock-runtime invoke-model --region $TestRegion --model-id $testModel --body $minimalPayload --cli-binary-format raw-in-base64-out $tempFile 2>$null | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        $permissionErrors += "bedrock:InvokeModel"
                    }
                }
                finally {
                    if (Test-Path $tempFile) {
                        Remove-Item $tempFile -Force
                    }
                }
            }
        }
    }
    catch {
        # Could not test invoke permissions
    }
    
    if ($permissionErrors.Count -eq 0) {
        Write-Success "All required IAM permissions are available"
        return $true
    }
    else {
        Write-Error "Missing IAM permissions: $($permissionErrors -join ', ')"
        Write-Info "Add these permissions to your IAM user/role:"
        foreach ($action in $permissionErrors) {
            Write-Host "  - $action"
        }
        return $false
    }
}

# Comprehensive Bedrock test
function Invoke-ComprehensiveTest {
    $targetRegion = if ($Region) { $Region } else { $env:AWS_BEDROCK_REGION ?? $env:AWS_REGION ?? "us-east-1" }
    $targetModel = if ($Model) { $Model } else { $env:AWS_BEDROCK_MODEL_ID ?? "anthropic.claude-3-sonnet-20240229-v1:0" }
    
    Write-Host ""
    Write-Log "🧪 Starting Comprehensive AWS Bedrock Test" "INFO"
    Write-Host "=========================================="
    
    # Show configuration
    if (-not (Show-AWSConfig)) {
        return $false
    }
    Write-Host ""
    
    # Test authentication
    if (-not (Test-AWSAuth)) {
        return $false
    }
    Write-Host ""
    
    # Test IAM permissions
    if (-not (Test-IAMPermissions $targetRegion)) {
        return $false
    }
    Write-Host ""
    
    # Test target region
    if (-not (Test-BedrockRegion $targetRegion)) {
        Write-Error "Failed to access Bedrock in target region: $targetRegion"
        return $false
    }
    Write-Host ""
    
    # Test target model availability
    if (-not (Test-ModelAvailability $targetRegion $targetModel)) {
        Write-Warn "Target model $targetModel not available, testing with available models..."
        
        # Find an available model
        try {
            $modelsOutput = & aws bedrock list-foundation-models --region $targetRegion --output json 2>$null
            if ($LASTEXITCODE -eq 0) {
                $models = $modelsOutput | ConvertFrom-Json
                if ($models.modelSummaries.Count -gt 0) {
                    $targetModel = $models.modelSummaries[0].modelId
                    Write-Info "Using available model: $targetModel"
                }
                else {
                    Write-Error "No models available for testing"
                    return $false
                }
            }
            else {
                Write-Error "Could not retrieve available models"
                return $false
            }
        }
        catch {
            Write-Error "Could not retrieve available models: $_"
            return $false
        }
    }
    Write-Host ""
    
    # Test model inference
    if (Test-ModelInference $targetRegion $targetModel) {
        Write-Host ""
        Write-Success "🎉 All Bedrock tests passed successfully!"
        
        Write-Host ""
        Write-Info "Configuration Summary:"
        Write-Host "  ✅ Region: $targetRegion" -ForegroundColor Green
        Write-Host "  ✅ Model: $targetModel" -ForegroundColor Green
        Write-Host "  ✅ Authentication: Working" -ForegroundColor Green
        Write-Host "  ✅ Permissions: Valid" -ForegroundColor Green
        Write-Host "  ✅ Inference: Functional" -ForegroundColor Green
        
        return $true
    }
    else {
        Write-Host ""
        Write-Error "❌ Bedrock inference test failed"
        return $false
    }
}

# Quick test mode
function Invoke-QuickTest {
    $testRegion = if ($Region) { $Region } else { $env:AWS_BEDROCK_REGION ?? $env:AWS_REGION ?? "us-east-1" }
    
    Write-Host ""
    Write-Log "⚡ Quick AWS Bedrock Test" "INFO"
    Write-Host "========================="
    
    # Quick auth check
    try {
        & aws sts get-caller-identity 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✅ AWS Authentication: OK"
        }
        else {
            Write-Error "❌ AWS Authentication: Failed"
            return $false
        }
    }
    catch {
        Write-Error "❌ AWS Authentication: Failed"
        return $false
    }
    
    # Quick Bedrock check
    try {
        $modelsOutput = & aws bedrock list-foundation-models --region $testRegion --output json 2>$null
        if ($LASTEXITCODE -eq 0) {
            $models = $modelsOutput | ConvertFrom-Json
            $modelCount = $models.modelSummaries.Count
            Write-Success "✅ Bedrock Access: OK ($modelCount models available)"
            return $true
        }
        else {
            Write-Error "❌ Bedrock Access: Failed"
            return $false
        }
    }
    catch {
        Write-Error "❌ Bedrock Access: Failed"
        return $false
    }
}

# Show help
function Show-Help {
    Write-Host @"
AWS Bedrock Connectivity Test Script v2.0.0 - Windows PowerShell

USAGE:
    .\test-aws-bedrock.ps1 [OPTIONS]

OPTIONS:
    -Quick          Run quick connectivity test only
    -Region REGION  Set AWS region for testing (default: `$env:AWS_BEDROCK_REGION or `$env:AWS_REGION or us-east-1)
    -Model MODEL    Set model ID for testing (default: `$env:AWS_BEDROCK_MODEL_ID or anthropic.claude-3-sonnet-20240229-v1:0)
    -ListRegions    List supported Bedrock regions
    -ListModels     List common Bedrock models
    -Help           Show this help message

EXAMPLES:
    .\test-aws-bedrock.ps1                                  # Run comprehensive test
    .\test-aws-bedrock.ps1 -Quick                          # Quick connectivity test
    .\test-aws-bedrock.ps1 -Region us-west-2               # Test specific region
    .\test-aws-bedrock.ps1 -Model anthropic.claude-instant-v1  # Test specific model

ENVIRONMENT VARIABLES:
    AWS_PROFILE             AWS profile to use
    AWS_REGION              Default AWS region
    AWS_BEDROCK_REGION      Bedrock-specific region
    AWS_BEDROCK_MODEL_ID    Model ID to test
    AWS_ACCESS_KEY_ID       AWS access key
    AWS_SECRET_ACCESS_KEY   AWS secret key
    AWS_SESSION_TOKEN       AWS session token (for temporary credentials)

WINDOWS SETUP:
    1. Install AWS CLI: winget install Amazon.AWSCLI
    2. Configure credentials: aws configure
    3. Test connectivity: .\test-aws-bedrock.ps1 -Quick

TROUBLESHOOTING:
    1. Ensure AWS CLI is configured: aws configure
    2. Check IAM permissions for Bedrock access
    3. Verify region supports Bedrock service
    4. Confirm model availability in your account
"@
}

# List supported regions
function Show-Regions {
    Write-Host "Supported AWS Bedrock Regions:"
    foreach ($region in $Script:AWS_REGIONS) {
        Write-Host "  - $region"
    }
}

# List common models
function Show-Models {
    Write-Host "Common AWS Bedrock Models:"
    foreach ($model in $Script:BEDROCK_MODELS) {
        Write-Host "  - $model"
    }
}

# Main function
function Invoke-Main {
    # Handle help and listing commands first
    if ($Help) {
        Show-Help
        return
    }
    
    if ($ListRegions) {
        Show-Regions
        return
    }
    
    if ($ListModels) {
        Show-Models
        return
    }
    
    # Set environment variables if provided
    if ($Region) { $env:AWS_BEDROCK_REGION = $Region }
    if ($Model) { $env:AWS_BEDROCK_MODEL_ID = $Model }
    
    # Check prerequisites
    Test-Prerequisites
    
    # Run appropriate test
    if ($Quick) {
        $success = Invoke-QuickTest
    }
    else {
        $success = Invoke-ComprehensiveTest
    }
    
    if (-not $success) {
        exit 1
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Main
}