#!/bin/bash

# AWS Bedrock Connectivity Test Script
# Comprehensive testing for AWS Bedrock integration
# Version: 2.0.0

set -euo pipefail

# Configuration
readonly AWS_REGIONS=("us-east-1" "us-west-2" "eu-west-1" "ap-southeast-1" "ap-northeast-1")
readonly BEDROCK_MODELS=(
    "anthropic.claude-3-5-sonnet-20241022-v2:0"
    "anthropic.claude-3-sonnet-20240229-v1:0"
    "anthropic.claude-3-haiku-20240307-v1:0"
    "anthropic.claude-instant-v1"
    "amazon.titan-text-express-v1"
    "cohere.command-text-v14"
    "ai21.j2-ultra-v1"
    "meta.llama2-70b-chat-v1"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

info() {
    echo -e "${BLUE}INFO:${NC} $*"
}

warn() {
    echo -e "${YELLOW}WARN:${NC} $*"
}

error() {
    echo -e "${RED}ERROR:${NC} $*"
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $*"
}

# Check if required tools are installed
check_prerequisites() {
    info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing_tools[*]}"
        info "Install missing tools:"
        for tool in "${missing_tools[@]}"; do
            case "$tool" in
                "aws-cli")
                    echo "  AWS CLI: pip install awscli"
                    ;;
                "jq")
                    echo "  jq: apt install jq (Ubuntu) or brew install jq (macOS)"
                    ;;
                "curl")
                    echo "  curl: apt install curl (Ubuntu) or pre-installed (macOS)"
                    ;;
            esac
        done
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Display AWS configuration
show_aws_config() {
    info "AWS Configuration:"
    
    # Check AWS CLI configuration
    if aws configure list &>/dev/null; then
        echo "  $(aws configure list 2>/dev/null | head -4 | tail -3)"
    else
        warn "AWS CLI not configured"
        return 1
    fi
    
    # Check environment variables
    echo ""
    info "Environment Variables:"
    for var in AWS_PROFILE AWS_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_BEDROCK_REGION AWS_BEDROCK_MODEL_ID; do
        if [[ -n "${!var:-}" ]]; then
            if [[ "$var" == *"KEY"* ]] || [[ "$var" == *"TOKEN"* ]]; then
                echo "  $var: ******* (redacted)"
            else
                echo "  $var: ${!var}"
            fi
        fi
    done
}

# Test AWS authentication
test_aws_auth() {
    info "Testing AWS authentication..."
    
    if ! aws sts get-caller-identity &>/dev/null; then
        error "AWS authentication failed"
        info "Common solutions:"
        info "  1. Run: aws configure"
        info "  2. Set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
        info "  3. Use IAM roles or profiles"
        return 1
    fi
    
    local identity
    identity=$(aws sts get-caller-identity --output json 2>/dev/null)
    local user_arn
    user_arn=$(echo "$identity" | jq -r '.Arn')
    local account_id
    account_id=$(echo "$identity" | jq -r '.Account')
    
    success "Authenticated as: $user_arn"
    info "Account ID: $account_id"
}

# Test Bedrock access in specific region
test_bedrock_region() {
    local region="$1"
    info "Testing Bedrock access in region: $region"
    
    # Test list-foundation-models
    if ! aws bedrock list-foundation-models --region "$region" &>/dev/null; then
        error "Cannot access Bedrock in region: $region"
        return 1
    fi
    
    local models_output
    models_output=$(aws bedrock list-foundation-models --region "$region" --output json 2>/dev/null)
    local model_count
    model_count=$(echo "$models_output" | jq '.modelSummaries | length' 2>/dev/null || echo "0")
    
    success "Bedrock accessible in $region with $model_count foundation models"
    
    # List available models
    echo "  Available models:"
    echo "$models_output" | jq -r '.modelSummaries[] | "    " + .modelId' 2>/dev/null | head -10
    
    if [[ "$model_count" -gt 10 ]]; then
        echo "    ... and $((model_count - 10)) more"
    fi
    
    return 0
}

# Test specific model availability
test_model_availability() {
    local region="$1"
    local model_id="$2"
    
    info "Testing model availability: $model_id in $region"
    
    # Check if model exists in the foundation models list
    if aws bedrock list-foundation-models --region "$region" --output json 2>/dev/null | \
       jq -e ".modelSummaries[] | select(.modelId == \"$model_id\")" >/dev/null; then
        success "Model $model_id is available in $region"
        return 0
    else
        warn "Model $model_id is not available in $region"
        return 1
    fi
}

