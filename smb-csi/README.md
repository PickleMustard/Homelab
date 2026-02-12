# SMB CSI Driver Setup for k3s

## Overview
This directory contains configuration files to install and configure the SMB CSI driver on k3s, enabling the Sonarr stack to use SMB-mounted PVCs.

## Files

1. **rbac.yaml** - RBAC configuration for CSI driver service accounts and permissions
2. **smb-secret.yaml** - SMB credentials secret (update with actual credentials)
3. **csi-smb-configmap.yaml** - CSI driver configuration
4. **csi-smb-plugin.yaml** - CSI driver deployment (daemonset and controller)
5. **smb-server.yaml** - Optional SMB server deployment for testing

## Installation Steps

### 1. Create Namespace and RBAC
```bash
kubectl apply -f rbac.yaml
```

### 2. Configure SMB Credentials
Edit `smb-secret.yaml` with your actual SMB credentials:
```bash
nano smb-secret.yaml
# Update YOUR_SMB_USERNAME and YOUR_SMB_PASSWORD
```

Then apply the secret:
```bash
kubectl apply -f smb-secret.yaml
```

### 3. Install CSI Driver
```bash
kubectl apply -f csi-smb-configmap.yaml
kubectl apply -f csi-smb-plugin.yaml
```

### 4. Verify Installation
```bash
# Check CSI driver pods
kubectl get pods -n kube-system | grep smb

# Check CSIDriver
kubectl get csidriver

# Check storage classes
kubectl get storageclass
```

### 5. (Optional) Deploy SMB Server for Testing
If you need to deploy an SMB server within the cluster:
```bash
# Update smb-server.yaml with your storage path
nano smb-server.yaml

# Deploy
kubectl apply -f smb-server.yaml
```

## Troubleshooting

### Driver Not Attaching Volumes
```bash
# Check CSI controller logs
kubectl logs -n kube-system deployment/smb-csi-controller

# Check CSI node plugin logs
kubectl logs -n kube-system daemonset/csi-smbplugin

# Check pod events
kubectl describe pod <pod-name> -n media
```

### Verify SMB Connection
```bash
# Test SMB connectivity from a pod
kubectl run -it --rm --restart=Never debug --image=busybox -- nslookup smb-server.default.svc.cluster.local
```

### Check PVC Status
```bash
kubectl get pvc -n media
kubectl describe pvc media-data -n media
```

### Check PV Status
```bash
kubectl get pv
kubectl describe pv media-data
```

## Notes

- The CSI driver is installed in `kube-system` namespace
- SMB secrets are stored in the `media` namespace
- The driver version is v1.11.0 (latest stable)
- The volume handle format: `smb-server.default.svc.cluster.local/media##`

## Existing Configuration

Your existing Sonarr configuration will work once the driver is installed:
- PV: `k3s/starr-config/sonarr/media-pv.yml`
- PVC: `k3s/starr-config/sonarr/sonarr-pvc.yml`
- StorageClass: `k3s/starr-config/sonarr/smb-persistent-claim.yml`

The PVC references the CSI driver `smb.csi.k8s.io` which will be available after installation.
