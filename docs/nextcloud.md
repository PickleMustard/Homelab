# Nextcloud

Nextcloud is a self-hosted file share and collaboration platform providing file storage, synchronization, sharing, and collaboration features.

## Deployment

- **Type:** Helm Chart
- **Namespace:** `nextcloud` (to be created)
- **Chart:** Standard Nextcloud Helm chart
- **Values:** `nextcloud-values.yml`

## Configuration

### External Database
- **Type:** PostgreSQL
- **Host:** `postgres-postgresql.postgres.svc.cluster.local:5432`
- **Database:** `nextcloud`
- **User:** `postgres_fid`
- **Connection:** Uses internal database (disabled)

### Ingress
- **Enabled:** Yes
- **Ingress Class:** `traefik`
- **Host:** `nextcloud.picklemustard.dev`
- **Service Port:** `https`
- **Path:** `/`

### Application Settings
- **Host:** `nextcloud.picklemustard.dev`
- **HTTPS Protocol:** Enabled (client fix)

### Secrets
Configuration uses existing secret `nextcloud-config` with:
- `username` - Admin username
- `password` - Admin password
- `smtp-username` - SMTP username for email
- `smtp-password` - SMTP password
- `smtp-host` - SMTP server hostname

## Storage

- **Storage Class:** `local-path`
- **Access Mode:** `ReadWriteOnce`
- **Size:** 1Gi (should be increased for production use)

## Features

### Collaboration Tools
- File storage and synchronization
- Calendar and contacts
- Office document editing (Collabora/OnlyOffice)
- Video conferencing (Talk)
- Two-factor authentication

### Integration
- **Database:** PostgreSQL shared database service
- **Email:** SMTP integration for notifications
- **Authentication:** Can integrate with LLDAP via LDAP app

## Deployment Commands

```bash
# Create namespace (if needed)
kubectl create namespace nextcloud

# Install Nextcloud using Helm
helm install --namespace nextcloud nextcloud <chart-repo>/nextcloud -f nextcloud-values.yml

# Update existing deployment
helm upgrade --namespace nextcloud nextcloud <chart-repo>/nextcloud -f nextcloud-values.yml
```

## Management

### Access
- **URL:** https://nextcloud.picklemustard.dev
- **Admin Credentials:** From `nextcloud-config` secret

### Common Operations
```bash
# Get deployment status
kubectl get deployment -n nextcloud

# View logs
kubectl logs -f deployment/nextcloud -n nextcloud

# Check ingress
kubectl get ingress -n nextcloud

# Access pod shell
kubectl exec -it deployment/nextcloud -n nextcloud -- bash
```

## Maintenance

### Storage Management
- Monitor storage usage and expand PVC if needed
- Backup Nextcloud data directory
- Backup PostgreSQL database

### Updates
- Regular updates via Helm upgrade
- Check Nextcloud app updates through admin panel

### Troubleshooting
- Check pod logs for database connection errors
- Verify ingress configuration and TLS certificates
- Ensure PostgreSQL service is accessible

## Related Services

- **PostgreSQL:** Backend database
- **Traefik:** Ingress controller
- **Stalwart Mail:** Email notifications (if configured)
- **LLDAP:** User authentication (via LDAP app)

## Notes

- Consider increasing storage size from 1Gi for production use
- Enable LDAP app for integration with LLDAP authentication
- Configure external storage for media files
- Set up regular backups for data and database
- Configure SSL/TLS for secure access (handled by Traefik)
