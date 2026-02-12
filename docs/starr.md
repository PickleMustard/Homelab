# Starr Stack - Media Management

**Namespace:** `media`

---

## Overview

The Starr stack consists of media management tools that automate the downloading and organizing of media content. The stack includes Sonarr (TV shows), Radarr (movies), and potentially other *arr applications.

---

## Configuration Files

- `starr-config/` - Starr stack configuration directory
- `starr-config/sonarr/` - Sonarr-specific configurations

---

## Deployment

The Starr stack services are typically deployed using Helm or manual Kubernetes deployments. Configuration files are prepared in the `starr-config/` directory.

---

## Services

### Sonarr
- **Purpose:** TV series management and automation
- **Features:**
  - Automatic TV show downloading
  - Episode metadata fetching
  - Quality profiles
  - Release searching
  - Integration with download clients
  - Integration with Jellyfin

### Radarr
- **Purpose:** Movie management and automation
- **Features:**
  - Automatic movie downloading
  - Movie metadata fetching
  - Quality profiles
  - Release searching
  - Integration with download clients
  - Integration with Jellyfin

### Potential Other Services
- **Lidarr** - Music management
- **Readarr** - Book management
- **Bazarr** - Subtitle management

---

## Configuration

### Sonarr Configuration (`starr-config/sonarr/`)

Sonarr-specific configuration files:
- `config.xml` - Main configuration
- Database files
- `nzbget.conf` - Usenet client configuration (if used)
- `transmission.json` - Torrent client configuration (if used)

### Common Settings

**Quality Profiles:**
- Define preferred video quality
- Set cutoff for automatic upgrades
- Configure allowed and rejected qualities

**Download Clients:**
- Configure torrent client (Transmission, qBittorrent, etc.)
- Configure Usenet client (NZBGet, SABnzbd)
- Set download paths

**Import Settings:**
- Configure watch directories
- Set up automatic import from download clients
- Configure completed handling

**Metadata:**
- Enable metadata fetching
- Configure metadata providers (TheTVDB, etc.)

---

## Access

### Sonarr
URL: https://sonarr.picklemustard.dev (if configured)

### Radarr
URL: https://radarr.picklemustard.dev (if configured)

---

## Integration

### Jellyfin
The Starr stack integrates with Jellyfin for media playback:
- **Series Path:** `/data/TV Shows/` (Jellyfin media storage)
- **Movies Path:** `/data/Movies/` (Jellyfin media storage)
- **Automatic Import:** New downloads are automatically imported by Jellyfin

### Download Clients

#### Torrent Clients
- **Transmission:** Lightweight torrent client
- **qBittorrent:** Feature-rich torrent client
- **Deluge:** Plugin-based torrent client

#### Usenet Clients
- **NZBGet:** Lightweight Usenet client
- **SABnzbd:** Feature-rich Usenet client

### Indexers

Configure indexers for searching releases:
- **Jackett** - Torrent indexer aggregator
- **Prowlarr** - Indexer manager
- Individual tracker RSS feeds

---

## Management

### Check Status
```bash
kubectl get pods -n media
kubectl logs -f deployment/sonarr -n media
kubectl logs -f deployment/radarr -n media
```

### Access Shell
```bash
kubectl exec -it deployment/sonarr -n media -- /bin/sh
```

---

## Troubleshooting

### Service Not Starting
1. Check pod status: `kubectl get pods -n media`
2. Review logs: `kubectl logs -f deployment/sonarr -n media`
3. Check PVCs: `kubectl get pvc -n media`
4. Verify configuration files

### Download Not Working
1. Check download client is accessible
2. Verify download client configuration
3. Test indexer connectivity
4. Review Sonarr/Radarr logs for errors
5. Check network policies

### Import Not Working
1. Verify import paths are correct
2. Check permissions on media directories
3. Ensure Jellyfin and Starr stack use same storage
4. Review import logs

### Metadata Not Fetching
1. Check metadata provider status
2. Verify API keys are valid
3. Test provider connectivity
4. Review rate limiting settings

---

## Backup

### Backup Configuration
```bash
# Backup Sonarr config
kubectl exec -n media deployment/sonarr -- tar czf /tmp/sonarr-backup.tar.gz /config
kubectl cp -n media deployment/sonarr:/tmp/sonarr-backup.tar.gz ./sonarr-backup.tar.gz

# Backup Radarr config
kubectl exec -n media deployment/radarr -- tar czf /tmp/radarr-backup.tar.gz /config
kubectl cp -n media deployment/radarr:/tmp/radarr-backup.tar.gz ./radarr-backup.tar.gz
```

### Backup Database
The Starr stack databases are included in the configuration backup.

---

## Upgrade

### Sonarr
```bash
kubectl set image deployment/sonarr sonarr=linuxserver/sonarr:<version> -n media
kubectl rollout status deployment/sonarr -n media
```

### Radarr
```bash
kubectl set image deployment/radarr radarr=linuxserver/radarr:<version> -n media
kubectl rollout status deployment/radarr -n media
```

---

## Configuration

### Initial Setup

1. **Access Web Interface:** Navigate to Sonarr/Radarr URL
2. **Set Media Management:**
   - Configure root folders (e.g., `/data/TV Shows`, `/data/Movies`)
   - Set up quality profiles
   - Configure naming schemes
3. **Set Download Clients:**
   - Add torrent client
   - Add Usenet client (if using)
   - Configure download paths
4. **Set Indexers:**
   - Add Jackett/Prowlarr or individual indexers
   - Configure API keys
   - Test connectivity
5. **Set Series/Movies:**
   - Add TV shows to Sonarr
   - Add movies to Radarr
   - Configure monitoring settings

### Quality Profiles

Create quality profiles based on preferences:
- **SD:** Standard Definition (480p, 576p)
- **HD:** High Definition (720p, 1080p)
- **Full HD:** 1080p
- **UHD:** 4K (2160p)
- **Lossless:** Uncompressed or minimal compression

### Naming Schemes

Configure file naming conventions:
- Series: `Series Name - S00E00 - Episode Title [Quality].ext`
- Movies: `Movie Name (Year) [Quality].ext`

---

## Best Practices

### Media Organization
Organize media in standard structure:
```
/data/
├── TV Shows/
│   ├── Series Name/
│   │   ├── Season 01/
│   │   │   ├── Series Name - S01E01 - Episode Title.ext
│   │   │   └── ...
│   │   └── ...
├── Movies/
│   ├── Movie Name (Year) [Quality].ext
│   └── ...
└── Music/
    └── ...
```

### Download Management
- Set appropriate download speeds
- Configure seed ratio limits
- Manage disk space
- Use appropriate quality profiles
- Set up automatic cleanup

### Indexer Management
- Use multiple indexers for better results
- Configure RSS feeds for automatic searching
- Set up backup indexers
- Monitor indexer status

---

## Notes

- Configuration files are stored in `starr-config/` directory
- Services share media storage with Jellyfin
- Consider PVCs for configuration persistence
- Use specific image tags instead of `latest` for production
- Regular backups of configuration are recommended
- Monitor disk usage for downloads
- Configure appropriate resource limits
