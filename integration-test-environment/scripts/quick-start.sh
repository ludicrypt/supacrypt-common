#!/bin/bash

# Supacrypt Integration Test Environment - Quick Start
# This script sets up the complete test environment for end-to-end testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🚀 Starting Supacrypt Integration Test Environment Setup"
echo "Project Root: $PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    command -v docker >/dev/null 2>&1 || { 
        log_error "Docker is required but not installed. Please install Docker and try again."
        exit 1
    }
    
    command -v docker-compose >/dev/null 2>&1 || { 
        log_error "Docker Compose is required but not installed. Please install Docker Compose and try again."
        exit 1
    }
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running. Please start Docker and try again."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Check component implementation status
check_component_status() {
    log_info "Checking component implementation status..."
    
    # Backend Service
    if [[ -f "$PROJECT_ROOT/supacrypt-backend-akv/Supacrypt.Backend.sln" ]]; then
        log_success "Backend service: Ready for testing"
    else
        log_error "Backend service not found"
        exit 1
    fi
    
    # PKCS#11
    if [[ -f "$PROJECT_ROOT/supacrypt-pkcs11/CMakeLists.txt" ]]; then
        log_success "PKCS#11 provider: Available for testing"
    else
        log_warning "PKCS#11 provider not fully implemented"
    fi
    
    # CSP
    if [[ -f "$PROJECT_ROOT/supacrypt-csp/CMakeLists.txt" ]]; then
        log_warning "CSP provider: Partial implementation - limited testing"
    else
        log_warning "CSP provider not available"
    fi
    
    # KSP  
    if [[ -f "$PROJECT_ROOT/supacrypt-ksp/CMakeLists.txt" ]]; then
        log_warning "KSP provider: Partial implementation - limited testing"
    else
        log_warning "KSP provider not available"
    fi
    
    # CTK
    if [[ -f "$PROJECT_ROOT/supacrypt-ctk/Package.swift" ]]; then
        log_success "CTK provider: Available for testing"
    else
        log_warning "CTK provider not available"
    fi
}

# Setup test certificates
setup_certificates() {
    log_info "Setting up test certificates..."
    
    # Check if backend has certificate generation script
    if [[ -f "$PROJECT_ROOT/supacrypt-backend-akv/scripts/generate-dev-certs.sh" ]]; then
        cd "$PROJECT_ROOT/supacrypt-backend-akv"
        chmod +x scripts/generate-dev-certs.sh
        ./scripts/generate-dev-certs.sh
        log_success "Development certificates generated"
    else
        log_warning "Certificate generation script not found - using default certificates"
    fi
}

# Create test configuration
create_test_configs() {
    log_info "Creating test configurations..."
    
    mkdir -p "$SCRIPT_DIR/../configs/backend"
    mkdir -p "$SCRIPT_DIR/../configs"
    
    # Backend configuration for testing
    cat > "$SCRIPT_DIR/../configs/backend/appsettings.Testing.json" << EOF
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AzureKeyVault": {
    "VaultUrl": "https://test-vault.vault.azure.net/",
    "UseManagedIdentity": false,
    "UseLocalEmulator": true
  },
  "Security": {
    "RequireClientCertificate": false,
    "AllowedCertificateThumbprints": []
  },
  "Observability": {
    "EnableMetrics": true,
    "EnableTracing": true,
    "EnableHealthChecks": true
  }
}
EOF

    # Prometheus configuration
    cat > "$SCRIPT_DIR/../configs/prometheus.yml" << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'supacrypt-backend'
    static_configs:
      - targets: ['supacrypt-backend:5000']
    metrics_path: '/metrics'
    
  - job_name: 'test-orchestrator'
    static_configs:
      - targets: ['test-orchestrator:8080']
EOF

    log_success "Test configurations created"
}

# Build components that are ready
build_components() {
    log_info "Building available components..."
    
    # Build backend service
    if [[ -f "$PROJECT_ROOT/supacrypt-backend-akv/Dockerfile.development" ]]; then
        log_info "Building backend service..."
        cd "$PROJECT_ROOT/supacrypt-backend-akv"
        docker build -f Dockerfile.development -t supacrypt-backend:test .
        log_success "Backend service built"
    fi
    
    # Build PKCS#11 if available
    if [[ -f "$PROJECT_ROOT/supacrypt-pkcs11/build.sh" ]]; then
        log_info "Building PKCS#11 provider..."
        cd "$PROJECT_ROOT/supacrypt-pkcs11"
        chmod +x build.sh
        # Note: This would need actual build in real scenario
        log_warning "PKCS#11 build skipped - needs full implementation"
    fi
}

# Start the test environment
start_environment() {
    log_info "Starting integration test environment..."
    
    cd "$SCRIPT_DIR/.."
    
    # Pull required images
    docker-compose pull azurite prometheus grafana
    
    # Start the environment
    docker-compose up -d
    
    # Wait for services to be healthy
    log_info "Waiting for services to start..."
    sleep 30
    
    # Check service health
    if curl -f http://localhost:5000/health >/dev/null 2>&1; then
        log_success "Backend service is healthy"
    else
        log_error "Backend service health check failed"
        docker-compose logs supacrypt-backend
        exit 1
    fi
    
    log_success "Integration test environment is ready"
}

# Display access information
show_access_info() {
    echo ""
    echo "🎉 Supacrypt Integration Test Environment is ready!"
    echo ""
    echo "Service URLs:"
    echo "  Backend API: http://localhost:5000"
    echo "  Backend gRPC: localhost:5051"
    echo "  Prometheus: http://localhost:9090"
    echo "  Grafana: http://localhost:3000 (admin/supacrypt)"
    echo ""
    echo "Next steps:"
    echo "  1. Run integration tests: ./scripts/run-integration-tests.sh"
    echo "  2. View logs: docker-compose logs -f"
    echo "  3. Stop environment: docker-compose down"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    check_component_status
    setup_certificates
    create_test_configs
    build_components
    start_environment
    show_access_info
}

# Run main function
main "$@"