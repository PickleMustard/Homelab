# Jellyfin - Media Server

**Namespace:** `media`

**URL:** https://jellyfin.picklemustard.dev

**Port:** 8096

---

## Overview

Jellyfin is a free software media system that provides streaming of media files. It serves as the central media server for the homelab, supporting video transcoding, live TV, and music streaming.

---

## Configuration Files

- `jellyfin/deployment.yml` - Main deployment
- `jellyfin/service.yml` - Service definition
- `jellyfin/ingress.yml` - HTTP ingress
- `jellyfin/pvc.yml` - 10Gi PVC for configuration
- `jellyfin/configmap.yml` - System configuration

---

## Deployment

```bash
# Create namespace
kubectl create namespace media

# Apply all Jellyfin configurations
kubectl apply -f jellyfin/
```

---

## Storage

### Persistent Volume Claims

| PVC Name | Size | Mount Path | Purpose |
|----------|------|------------|---------|
| `media-data` | Varies | `/data` | Media files (movies, TV, music) |
| `jellyfin-data` | 10Gi | `/config` (subPath: `jellyfin-config`) | Application configuration |
| `system-config-volume` | ConfigMap | `/config/system.xml` | System configuration |

### Storage Class
All PVCs use the `local-path` storage class.

---

## Hardware Acceleration

Jellyfin is configured with NVIDIA GPU support for hardware-accelerated transcoding:

```yaml
resources:
  limits:
    nvidia.com/gpu: 1
```

This enables:
- Faster transcoding for incompatible formats
- Lower CPU usage during playback
- Better performance for 4K content

---

## Configuration

### System Configuration
The system configuration is stored in a ConfigMap (`jellyfin-system-config`) and mounted to `/config/system.xml`.

### Environment Variables
No specific environment variables are configured. Jellyfin uses its configuration files stored in `/config`.

---

## Access

### Web Interface
URL: https://jellyfin.picklemustard.dev

### Direct Streaming
- **HTTP:** http://jellyfin.picklemustard.dev:8096
- **HTTPS:** https://jellyfin.picklemustard.dev

### Clients
Jellyfin clients are available for:
- Web browsers
- Android / iOS
- Smart TVs (Android TV, Samsung, LG)
- Desktop (Windows, macOS, Linux)
- Media players (Kodi, Roku)

---

## Management

### Check Status
```bash
kubectl get pods -n media
kubectl logs -f deployment/jellyfin -n media
```

### Access Shell
```bash
kubectl exec -it deployment/jellyfin -n media -- /bin/sh
```

### Check GPU Usage
```bash
kubectl exec -n media deployment/jellyfin -- nvidia-smi
```

---

## Troubleshooting

### Transcoding Issues
1. Check GPU is accessible: `kubectl exec -n media deployment/jellyfin -- nvidia-smi`
2. Verify NVIDIA runtime is installed on the node
3. Check transcoding logs in Jellyfin Dashboard
4. Ensure media files have correct permissions

### Storage Issues
1. Verify PVCs are bound: `kubectl get pvc -n media`
2. Check storage class: `kubectl get storageclass`
3. Ensure media files are accessible: `kubectl exec -n media deployment/jellyfin -- ls -la /data`

### Performance Issues
1. Monitor GPU usage: `kubectl exec -n media deployment/jellyfin -- nvidia-smi -l 1`
2. Check CPU/memory usage: `kubectl top pod -n media`
3. Review transcoding settings in Jellyfin

### Cannot Access Web Interface
1. Check pod status: `kubectl get pods -n media`
2. Verify service: `kubectl get svc -n media`
3. Check ingress: `kubectl get ingress -n media`

---

## Backup

### Backup Configuration
```bash
# Backup Jellyfin config
kubectl exec -n media deployment/jellyfin -- tar czf /tmp/jellyfin-config-backup.tar.gz /config
kubectl cp -n media deployment/jellyfin:/tmp/jellyfin-config-backup.tar.gz ./jellyfin-config-backup.tar.gz
```

### Backup Media
Media files are stored in a separate PVC (`media-data`). Back up this volume regularly using your backup solution.

---

## Upgrade

```bash
# Update image tag
kubectl set image deployment/jellyfin jellyfin=jellyfin/jellyfin:<version> -n media

# Watch rollout
kubectl rollout status deployment/jellyfin -n media
```

---

## Recommended Settings

### Transcoding
- Enable hardware acceleration (NVENC)
- Set preferred video codec: H.264
- Enable tone mapping for HDR content

### Library Setup
- Organize media in standard structure:
  - `/data/Movies/` - Movies
  - `/data/TV Shows/` - TV series
  - `/data/Music/` - Music files
- Enable metadata fetching (TheMovieDB, TVDB, MusicBrainz)

### Network
- Enable remote access if needed
- Configure bandwidth limits for external users
- Enable HTTPS for secure connections

---

## Integration with Starr Services

Jellyfin integrates with:
- **Sonarr** - Automatically imports downloaded TV shows
- **Radarr** - Automatically imports downloaded movies

The Starr services should be configured to use the same `media-data` PVC or mount path.

---

## Notes

- Jellyfin uses GPU acceleration for transcoding
- Configuration is stored in a subPath on the PVC (`jellyfin-config`)
- System configuration is managed via ConfigMap
- Media files are stored separately from configuration
