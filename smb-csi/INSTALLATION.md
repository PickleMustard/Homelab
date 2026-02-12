# SMB CSI Driver Helm Installation Guide

## Option 1: Using Helm (Recommended)

The SMB CSI driver can be easily installed using Helm:

```bash
# Add the CSI driver repository
helm repo add csi-driver-smb https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts
helm repo update

# Install the driver
helm install csi-driver-smb csi-driver-smb/csi-driver-smb \
  --namespace kube-system \
  --set controller.replicas=1 \
  --set linux.enabled=true \
  --set windows.enabled=false
```

## Option 2: Using the provided manifests

If you prefer to use the provided manifest files, use the installation script:

```bash
cd /app-storage/k3s
./install-smb-csi.sh
```

This script will:
1. Prompt you for SMB credentials
2. Create necessary RBAC resources
3. Create the SMB secret
4. Install the CSI driver
5. Verify the installation

## Manual Installation Steps

If you want to install manually without the script:

1. **Create SMB Secret**
   ```bash
   kubectl create secret generic media-data-creds \
     --namespace media \
     --from-literal=username=YOUR_USERNAME \
     --from-literal=password=YOUR_PASSWORD
   ```

2. **Apply RBAC**
   ```bash
   kubectl apply -f smb-csi/rbac.yaml
   ```

3. **Install CSI Driver**
   ```bash
   kubectl apply -f smb-csi/csi-smb-plugin.yaml
   ```

## Post-Installation Verification

After installation, verify the setup:

```bash
# Check CSI driver pods
kubectl get pods -n kube-system | grep smb

# Check CSIDriver
kubectl get csidriver

# Check Sonarr pods
kubectl get pods -n media
```

## Troubleshooting Common Issues

### 1. Volume attachment timeout
If you see "timed out waiting for external-attacher" error:

```bash
# Check CSI controller logs
kubectl logs -n kube-system deployment/smb-csi-controller -c smb

# Check CSI node logs
kubectl logs -n kube-system daemonset/csi-smbplugin -c smb
```

### 2. Authentication failures
Verify your SMB credentials:
```bash
kubectl get secret media-data-creds -n media -o yaml
```

### 3. Network connectivity
Check if the SMB server is reachable from the cluster:
```bash
kubectl run -it --rm debug --image=busybox -- nslookup YOUR_SMB_SERVER_IP
```

### 4. VolumeHandle mismatch
Ensure the PV's volumeHandle matches the SMB server address. The current PV uses:
```
smb-server.default.svc.cluster.local/media##
```

If you're using an external SMB server (not a Kubernetes service), update the PV's volumeHandle to:
```
YOUR_SMB_SERVER_IP/YOUR_SHARE_NAME##
```

## Current Configuration

Your existing Sonarr setup will work with the CSI driver:

- **PV**: Uses CSI driver `smb.csi.k8s.io` with volumeHandle `smb-server.default.svc.cluster.local/media##`
- **StorageClass**: `media-data` (provisioner: `smb.csi.k8s.io`)
- **PVC**: Binds to PV `media-data`
- **Secret**: `media-data-creds` in `media` namespace

The error "timed out waiting for external-attacher of smb.csi.k8s.io CSI driver" will be resolved once the CSI driver is installed.

## Quick Status Check

Run the status check script:
```bash
cd /app-storage/k3s
./check-smb-csi.sh
```

This will show you the status of all relevant components.
