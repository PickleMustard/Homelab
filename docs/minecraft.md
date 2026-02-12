# Minecraft Servers

**Namespace:** `minecraft`

---

## Overview

Minecraft servers are deployed in the k3s homelab using Agones, a Kubernetes-based game server operator. Agones manages the lifecycle of game servers and provides features like allocation, scaling, and health checking.

---

## Configuration Files

- `minecraft/server-properties-configmap.yml` - Server properties
- `minecraft/bukkit-configmap.yml` - Bukkit configuration
- `minecraft/spigot-configmap.yml` - Spigot configuration
- `minecraft/itzg-config/` - itzg/minecraft-server configurations
- `minecraft/shulker-config/` - Shulker management configurations

---

## Deployment

Minecraft servers are deployed using Agones:

```bash
# Create namespace
kubectl create namespace minecraft

# Apply Agones CRDs (if not installed)
kubectl apply -f https://raw.githubusercontent.com/googleforgames/agones/release-1.36.0/install/yaml/install.yaml

# Apply server configurations
kubectl apply -f minecraft/
```

---

## Server Types

### itzg/minecraft-server
Popular Docker image for running Minecraft servers with easy configuration.

### Shulker
Management tool for multiple Minecraft servers.

---

## Configuration

### Server Properties (server-properties-configmap.yml)

Standard Minecraft server properties:
- `server-name` - Server name
- `server-port` - Server port (default: 25565)
- `gamemode` - Game mode (survival, creative, adventure, spectator)
- `difficulty` - Difficulty level (peaceful, easy, normal, hard)
- `max-players` - Maximum player count
- `spawn-monsters` - Spawn monsters
- `spawn-animals` - Spawn animals
- `pvp` - Enable PvP
- `level-seed` - World seed
- `level-name` - World name
- `view-distance` - View distance

### Bukkit Configuration (bukkit-configmap.yml)

Bukkit/Spigot-specific settings:
- `spawn-limits` - Mob spawn limits
- `chunk-gc` - Chunk garbage collection
- `ticks-per` - Various tick settings

### Spigot Configuration (spigot-configmap.yml)

Spigot-specific optimizations:
- `settings` - General settings
- `world-settings` - Per-world settings
- `timings` - Performance monitoring

---

## Agones Integration

### GameServer Custom Resource

Agones uses `GameServer` CRD to manage servers:

```yaml
apiVersion: "agones.dev/v1"
kind: GameServer
metadata:
  name: "minecraft-server"
  namespace: minecraft
spec:
  ports:
    - name: minecraft
      containerPort: 25565
  template:
    spec:
      containers:
        - name: minecraft
          image: itzg/minecraft-server
```

### Features
- **Allocation:** Allocate servers to players
- **Health Checking:** Monitor server health
- **Scaling:** Scale servers based on demand
- **State Management:** Track server state (Allocated, Ready, Reserved)

---

## Access

### Direct Connection
- **Host:** `minecraft.picklemustard.dev`
- **Port:** 25565

### Via Agones
Agones provides dynamic allocation endpoints.

---

## Management

### Check Status
```bash
kubectl get gameservers -n minecraft
kubectl describe gameserver <server-name> -n minecraft
```

### View Logs
```bash
kubectl logs -f gameserver/<server-name> -n minecraft
```

### Access Server Console
```bash
kubectl exec -it gameserver/<server-name> -n minecraft -- /bin/bash
```

---

## Troubleshooting

### Server Not Starting
1. Check GameServer status: `kubectl get gameservers -n minecraft`
2. Review pod logs: `kubectl logs gameserver/<server-name> -n minecraft`
3. Check Agones operator: `kubectl get pods -n agones-system`
4. Verify resource limits

### Cannot Connect to Server
1. Check server state: `kubectl get gameservers -n minecraft`
2. Verify service: `kubectl get svc -n minecraft`
3. Check ingress: `kubectl get ingress -n minecraft`
4. Test port connectivity: `nc -zv minecraft.picklemustard.dev 25565`

### Performance Issues
1. View performance metrics: `kubectl top pod -n minecraft`
2. Check server ticks per second (TPS)
3. Review Spigot timings: `/timings on`
4. Adjust view distance and spawn limits

### World Corruption
1. Backup world data regularly
2. Use world editing tools cautiously
3. Monitor disk usage
4. Check for errors in logs

---

## Backup

### Backup World Data
```bash
# Get the GameServer pod name
POD_NAME=$(kubectl get pods -n minecraft -l agones.dev/gameserver=<server-name> -o jsonpath='{.items[0].metadata.name}')

# Copy world data
kubectl cp -n minecraft $POD_NAME:/data/world ./minecraft-world-backup
```

### Restore World Data
```bash
# Stop the server
kubectl delete gameserver <server-name> -n minecraft

# Copy world data back
POD_NAME=$(kubectl get pods -n minecraft -l agones.dev/gameserver=<server-name> -o jsonpath='{.items[0].metadata.name}')
kubectl cp ./minecraft-world-backup -n minecraft $POD_NAME:/data/world

# Restart the server
kubectl apply -f <gameserver-config>.yml
```

---

## Configuration

### Initial Setup

1. Configure server properties in ConfigMap
2. Set up world seed and name
3. Configure game mode and difficulty
4. Set spawn protection and max players
5. Enable/disable whitelist, ops, etc.

### Plugins

Install plugins for Spigot/Bukkit servers:
1. Copy plugins to `/data/plugins/`
2. Restart server
3. Configure plugins in `/data/plugins/<plugin>/config.yml`

### Resource Management

Adjust resource limits based on server requirements:

```yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "1"
  limits:
    memory: "4Gi"
    cpu: "2"
```

---

## Integration

### Pterodactyl
Minecraft servers can be managed via Pterodactyl:
- Configure Wings to use Agones
- Set up server templates
- Manage servers from web interface

### Agones
Agones manages server lifecycle:
- Automatic scaling
- Health checking
- Player allocation

---

## Performance Tuning

### Spigot Optimizations
- Adjust `view-distance` based on player count
- Enable `merge-radius` for entities and items
- Set appropriate `spawn-limits`
- Use `mob-spawn-range` to control mob spawning

### JVM Settings
Configure JVM options in itzg/minecraft-server:
```yaml
env:
  - name: JVM_XX_OPTS
    value: "-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200"
```

---

## Security

### Best Practices
1. Enable whitelist for private servers
2. Use ops cautiously
3. Set spawn protection
4. Regularly update server software
5. Monitor player activity
6. Back up world data regularly

### Whitelist
Configure whitelist in server properties:
- `whitelist=true` - Enable whitelist
- `whitelist-players` - Add players to whitelist
- `enforce-whitelist=true` - Enforce whitelist

---

## Notes

- Minecraft servers are deployed using Agones
- Configuration files are stored as ConfigMaps
- Server properties can be customized per server
- Consider resource requirements based on player count
- Regular backups are critical for world data
- Monitor TPS and performance metrics
- Use appropriate server software (Vanilla, Spigot, Paper)
