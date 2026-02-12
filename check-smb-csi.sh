#!/bin/bash

# SMB CSI Driver Status Check Script

echo "======================================"
echo "SMB CSI Driver Status Check"
echo "======================================"
echo ""

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to the cluster"
    exit 1
fi

echo "1. CSI Driver Pods (kube-system):"
echo "-----------------------------------"
kubectl get pods -n kube-system -l app=csi-smbplugin 2>/dev/null || echo "No CSI node plugin pods found"
kubectl get pods -n kube-system -l app=smb-csi-controller 2>/dev/null || echo "No CSI controller pods found"
echo ""

echo "2. CSI Driver Status:"
echo "-----------------------------------"
kubectl get csidriver 2>/dev/null || echo "No CSI drivers found"
echo ""

echo "3. SMB Secrets (media namespace):"
echo "-----------------------------------"
kubectl get secrets -n media 2>/dev/null | grep -E "(NAME|media-data)" || echo "No SMB secrets found in media namespace"
echo ""

echo "4. Storage Classes:"
echo "-----------------------------------"
kubectl get storageclass 2>/dev/null || echo "No storage classes found"
echo ""

echo "5. Persistent Volumes:"
echo "-----------------------------------"
kubectl get pv 2>/dev/null | grep media-data || echo "No media-data PV found"
echo ""

echo "6. Persistent Volume Claims (media namespace):"
echo "-----------------------------------"
kubectl get pvc -n media 2>/dev/null || echo "No PVCs found in media namespace"
echo ""

echo "7. Sonarr Pods (media namespace):"
echo "-----------------------------------"
kubectl get pods -n media 2>/dev/null || echo "No pods found in media namespace"
echo ""

echo "8. Recent Events (media namespace):"
echo "-----------------------------------"
kubectl get events -n media --sort-by=.metadata.creationTimestamp 2>/dev/null | tail -10 || echo "No events found"
echo ""

echo "9. Detailed Volume Attachment Status:"
echo "-----------------------------------"
kubectl get volumeattachments 2>/dev/null || echo "No volume attachments found"
echo ""

# Check if there are any failing pods
echo "10. Failing Pods (all namespaces):"
echo "-----------------------------------"
kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | grep -v "NAMESPACE" || echo "No failing pods"
echo ""

echo "======================================"
echo "Check Complete!"
echo "======================================"
echo ""
echo "If you see issues with the Sonarr pod, run:"
echo "  kubectl describe pod -l app.kubernetes.io/name=sonarr -n media"
echo ""
echo "To view CSI controller logs:"
echo "  kubectl logs -n kube-system deployment/smb-csi-controller -c smb"
echo ""
echo "To view CSI node logs:"
echo "  kubectl logs -n kube-system daemonset/csi-smbplugin -c smb"
echo ""
