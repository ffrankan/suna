#!/bin/bash

# Suna Self-Hosting Startup Script with Reverse Proxy
# This script starts all services with Nginx reverse proxy to avoid CORS issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
    else
        print_error "Neither docker-compose nor docker compose is available"
        exit 1
    fi
    print_success "Using $DOCKER_COMPOSE_CMD"
}

# Check required files
check_files() {
    local required_files=("docker-compose.yaml" "nginx.conf" "backend/.env")

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file not found: $file"
            if [[ "$file" == "backend/.env" ]]; then
                print_warning "Please copy backend/.env.example to backend/.env and configure it"
            fi
            exit 1
        fi
    done
    print_success "All required files found"
}

# Stop existing containers
stop_services() {
    print_status "Stopping existing services..."
    $DOCKER_COMPOSE_CMD down --remove-orphans 2>/dev/null || true
}

# Build and start services
start_services() {
    print_status "Building and starting services with reverse proxy..."
    $DOCKER_COMPOSE_CMD up --build -d

    # Wait for services to be healthy
    print_status "Waiting for services to be ready..."
    sleep 10

    # Check if services are running
    if $DOCKER_COMPOSE_CMD ps | grep -q "Up"; then
        print_success "Services started successfully"
    else
        print_error "Some services failed to start"
        $DOCKER_COMPOSE_CMD logs
        exit 1
    fi
}

# Display service status and URLs
show_status() {
    echo
    print_success "=== Suna is now running with reverse proxy ==="
    echo
    echo "🌐 Application URL: http://localhost"
    echo "🔧 API Health Check: http://localhost/health"
    echo "📊 Service Status:"
    echo
    $DOCKER_COMPOSE_CMD ps
    echo
    print_status "To view logs: $DOCKER_COMPOSE_CMD logs -f"
    print_status "To stop: $DOCKER_COMPOSE_CMD down"
    echo
    print_warning "Note: All requests now go through port 80 (Nginx reverse proxy)"
    print_warning "Frontend and backend are no longer directly accessible on ports 3000/8000"
}

# Wait for health check
wait_for_health() {
    print_status "Waiting for application to be healthy..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost/health >/dev/null 2>&1; then
            print_success "Application is healthy!"
            return 0
        fi

        printf "."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo
    print_warning "Health check timeout, but services may still be starting..."
    print_status "Check logs with: $DOCKER_COMPOSE_CMD logs"
}

# Main execution
main() {
    echo "🚀 Starting Suna with Reverse Proxy Setup"
    echo "=========================================="

    check_docker
    check_docker_compose
    check_files
    stop_services
    start_services
    wait_for_health
    show_status
}

# Handle script interruption
cleanup() {
    echo
    print_warning "Script interrupted. Stopping services..."
    $DOCKER_COMPOSE_CMD down
    exit 1
}

trap cleanup INT TERM

# Run main function
main "$@"
