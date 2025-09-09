#!/bin/bash

# PyPI Package Publisher Script
# Builds and publishes eoddata package to PyPI or TestPyPI
# Usage: ./publish.sh [test|prod]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
PACKAGE_NAME="eoddata-client"
DIST_DIR="dist"
BUILD_DIR="build"
EGG_INFO_DIR="src/${PACKAGE_NAME}.egg-info"

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [test|prod]"
    echo ""
    echo "Options:"
    echo "  test    Publish to test.pypi.org"
    echo "  prod    Publish to pypi.org (production)"
    echo ""
    echo "Environment Variables Required:"
    echo "  PYPI_TEST_API_KEY  - API key for test.pypi.org"
    echo "  PYPI_API_KEY       - API key for pypi.org"
}

# Function to validate environment variables
validate_env_vars() {
    if [[ -z "$PYPI_TEST_API_KEY" ]]; then
        print_error "PYPI_TEST_API_KEY environment variable is not set"
        return 1
    fi
    
    if [[ -z "$PYPI_API_KEY" ]]; then
        print_error "PYPI_API_KEY environment variable is not set"
        return 1
    fi
    
    print_success "Environment variables validated"
    return 0
}

# Function to clean up build artifacts
cleanup_artifacts() {
    print_status "Cleaning up existing build artifacts..."
    
    # Remove distribution directory
    if [[ -d "$DIST_DIR" ]]; then
        rm -rf "$DIST_DIR"
        print_status "Removed $DIST_DIR directory"
    fi
    
    # Remove build directory
    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
        print_status "Removed $BUILD_DIR directory"
    fi
    
    # Remove egg-info directory
    if [[ -d "$EGG_INFO_DIR" ]]; then
        rm -rf "$EGG_INFO_DIR"
        print_status "Removed $EGG_INFO_DIR directory"
    fi
    
    # Remove any __pycache__ directories
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    
    # Remove any .pyc files
    find . -type f -name "*.pyc" -delete 2>/dev/null || true
    
    print_success "Build artifacts cleaned up"
}

# Function to get current version from pyproject.toml
get_current_version() {
    if [[ -f "pyproject.toml" ]]; then
        version=$(grep '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')
        echo "$version"
    else
        print_error "pyproject.toml not found"
        return 1
    fi
}

# Function to run pre-publish checks
run_checks() {
    print_status "Running pre-publish checks..."
    
    # Check if we're in a git repository and if there are uncommitted changes
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if ! git diff-index --quiet HEAD --; then
            print_warning "You have uncommitted changes. Consider committing them first."
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Aborted by user"
                exit 1
            fi
        fi
    fi
    
    # Check if virtual environment is activated
    if [[ -z "$VIRTUAL_ENV" ]] && [[ -z "$CONDA_DEFAULT_ENV" ]]; then
        print_warning "No virtual environment detected. It's recommended to use a virtual environment."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Aborted by user"
            exit 1
        fi
    fi
    
    # Run tests if available
    if command -v python >/dev/null 2>&1; then
        if python -m pytest --version >/dev/null 2>&1 && [[ -d "tests" ]]; then
            print_status "Running tests..."
            if ! python -m pytest tests/ -x; then
                print_error "Tests failed. Please fix them before publishing."
                exit 1
            fi
            print_success "All tests passed"
        else
            print_warning "No pytest or tests directory found, skipping tests"
        fi
    fi
    
    print_success "Pre-publish checks completed"
}

# Function to build the package
build_package() {
    print_status "Building package..."
    
    # Ensure build tools are available
    if ! python -m build --version >/dev/null 2>&1; then
        print_error "python build module not found. Install it with: pip install build"
        exit 1
    fi
    
    # Build the package
    python -m build
    
    if [[ ! -d "$DIST_DIR" ]] || [[ -z "$(ls -A $DIST_DIR)" ]]; then
        print_error "Build failed - no files in $DIST_DIR directory"
        exit 1
    fi
    
    print_success "Package built successfully"
    
    # Show built files
    print_status "Built files:"
    ls -la "$DIST_DIR"
}

# Function to publish to PyPI
publish_package() {
    local target=$1
    local repository_url=""
    local api_key=""
    
    if [[ "$target" == "test" ]]; then
        repository_url="https://test.pypi.org/legacy/"
        api_key="$PYPI_TEST_API_KEY"
        print_status "Publishing to test.pypi.org..."
    elif [[ "$target" == "prod" ]]; then
        repository_url="https://upload.pypi.org/legacy/"
        api_key="$PYPI_API_KEY"
        print_status "Publishing to pypi.org (PRODUCTION)..."
    else
        print_error "Invalid target: $target"
        exit 1
    fi
    
    # Ensure twine is available
    if ! python -m twine --version >/dev/null 2>&1; then
        print_error "twine not found. Install it with: pip install twine"
        exit 1
    fi
    
    # Upload using twine
    python -m twine upload \
        --repository-url "$repository_url" \
        --username __token__ \
        --password "$api_key" \
        "$DIST_DIR"/*
    
    if [[ $? -eq 0 ]]; then
        print_success "Package published successfully to $target"
        
        # Show installation instructions
        local version=$(get_current_version)
        if [[ "$target" == "test" ]]; then
            echo ""
            print_status "To install from test PyPI:"
            echo "pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple/ ${PACKAGE_NAME}==${version}"
        else
            echo ""
            print_status "To install from PyPI:"
            echo "pip install ${PACKAGE_NAME}==${version}"
        fi
    else
        print_error "Failed to publish package to $target"
        exit 1
    fi
}

# Function to confirm production deployment
confirm_production() {
    local version=$(get_current_version)
    echo ""
    print_warning "⚠️  PRODUCTION DEPLOYMENT ⚠️"
    echo "You are about to publish version $version to the PRODUCTION PyPI (pypi.org)"
    echo "This action cannot be undone!"
    echo ""
    read -p "Are you absolutely sure you want to proceed? Type 'YES' to confirm: " -r
    echo
    if [[ "$REPLY" != "YES" ]]; then
        print_error "Production deployment cancelled"
        exit 1
    fi
}

# Main script logic
main() {
    echo "🚀 PyPI Package Publisher"
    echo "========================="
    
    # Check arguments
    if [[ $# -ne 1 ]]; then
        show_usage
        exit 1
    fi
    
    local target=$1
    
    if [[ "$target" != "test" ]] && [[ "$target" != "prod" ]]; then
        print_error "Invalid target: $target"
        show_usage
        exit 1
    fi
    
    # Validate environment variables
    if ! validate_env_vars; then
        exit 1
    fi
    
    # Show current version
    local version=$(get_current_version)
    print_status "Current package version: $version"
    
    # Confirm production deployment
    if [[ "$target" == "prod" ]]; then
        confirm_production
    fi
    
    # Clean up previous build artifacts
    cleanup_artifacts
    
    # Run pre-publish checks
    run_checks
    
    # Build the package
    build_package
    
    # Publish the package
    publish_package "$target"
    
    print_success "✅ Deployment completed successfully!"
}

# Run main function with all arguments
main "$@"