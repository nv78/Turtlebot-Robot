#!/bin/bash

# Navy Autonomous Deployment Script
# Supports deployment to staging and production environments

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployment"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

usage() {
    echo "Usage: $0 <environment> <version>"
    echo ""
    echo "Environments:"
    echo "  development  - Local development deployment"
    echo "  staging      - Staging environment deployment"
    echo "  production   - Production environment deployment"
    echo ""
    echo "Version:"
    echo "  Git commit hash, tag, or 'latest'"
    echo ""
    echo "Examples:"
    echo "  $0 staging v1.0.0"
    echo "  $0 production abc123def"
    echo "  $0 development latest"
    exit 1
}

validate_environment() {
    local env=$1
    
    case $env in
        development|staging|production)
            log_info "Deploying to $env environment"
            ;;
        *)
            log_error "Invalid environment: $env"
            usage
            ;;
    esac
}

check_prerequisites() {
    local env=$1
    
    log_info "Checking prerequisites for $env deployment..."
    
    # Check required tools
    local required_tools=("docker" "kubectl")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is required but not installed"
            exit 1
        fi
    done
    
    # Check Kubernetes connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check Docker registry access
    if [ "$env" != "development" ]; then
        if ! docker info &> /dev/null; then
            log_error "Docker daemon not running"
            exit 1
        fi
    fi
    
    log_success "Prerequisites check passed"
}

prepare_configuration() {
    local env=$1
    local version=$2
    
    log_info "Preparing configuration for $env deployment..."
    
    # Create environment-specific configuration
    local config_dir="$DEPLOYMENT_DIR/$env"
    local temp_config_dir="/tmp/navy-autonomous-config-$env"
    
    rm -rf "$temp_config_dir"
    mkdir -p "$temp_config_dir"
    
    # Copy base configuration
    cp -r "$config_dir"/* "$temp_config_dir/" 2>/dev/null || true
    
    # Update image version in Kubernetes manifests
    if [ -f "$PROJECT_ROOT/k8s/navy-autonomous-deployment.yaml" ]; then
        sed "s|ghcr.io/your-org/navy-autonomous:latest|ghcr.io/your-org/navy-autonomous:$version|g" \
            "$PROJECT_ROOT/k8s/navy-autonomous-deployment.yaml" > "$temp_config_dir/deployment.yaml"
    fi
    
    # Set environment-specific configuration
    case $env in
        production)
            export NAVY_MODE="full_autonomous"
            export REPLICA_COUNT=1
            export RESOURCE_REQUESTS_CPU="1000m"
            export RESOURCE_REQUESTS_MEMORY="2Gi"
            export RESOURCE_LIMITS_CPU="2000m"
            export RESOURCE_LIMITS_MEMORY="4Gi"
            ;;
        staging)
            export NAVY_MODE="semi_autonomous"
            export REPLICA_COUNT=1
            export RESOURCE_REQUESTS_CPU="500m"
            export RESOURCE_REQUESTS_MEMORY="1Gi"
            export RESOURCE_LIMITS_CPU="1000m"
            export RESOURCE_LIMITS_MEMORY="2Gi"
            ;;
        development)
            export NAVY_MODE="test_yolo"
            export REPLICA_COUNT=1
            export RESOURCE_REQUESTS_CPU="250m"
            export RESOURCE_REQUESTS_MEMORY="512Mi"
            export RESOURCE_LIMITS_CPU="500m"
            export RESOURCE_LIMITS_MEMORY="1Gi"
            ;;
    esac
    
    log_success "Configuration prepared"
}

deploy_kubernetes() {
    local env=$1
    local version=$2
    
    log_info "Deploying to Kubernetes ($env)..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace navy-autonomous --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply Kubernetes manifests
    if [ -f "/tmp/navy-autonomous-config-$env/deployment.yaml" ]; then
        kubectl apply -f "/tmp/navy-autonomous-config-$env/deployment.yaml"
    else
        kubectl apply -f "$PROJECT_ROOT/k8s/"
    fi
    
    # Wait for deployment to be ready
    log_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/navy-autonomous -n navy-autonomous --timeout=300s
    
    # Check deployment health
    local pod_name=$(kubectl get pods -n navy-autonomous -l app=navy-autonomous -o jsonpath='{.items[0].metadata.name}')
    
    if [ -n "$pod_name" ]; then
        log_info "Checking pod health..."
        kubectl wait --for=condition=ready pod/"$pod_name" -n navy-autonomous --timeout=120s
        log_success "Pod is ready: $pod_name"
    else
        log_error "No pods found for deployment"
        exit 1
    fi
}

deploy_docker_compose() {
    local env=$1
    local version=$2
    
    log_info "Deploying with Docker Compose ($env)..."
    
    local compose_file="$DEPLOYMENT_DIR/$env/docker-compose.yml"
    
    if [ ! -f "$compose_file" ]; then
        log_error "Docker Compose file not found: $compose_file"
        exit 1
    fi
    
    # Set environment variables
    export NAVY_IMAGE_VERSION="$version"
    export NAVY_MODE="${NAVY_MODE:-semi_autonomous}"
    
    # Deploy with Docker Compose
    docker-compose -f "$compose_file" down --remove-orphans || true
    docker-compose -f "$compose_file" pull
    docker-compose -f "$compose_file" up -d
    
    # Wait for services to be healthy
    log_info "Waiting for services to be healthy..."
    sleep 10
    
    # Check service health
    if docker-compose -f "$compose_file" ps | grep -q "Up (healthy)"; then
        log_success "Services are healthy"
    else
        log_warning "Some services may not be fully healthy"
        docker-compose -f "$compose_file" ps
    fi
}

run_post_deployment_tests() {
    local env=$1
    
    log_info "Running post-deployment tests..."
    
    case $env in
        kubernetes)
            # Test Kubernetes deployment
            local pod_name=$(kubectl get pods -n navy-autonomous -l app=navy-autonomous -o jsonpath='{.items[0].metadata.name}')
            if [ -n "$pod_name" ]; then
                kubectl exec "$pod_name" -n navy-autonomous -- /healthcheck.sh
            fi
            ;;
        docker-compose)
            # Test Docker Compose deployment
            if docker-compose -f "$DEPLOYMENT_DIR/$env/docker-compose.yml" exec -T navy-autonomous /healthcheck.sh; then
                log_success "Health check passed"
            else
                log_error "Health check failed"
                return 1
            fi
            ;;
    esac
    
    log_success "Post-deployment tests passed"
}

cleanup_temporary_files() {
    local env=$1
    
    log_info "Cleaning up temporary files..."
    rm -rf "/tmp/navy-autonomous-config-$env"
    log_success "Cleanup complete"
}

main() {
    local environment=${1:-}
    local version=${2:-latest}
    
    if [ $# -lt 1 ]; then
        usage
    fi
    
    log_info "Starting deployment of Navy Autonomous"
    log_info "Environment: $environment"
    log_info "Version: $version"
    log_info "Timestamp: $(date)"
    
    validate_environment "$environment"
    check_prerequisites "$environment"
    prepare_configuration "$environment" "$version"
    
    # Choose deployment method based on environment
    case $environment in
        production|staging)
            deploy_kubernetes "$environment" "$version"
            run_post_deployment_tests "kubernetes"
            ;;
        development)
            deploy_docker_compose "$environment" "$version"
            run_post_deployment_tests "docker-compose"
            ;;
    esac
    
    cleanup_temporary_files "$environment"
    
    log_success "Deployment completed successfully!"
    log_info "Environment: $environment"
    log_info "Version: $version"
    log_info "Access your deployment and check the logs for any issues."
}

# Script execution
main "$@" 