# Test model inference capability
test_model_inference() {
    local region="$1"
    local model_id="$2"
    
    info "Testing model inference: $model_id"
    
    # Create test payload based on model type
    local payload
    if [[ "$model_id" == anthropic.* ]]; then
        payload=$(cat << 'EOF'
{
    "anthropic_version": "bedrock-2023-05-31",
    "max_tokens": 100,
    "messages": [
        {
            "role": "user",
            "content": "Hello, can you confirm you're working? Please respond with just 'Yes, I am working properly.'"
        }
    ]
}
EOF
        )
    elif [[ "$model_id" == amazon.titan-* ]]; then
        payload=$(cat << 'EOF'
{
    "inputText": "Hello, can you confirm you're working?",
    "textGenerationConfig": {
        "maxTokenCount": 50,
        "temperature": 0.1
    }
}
EOF
        )
    else
        warn "Unknown model type for $model_id, skipping inference test"
        return 1
    fi
    
    # Test inference
    local response
    if response=$(aws bedrock-runtime invoke-model \
        --region "$region" \
        --model-id "$model_id" \
        --body "$payload" \
        --cli-binary-format raw-in-base64-out \
        /tmp/bedrock-response.json 2>/dev/null); then
        
        success "Model inference successful for $model_id"
        
        # Try to extract response text
        if [[ -f "/tmp/bedrock-response.json" ]]; then
            local response_text
            if [[ "$model_id" == anthropic.* ]]; then
                response_text=$(jq -r '.content[0].text // "No response text"' /tmp/bedrock-response.json 2>/dev/null || echo "Parse error")
            elif [[ "$model_id" == amazon.titan-* ]]; then
                response_text=$(jq -r '.results[0].outputText // "No response text"' /tmp/bedrock-response.json 2>/dev/null || echo "Parse error")
            else
                response_text="Unknown format"
            fi
            
            info "Model response: $response_text"
            rm -f /tmp/bedrock-response.json
        fi
        
        return 0
    else
        error "Model inference failed for $model_id"
        return 1
    fi
}

