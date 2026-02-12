# Vaultwarden-LDAP

Vaultwarden-LDAP is a service that provides LDAP authentication integration for Vaultwarden, allowing users to authenticate using LDAP credentials instead of local accounts.

## Deployment

- **Type:** Kubernetes Deployment
- **Namespace:** `vaultwarden`
- **Deployment:** `vaultwarden-ldap/deployment.yml`
- **ConfigMap:** `vaultwarden-ldap/config-map.yml`
- **Image:** `vividboarder/vaultwarden_ldap:latest`

## Configuration

### Environment Variables
- **CONFIG_PATH:** `/opt/vaultwarden-ldap/config.toml`
- **APP_VAULTWARDEN_ADMIN_TOKEN:** Vaultwarden admin token (from secret)
- **APP_LDAP_BIND_PASSWORD:** LDAP bind password (from secret)

### Secrets
Configuration uses secret `vaultwarden-ldap-config` with:
- `admin_token` - Vaultwarden admin token for API access
- `bind_passwd` - LDAP bind password for authentication

### ConfigMap
- **Name:** `vaultwarden-ldap`
- **File:** `config.toml`
- **Mounted:** `/opt/vaultwarden-ldap/config.toml`

## Deployment Strategy
- **Type:** `Recreate` (not RollingUpdate)
- **Reason:** Ensures clean state changes for LDAP integration

## Integration

### With Vaultwarden
- Authenticates users against LDAP instead of local database
- Synchronizes user accounts from LDAP
- Supports user provisioning and deprovisioning
- Provides centralized user management

### With LLDAP
- **LDAP Server:** LLDAP (192.168.1.142:3890)
- **Base DN:** `dc=andromeda,dc=picklemustard,dc=dev`
- **Bind DN:** Configured for read access to user entries
- **Search Attribute:** `uid`

## Configuration File (config.toml)

The ConfigMap contains the main configuration including:
- LDAP server connection details
- Base DN and bind credentials
- User search filters
- Group mappings
- Vaultwarden API endpoints

## Architecture

```
User Login Request
    ↓
Vaultwarden-LDAP
    ↓
LDAP Authentication (LLDAP)
    ↓
Vaultwarden API
    ↓
Access Granted/Denied
```

## Deployment Commands

```bash
# Create namespace (if needed)
kubectl create namespace vaultwarden

# Apply ConfigMap
kubectl apply -f vaultwarden-ldap/config-map.yml

# Apply Secret (create separately)
kubectl create secret generic vaultwarden-ldap-config \
  --from-literal=admin_token=<token> \
  --from-literal=bind_passwd=<password> \
  -n vaultwarden

# Apply Deployment
kubectl apply -f vaultwarden-ldap/deployment.yml
```

## Management

### Monitoring
```bash
# Check deployment status
kubectl get deployment vaultwarden-ldap -n vaultwarden

# View logs
kubectl logs -f deployment/vaultwarden-ldap -n vaultwarden

# Check pod status
kubectl get pods -n vaultwardwarden
```

### Configuration
```bash
# View current config
kubectl describe configmap vaultwarden-ldap -n vaultwarden

# Edit config
kubectl edit configmap vaultwarden-ldap -n vaultwarden

# Restart deployment after config change
kubectl rollout restart deployment/vaultwarden-ldap -n vaultwarden
```

## Features

### User Authentication
- LDAP-based authentication
- Password validation against LDAP
- Session management

### User Synchronization
- Automatic user creation from LDAP
- User attribute mapping
- Group-based access control

### Security
- Secure LDAP connection support
- Token-based API authentication
- Password protection for sensitive data

## Use Cases

### Centralized Authentication
- Single LDAP source for multiple applications
- Consistent authentication across services
- Centralized user management

### User Management
- Automatic user provisioning
- Group-based permissions
- Easy user onboarding/offboarding

### Integration
- Works with existing Vaultwarden installation
- Minimal configuration required
- Transparent to end users

## Related Services

- **Vaultwarden:** Main password manager application
- **LLDAP:** LDAP authentication server
- **PostgreSQL:** Backend database (if Vaultwarden uses it)

## Advantages

### Security
- Centralized password policy
- Single sign-on capability
- Secure password storage in Vaultwarden

### Management
- LDAP-based user management
- Group-based access control
- Automated provisioning/deprovisioning

### Integration
- Seamless integration with existing LDAP
- Minimal Vaultwarden configuration
- Works with standard LDAP servers

## Troubleshooting

### Authentication Failures
- Check logs: `kubectl logs -f deployment/vaultwarden-ldap -n vaultwarden`
- Verify LDAP server is reachable
- Check bind credentials in secret
- Verify Base DN and search filter

### User Not Created
- Check Vaultwarden admin token
- Verify Vaultwarden API is accessible
- Check logs for synchronization errors
- Review group mapping configuration

### Connection Issues
- Verify LDAP server address and port
- Check network policies
- Ensure service can reach LLDAP
- Test LDAP connectivity manually

### Configuration Issues
- Validate config.toml syntax
- Check ConfigMap contents
- Verify secret references
- Review deployment environment variables

## Security Considerations

### Secrets Management
- Store sensitive data in Kubernetes secrets
- Rotate LDAP bind passwords regularly
- Use strong Vaultwarden admin tokens
- Never commit secrets to version control

### Network Security
- Use TLS for LDAP connections if available
- Restrict network access to LDAP server
- Implement RBAC for service accounts

### Audit Logging
- Enable audit logging for authentication events
- Monitor for failed login attempts
- Track user synchronization activities

## Notes

- Uses `Recreate` deployment strategy - expect brief downtime during updates
- Configuration changes require pod restart
- Integrates seamlessly with existing Vaultwarden installation
- Can be disabled to revert to local authentication

## Future Enhancements

- Enable TLS for LDAP connections
- Add group synchronization
- Implement user attribute caching
- Configure advanced search filters
- Add health checks and monitoring

## References

- **Vaultwarden-LDAP:** https://github.com/vividboarder/vaultwarden_ldap
- **Vaultwarden:** https://github.com/dani-garcia/vaultwarden
- **LLDAP:** https://github.com/lldap/lldap
