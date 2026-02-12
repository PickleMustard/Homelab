#!/bin/bash

# Forgejo Deployment Script
# This script deploys Forgejo in the correct order

set -e

echo "=========================================="
echo "Forgejo Deployment for k3s Homelab"
echo "=========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed or not in PATH"
    exit 1
fi

echo ""
echo "Step 1: Creating namespace..."
kubectl apply -f forgejo/create-namespace.yml

echo ""
echo "Step 2: Creating secrets..."
kubectl apply -f secrets/forgejo-secrets.yml
kubectl apply -f forgejo/forgejo-smb-secret.yml

echo ""
echo "Step 3: Creating storage resources..."
kubectl apply -f forgejo/forgejo-storageclass.yml
kubectl apply -f forgejo/forgejo-pv.yml
kubectl apply -f forgejo/forgejo-pvc.yml

echo ""
echo "Step 4: Creating PostgreSQL database init job..."
kubectl apply -f forgejo/init-db-job.yml

echo ""
echo "Waiting for database initialization (30 seconds)..."
sleep 30

echo ""
echo "Step 5: Creating SSH TCP route..."
kubectl apply -f forgejo/forgejo-ssh-tcp-route.yml

echo ""
echo "Step 6: Installing Forgejo via Helm..."
helm install forgejo -n git oci://code.forgejo.org/forgejo-helm/forgejo -f forgejo/forgejo-values.yml

echo ""
echo "=========================================="
echo "Deployment complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify deployment: kubectl get all -n git"
echo "2. Check logs: kubectl logs -f deployment/forgejo -n git"
echo "3. Access at: http://git.picklemustard.dev"
echo ""
echo "Note: Ensure git-ssh Traefik entrypoint is configured for SSH access"
echo "Note: Ensure LLDAP groups git-users and git-admin are created"
echo ""
