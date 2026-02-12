# AdGuard Home - DNS Server & Ad Blocker

**Deployment:** Docker Compose

**URL:** http://<server-ip>:3000 (default)

---

## Overview

AdGuard Home is a network-wide software for blocking ads and tracking. It operates as a DNS server that restores your control over your privacy.

---

## Configuration Files

- `adguard/docker-compose.yml` - Docker Compose configuration
- `adguard/conf/` - Configuration directory
- `adguard/work/` - Working directory

---

## Deployment

AdGuard Home is deployed using Docker Compose (not Kubernetes):

```bash
# Navigate to adguard directory
cd adguard

# Start AdGuard Home
docker-compose up -d

# View logs
docker-compose logs -f

# Stop AdGuard Home
docker-compose down
```

---

## Configuration

### Docker Compose

The Docker Compose file defines:
- **Image:** `adguard/adguardhome:latest`
- **Ports:**
  - 53 (DNS)
  - 67/68 (DHCP)
  - 80 (HTTP UI)
  - 443 (HTTPS UI)
  - 3000 (Initial setup)
  - 853 (DNS-over-TLS)
  - 784 (DNS-over-QUIC)
  - 8853 (DNS-over-TLS)
- **Volumes:**
  - `./conf` - Configuration files
  - `./work` - Working data

### Initial Setup

1. Access the web interface at `http://<server-ip>:3000`
2. Set admin credentials
3. Configure DNS settings
4. Choose upstream DNS servers

---

## Features

- **DNS Filtering:** Block ads, trackers, and malicious domains
- **Parental Controls:** Block adult content and set restrictions
- **Safe Browsing:** Block phishing and malware domains
- **Query Log:** View all DNS queries
- **Statistics:** Monitor network activity
- **Custom Filtering:** Add custom blocklists and allowlists
- **DNS-over-HTTPS/TLS:** Encrypted DNS queries
- **DHCP Server:** Manage network devices

---

## Access

### Web Interface
URL: http://<server-ip>:80 or http://<server-ip>:3000 (initial setup)

### DNS Configuration
Configure your devices or router to use AdGuard Home DNS:
- **Primary DNS:** `<server-ip>`
- **Secondary DNS:** `<server-ip>` or your ISP DNS

---

## Management

### Check Status
```bash
docker-compose ps
docker-compose logs -f
```

### Restart AdGuard Home
```bash
docker-compose restart
```

### Update AdGuard Home
```bash
docker-compose pull
docker-compose up -d
```

---

## Troubleshooting

### AdGuard Home Not Starting
1. Check if ports are available: `netstat -tlnp | grep -E ':(53|80|3000)'`
2. Review logs: `docker-compose logs`
3. Check permissions on `conf/` and `work/` directories
4. Verify Docker is running

### DNS Not Working
1. Check AdGuard Home is running: `docker-compose ps`
2. Verify port 53 is accessible: `netstat -tlnp | grep 53`
3. Test DNS resolution: `nslookup google.com <server-ip>`
4. Review DNS settings in AdGuard Home UI

### Cannot Access Web Interface
1. Check if container is running: `docker-compose ps`
2. Verify port mapping in docker-compose.yml
3. Check firewall rules
4. Try accessing via server IP

### High CPU Usage
1. Check query statistics in AdGuard Home UI
2. Review blocklists (too many may cause high CPU)
3. Consider disabling unused features
4. Check for software updates

---

## Backup

### Backup Configuration
```bash
# Backup conf and work directories
tar czf adguard-backup.tar.gz conf/ work/

# Copy to backup location
cp adguard-backup.tar.gz /backup/location/
```

### Restore from Backup
```bash
# Stop AdGuard Home
docker-compose down

# Extract backup
tar xzf adguard-backup.tar.gz

# Start AdGuard Home
docker-compose up -d
```

---

## Configuration

### DNS Upstream Servers

Configure upstream DNS servers in the AdGuard Home UI:
- Cloudflare DNS: `1.1.1.1`, `1.0.0.1`
- Google DNS: `8.8.8.8`, `8.8.4.4`
- Quad9: `9.9.9.9`, `149.112.112.112`

### Blocklists

Add blocklists to enhance ad blocking:
- AdGuard DNS filter
- EasyList
- Peter Lowe's List
- Malware Domain List

### Custom Rules

Add custom DNS rules:
- Block specific domains: `||example.com^`
- Redirect domains: `||example.com^$dnsrewrite=192.168.1.1`
- Allow specific domains: `@@||example.com^`

### DHCP Server

Configure DHCP server in AdGuard Home:
- Set IP range
- Configure lease time
- Add static leases for devices

---

## Integration

AdGuard Home integrates with:

- **Home Network:** Configure router to use AdGuard Home DNS
- **Kubernetes Services:** Optionally block external ad domains for services
- **Cloudflare DDNS:** Update DNS records for dynamic IP

---

## Security

### Best Practices
1. Change default admin password
2. Enable HTTPS for web interface
3. Restrict access to web UI (IP whitelist)
4. Regularly update AdGuard Home
5. Review query logs for suspicious activity
6. Use DNS-over-HTTPS/TLS for encrypted queries

### Access Control
Restrict access to the web UI:
1. Configure IP whitelist in settings
2. Enable authentication
3. Use reverse proxy with Authelia

---

## Performance

### Optimization Tips
1. Limit blocklists to essential ones
2. Enable DNS caching
3. Monitor memory usage
4. Adjust query log retention period
5. Use appropriate server hardware

---

## Notes

- AdGuard Home runs via Docker Compose, not Kubernetes
- Default web UI ports: 80 (HTTP), 3000 (initial setup)
- DNS runs on port 53 (both TCP and UDP)
- Configuration files stored in `conf/` directory
- Working data stored in `work/` directory
- Configure router to use AdGuard Home DNS for network-wide protection
