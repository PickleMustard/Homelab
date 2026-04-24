#!/bin/bash
# OpenProject Deployment Script
# Deploys OpenProject using Helm + Kustomize to work around init-container tmp volume issue

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="collab"
CHART_REPO="openproject/openproject"
RELEASE_NAME="openproject"
VALUES_FILE="values.yml"
RENDERED_FILE="rendered-manifests.yaml"
HOST_TMP_DIR="/tmp/openproject-tmp"
HOST_APP_TMP_DIR="/tmp/openproject-app-tmp"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi

    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed"
        exit 1
    fi

    # Check kustomize
    if ! command -v kustomize &> /dev/null; then
        print_error "kustomize is not installed"
        print_info "Install kustomize:"
        echo "  curl -s https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash"
        exit 1
    fi

    print_info "All prerequisites installed ✓"
}

# Check if helm repo is added
check_helm_repo() {
    print_info "Checking Helm repository..."

    if ! helm repo list | grep -q "^openproject"; then
        print_info "Adding OpenProject Helm repository..."
        helm repo add openproject https://charts.openproject.org
        helm repo update
    else
        print_info "Helm repository already added ✓"
    fi
}

# Prepare hostPath directories on node
prepare_host_directories() {
    print_info "Preparing hostPath directories on andromeda-alpheratz..."

    # Try to connect to node
    if ssh -o ConnectTimeout=5 andromeda-alpheratz exit &> /dev/null; then
        ssh andromeda-alpheratz << 'ENDSSH'
            # Create directories
            echo "Creating directories..."
            sudo mkdir -p /tmp/openproject-tmp /tmp/openproject-app-tmp

            # Set ownership to UID 1000 (OpenProject user)
            echo "Setting ownership to 1000:1000..."
            sudo chown -R 1000:1000 /tmp/openproject-tmp /tmp/openproject-app-tmp

            # Set permissions with sticky bit
            echo "Setting permissions with sticky bit..."
            sudo chmod 1777 /tmp/openproject-tmp /tmp/openproject-app-tmp

            echo "Directories prepared successfully ✓"
ENDSSH
        print_info "HostPath directories prepared on node ✓"
    else
        print_warn "Cannot SSH to andromeda-alpheratz"
        print_info "Please prepare directories manually:"
        echo "  sudo mkdir -p $HOST_TMP_DIR $HOST_APP_TMP_DIR"
        echo "  sudo chown -R 1000:1000 $HOST_TMP_DIR $HOST_APP_TMP_DIR"
        echo "  sudo chmod 1777 $HOST_TMP_DIR $HOST_APP_TMP_DIR"
        read -p "Press Enter to continue..."
    fi
}

# Render Helm templates
render_helm_templates() {
    print_info "Rendering Helm templates..."

    helm template $RELEASE_NAME $CHART_REPO \
        -f $VALUES_FILE \
        --namespace $NAMESPACE \
        > $RENDERED_FILE

    if [ $? -eq 0 ]; then
        print_info "Helm templates rendered to $RENDERED_FILE ✓"
    else
        print_error "Failed to render Helm templates"
        exit 1
    fi
}

# Apply with Kustomize
apply_manifests() {
    print_info "Applying manifests with Kustomize..."

    kustomize build . | kubectl apply -f -

    if [ $? -eq 0 ]; then
        print_info "Manifests applied successfully ✓"
    else
        print_error "Failed to apply manifests"
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    print_info "Verifying deployment..."

    echo ""
    echo "Waiting for pods to be ready..."
    echo ""

    kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$RELEASE_NAME -w

    echo ""
    print_info "Deployment status:"
    kubectl get deployments -n $NAMESPACE

    print_info "Pod status:"
    kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$RELEASE_NAME -o wide
}

# Cleanup existing rendered file
cleanup() {
    print_info "Cleaning up old rendered file..."
    rm -f $RENDERED_FILE
}

# Main deployment flow
main() {
    echo ""
    echo "=========================================="
    echo "  OpenProject Deployment Script"
    echo "  Helm + Kustomize"
    echo "=========================================="
    echo ""

    check_prerequisites
    check_helm_repo
    prepare_host_directories

    echo ""
    read -p "Continue with deployment? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warn "Deployment cancelled"
        exit 0
    fi

    cleanup
    render_helm_templates
    apply_manifests
    verify_deployment

    echo ""
    print_info "Deployment complete! ✓"
    echo ""
    print_info "Access OpenProject at:"
    echo "  https://andromeda.picklemustard.dev/collab/plan"
    echo ""
    print_info "View logs:"
    echo "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=$RELEASE_NAME -c openproject"
    echo ""
}

# Run main function
main