# Test IAM permissions
test_iam_permissions() {
    local region="$1"
    info "Testing IAM permissions for Bedrock..."
    
    local required_actions=(
        "bedrock:ListFoundationModels"
        "bedrock:InvokeModel"
        "bedrock:InvokeModelWithResponseStream"
    )
    
    local permission_errors=()
    
    # Test list-foundation-models (bedrock:ListFoundationModels)
    if ! aws bedrock list-foundation-models --region "$region" &>/dev/null; then
        permission_errors+=("bedrock:ListFoundationModels")
    fi
    
    # Test invoke-model (will test with a simple model if available)
    local test_model
    test_model=$(aws bedrock list-foundation-models --region "$region" --output json 2>/dev/null | \
                 jq -r '.modelSummaries[0].modelId // "none"' 2>/dev/null || echo "none")
    
    if [[ "$test_model" != "none" ]]; then
        # Try a minimal inference test
        local minimal_payload='{"inputText":"test","textGenerationConfig":{"maxTokenCount":1}}'
        
        if ! aws bedrock-runtime invoke-model \
            --region "$region" \
            --model-id "$test_model" \
            --body "$minimal_payload" \
            --cli-binary-format raw-in-base64-out \
            /tmp/permission-test.json &>/dev/null; then
            permission_errors+=("bedrock:InvokeModel")
        fi
        
        rm -f /tmp/permission-test.json
    fi
    
    if [[ ${#permission_errors[@]} -eq 0 ]]; then
        success "All required IAM permissions are available"
        return 0
    else
        error "Missing IAM permissions: ${permission_errors[*]}"
        info "Add these permissions to your IAM user/role:"
        for action in "${permission_errors[@]}"; do
            echo "  - $action"
        done
        return 1
    fi
}

# Comprehensive Bedrock test
run_comprehensive_test() {
    local target_region="${AWS_BEDROCK_REGION:-${AWS_REGION:-us-east-1}}"
    local target_model="${AWS_BEDROCK_MODEL_ID:-anthropic.claude-3-sonnet-20240229-v1:0}"
    
    echo ""
    log "🧪 Starting Comprehensive AWS Bedrock Test"
    echo "=========================================="
    
    # Show configuration
    show_aws_config
    echo ""
    
    # Test authentication
    if ! test_aws_auth; then
        return 1
    fi
    echo ""
    
    # Test IAM permissions
    if ! test_iam_permissions "$target_region"; then
        return 1
    fi
    echo ""
    
    # Test target region
    if ! test_bedrock_region "$target_region"; then
        error "Failed to access Bedrock in target region: $target_region"
        return 1
    fi
    echo ""
    
    # Test target model availability
    if ! test_model_availability "$target_region" "$target_model"; then
        warn "Target model $target_model not available, testing with available models..."
        
        # Find an available model
        local available_model
        available_model=$(aws bedrock list-foundation-models --region "$target_region" --output json 2>/dev/null | \
                         jq -r '.modelSummaries[0].modelId // "none"' 2>/dev/null || echo "none")
        
        if [[ "$available_model" != "none" ]]; then
            target_model="$available_model"
            info "Using available model: $target_model"
        else
            error "No models available for testing"
            return 1
        fi
    fi
    echo ""
    
    # Test model inference
    if test_model_inference "$target_region" "$target_model"; then
        echo ""
        success "🎉 All Bedrock tests passed successfully!"
        
        echo ""
        info "Configuration Summary:"
        echo "  ✅ Region: $target_region"
        echo "  ✅ Model: $target_model"
        echo "  ✅ Authentication: Working"
        echo "  ✅ Permissions: Valid"
        echo "  ✅ Inference: Functional"
        
        return 0
    else
        echo ""
        error "❌ Bedrock inference test failed"
        return 1
    fi
}

# Quick test mode
run_quick_test() {
    local region="${AWS_BEDROCK_REGION:-${AWS_REGION:-us-east-1}}"
    
    echo ""
    log "⚡ Quick AWS Bedrock Test"
    echo "========================="
    
    # Quick auth check
    if aws sts get-caller-identity &>/dev/null; then
        success "✅ AWS Authentication: OK"
    else
        error "❌ AWS Authentication: Failed"
        return 1
    fi
    
    # Quick Bedrock check
    if aws bedrock list-foundation-models --region "$region" &>/dev/null; then
        local model_count
        model_count=$(aws bedrock list-foundation-models --region "$region" --output json 2>/dev/null | \
                     jq '.modelSummaries | length' 2>/dev/null || echo "0")
        success "✅ Bedrock Access: OK ($model_count models available)"
        return 0
    else
        error "❌ Bedrock Access: Failed"
        return 1
    fi
}

# Show help
show_help() {
    cat << EOF
AWS Bedrock Connectivity Test Script v2.0.0

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --quick         Run quick connectivity test only
    --region REGION Set AWS region for testing (default: \$AWS_BEDROCK_REGION or \$AWS_REGION or us-east-1)
    --model MODEL   Set model ID for testing (default: \$AWS_BEDROCK_MODEL_ID or anthropic.claude-3-sonnet-20240229-v1:0)
    --list-regions  List supported Bedrock regions
    --list-models   List common Bedrock models
    --help          Show this help message

EXAMPLES:
    $0                                  # Run comprehensive test
    $0 --quick                          # Quick connectivity test
    $0 --region us-west-2               # Test specific region
    $0 --model anthropic.claude-instant-v1  # Test specific model

ENVIRONMENT VARIABLES:
    AWS_PROFILE             AWS profile to use
    AWS_REGION              Default AWS region
    AWS_BEDROCK_REGION      Bedrock-specific region
    AWS_BEDROCK_MODEL_ID    Model ID to test
    AWS_ACCESS_KEY_ID       AWS access key
    AWS_SECRET_ACCESS_KEY   AWS secret key
    AWS_SESSION_TOKEN       AWS session token (for temporary credentials)

TROUBLESHOOTING:
    1. Ensure AWS CLI is configured: aws configure
    2. Check IAM permissions for Bedrock access
    3. Verify region supports Bedrock service
    4. Confirm model availability in your account
EOF
}

# List supported regions
list_regions() {
    echo "Supported AWS Bedrock Regions:"
    for region in "${AWS_REGIONS[@]}"; do
        echo "  - $region"
    done
}

# List common models
list_models() {
    echo "Common AWS Bedrock Models:"
    for model in "${BEDROCK_MODELS[@]}"; do
        echo "  - $model"
    done
}

# Main function
main() {
    local quick_mode=false
    local test_region=""
    local test_model=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                quick_mode=true
                shift
                ;;
            --region)
                test_region="$2"
                shift 2
                ;;
            --model)
                test_model="$2"
                shift 2
                ;;
            --list-regions)
                list_regions
                exit 0
                ;;
            --list-models)
                list_models
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set environment variables if provided
    [[ -n "$test_region" ]] && export AWS_BEDROCK_REGION="$test_region"
    [[ -n "$test_model" ]] && export AWS_BEDROCK_MODEL_ID="$test_model"
    
    # Check prerequisites
    check_prerequisites
    
    # Run appropriate test
    if [[ "$quick_mode" == "true" ]]; then
        run_quick_test
    else
        run_comprehensive_test
    fi
}

# Execute main function
main "$@"