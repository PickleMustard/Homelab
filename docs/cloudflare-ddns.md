# Cloudflare DDNS - Dynamic DNS

**Deployment:** Docker Compose

---

## Overview

Cloudflare DDNS automatically updates Cloudflare DNS records when your server's public IP changes. This ensures your services remain accessible even with a dynamic IP address.

---

## Configuration Files

- `cloudflare-ddns/docker-compose.yml` - Docker Compose configuration

---

## Deployment

Cloudflare DDNS is deployed using Docker Compose (not Kubernetes):

```bash
# Navigate to cloudflare-ddns directory
cd cloudflare-ddns

# Start Cloudflare DDNS
docker-compose up -d

# View logs
docker-compose logs -f

# Stop Cloudflare DDNS
docker-compose down
```

---

## Configuration

### Docker Compose

The Docker Compose file defines:
- **Image:** `favonia/cloudflare-ddns:latest`
- **Environment Variables:**
  - `CF_API_TOKEN` - Cloudflare API token
  - `CF_DOMAIN` - Domain to update (e.g., `picklemustard.dev`)
  - `CF_RECORDS` - DNS records to update (e.g., `@,www,*`)

### Required Environment Variables

Create a `.env` file or set environment variables:

```bash
CF_API_TOKEN=<your-cloudflare-api-token>
CF_DOMAIN=picklemustard.dev
CF_RECORDS=@,www,*
```

#### Cloudflare API Token

Create an API token in Cloudflare with permissions:
- **Zone:** DNS - Edit
- **Zone Resources:** Include - All zones or specific zone

---

## Features

- **Automatic IP Detection:** Detects public IP changes
- **DNS Updates:** Automatically updates Cloudflare DNS records
- **Multiple Records:** Update multiple DNS records (A, AAAA, CNAME)
- **IPv4/IPv6:** Supports both IPv4 and IPv6
- **Health Checks:** Verifies DNS propagation

---

## DNS Records

The `CF_RECORDS` variable specifies which records to update:
- `@` - Update the root domain (e.g., `picklemustard.dev`)
- `www` - Update `www.picklemustard.dev`
- `*` - Update wildcard `*.picklemustard.dev`

---

## Management

### Check Status
```bash
docker-compose ps
docker-compose logs -f
```

### Restart Cloudflare DDNS
```bash
docker-compose restart
```

### Update Cloudflare DDNS
```bash
docker-compose pull
docker-compose up -d
```

### Force IP Update
```bash
docker-compose restart
```

---

## Troubleshooting

### DNS Not Updating
1. Check container is running: `docker-compose ps`
2. Review logs: `docker-compose logs`
3. Verify API token has correct permissions
4. Check domain is configured in Cloudflare
5. Test API token manually:
   ```bash
   curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer <your-api-token>"
   ```

### Incorrect IP Detected
1. Check current public IP: `curl ifconfig.me`
2. Review logs to see detected IP
3. Verify network configuration
4. Check for multiple network interfaces

### Authentication Errors
1. Verify API token is correct
2. Check token has DNS Edit permissions
3. Ensure token is not expired
4. Verify domain ownership in Cloudflare

### Container Not Starting
1. Check Docker is running: `docker ps`
2. Review logs: `docker-compose logs`
3. Verify environment variables are set
4. Check network connectivity

---

## Cloudflare API Token

### Creating a Token

1. Go to Cloudflare Dashboard → My Profile → API Tokens
2. Click "Create Token"
3. Use template "Edit zone DNS" or create custom token
4. Configure permissions:
   - Zone → DNS → Edit
   - Zone Resources → Include → Specific zone → `picklemustard.dev`
5. Set TTL and IP restrictions if desired
6. Copy the token

### Testing Token

```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer <your-api-token>"
```

---

## Integration

Cloudflare DDNS integrates with:

- **Traefik:** DNS records for ingress routing
- **All Services:** Enables access via domain names
- **Cloudflare:** DNS management platform

---

## Security

### Best Practices
1. Store API token in environment variables, not in docker-compose.yml
2. Use .env file and add to .gitignore
3. Set appropriate token permissions (DNS Edit only)
4. Restrict token to specific zones if possible
5. Set IP restrictions on API token if possible
6. Regularly rotate API tokens

### .gitignore

Add `.env` to `.gitignore`:

```gitignore
.env
cloudflare-ddns/.env
```

---

## Advanced Configuration

### Multiple Domains

Update multiple domains by running multiple containers:

```yaml
services:
  cloudflare-ddns-1:
    image: favonia/cloudflare-ddns:latest
    environment:
      CF_API_TOKEN: ${CF_API_TOKEN}
      CF_DOMAIN: example.com
      CF_RECORDS: @,www
  
  cloudflare-ddns-2:
    image: favonia/cloudflare-ddns:latest
    environment:
      CF_API_TOKEN: ${CF_API_TOKEN}
      CF_DOMAIN: another.com
      CF_RECORDS: @,www
```

### Custom Update Interval

The container checks for IP changes periodically. To adjust the interval, modify the image or use environment variables supported by the specific image.

---

## Notes

- Cloudflare DDNS runs via Docker Compose, not Kubernetes
- Requires Cloudflare API token with DNS Edit permissions
- Updates DNS records for the specified domain
- Check logs regularly to verify updates are working
- Consider setting up monitoring for DDNS failures
- Ensure firewall allows outbound HTTPS to Cloudflare API
