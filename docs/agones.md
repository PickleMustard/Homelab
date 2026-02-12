# Agones

Agones is a library for hosting, running and scaling dedicated game servers on Kubernetes.

## Deployment

- **Type:** Helm Chart
- **Namespace:** `agones-system`
- **Chart:** `agones/agones`
- **Values:** `agones-values.yml`
- **Version:** Latest (configured via chart)

## Components

### Controller
- **Replicas:** 1
- **Health Check:**
  - Initial Delay: 500s
  - Period: 500s
  - Failure Threshold: 500s
  - Timeout: 500s

### Extensions
- **Replicas:** 1
- **HTTP Port:** 8080

### Ping Service
- **Replicas:** 1
- **HTTP Port:** 80
- **Service Type:** ClusterIP

### Allocator
- **Replicas:** 1
- **Log Level:** `debug`
- **Service Type:** LoadBalancer
- **HTTP:**
  - Port: 8443
  - Target Port: 8443
- **gRPC:**
  - Port: 8444
  - Target Port: 8444

### CRDs
- **Install:** Yes
- **Cleanup on Delete:** Yes
- **Cleanup Job TTL:** 60s

### Metrics
- **Prometheus Enabled:** No
- **Prometheus Service Discovery:** No
- **Service Monitor Interval:** 300s

## Game Server Configuration

### Supported Namespaces
- `shulker-system` - Shulker Minecraft clusters

### Custom Resources
- `GameServer` - Individual game server instance
- `Fleet` - Replicated set of game servers
- `GameServerAllocation` - Request to allocate a game server

## Integration with Shulker

Agones provides the underlying infrastructure for Shulker-based Minecraft server management:
- Game server lifecycle management
- Fleet scaling and orchestration
- Health checking and monitoring
- Allocation API for matchmaking

## Deployment Commands

```bash
# Install Agones
helm install --namespace agones-system agones agones/agones -f agones-values.yml

# Update Agones
helm upgrade --namespace agones-system agones agones/agones -f agones-values.yml

# Check CRDs
kubectl get crd | grep agones

# View game servers
kubectl get gameservers -A

# View fleets
kubectl get fleets -A
```

## Management

### Monitoring
```bash
# Check Agones system pods
kubectl get pods -n agones-system

# View controller logs
kubectl logs -f deployment/agones-controller -n agones-system

# View allocator logs
kubectl logs -f deployment/agones-allocator -n agones-system

# Check game servers
kubectl get gameservers -n shulker-system

# Check fleet status
kubectl get fleet -n shulker-system
```

### Game Server Operations
```bash
# Allocate a game server
kubectl apply -f allocation-request.yaml

# Delete a game server
kubectl delete gameserver <name> -n <namespace>

# Scale a fleet
kubectl scale fleet <fleet-name> --replicas=<count> -n <namespace>
```

## Configuration Files

### agones-cert.yml
- Certificate configuration for Agones services

### nvidia-runtime.yaml
- NVIDIA runtime configuration for GPU support

### nvidia-benchmark.yaml
- NVIDIA benchmark configuration

## Architecture

```
Shulker (Minecraft Manager)
    ↓
Agones (Game Server Operator)
    ↓
Kubernetes
```

## Features

### Fleet Management
- Define fleet templates
- Automatic scaling based on metrics
- Rolling updates for game servers

### Allocation System
- Matchmaking integration
- Label-based allocation
- Filter game servers by attributes

### Health Management
- Custom health checks
- Automatic restart of failed servers
- Graceful shutdown handling

### Development Support
- Development mode with debug logging
- Local development support
- Testing utilities

## Related Services

- **Minecraft:** Game servers managed by Agones
- **Shulker:** Minecraft server management layer
- **Kubernetes:** Underlying orchestration platform

## Use Cases

### Production
- Run dedicated game servers at scale
- Automatic scaling based on player demand
- Efficient resource utilization

### Development
- Test game server deployments
- Local development environment
- CI/CD integration

## Notes

- Health check intervals are set very high (500s) for testing - adjust for production
- Prometheus metrics are disabled - enable for monitoring in production
- Allocator is configured as LoadBalancer for external access
- CRDs are automatically installed with the Helm chart

## Troubleshooting

### Game Server Not Starting
- Check game server logs: `kubectl logs gameserver/<name> -n <namespace>`
- Verify Agones controller is running: `kubectl get pods -n agones-system`
- Check fleet status: `kubectl describe fleet <name> -n <namespace>`

### Allocation Failures
- Check allocator logs: `kubectl logs -f deployment/agones-allocator -n agones-system`
- Verify game servers are ready: `kubectl get gameservers -n <namespace>`
- Check label selectors match

### Health Check Issues
- Review health check configuration in game server spec
- Adjust health check intervals for your use case
- Check game server application logs for issues

## References

- **Documentation:** https://agones.dev/site/
- **GitHub:** https://github.com/googleforgames/agones
- **Shulker Integration:** Used by Shulker for Minecraft management
