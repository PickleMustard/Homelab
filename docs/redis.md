# Redis - In-Memory Data Store

**Namespace:** `redis`

**Port:** 6379

---

## Overview

Redis is an open-source, in-memory data structure store used as a database, cache, message broker, and queue. It provides fast data access for applications that require high performance.

---

## Configuration Files

- `redis-values.yml` - Helm chart values

---

## Deployment

Redis is deployed using Helm:

```bash
# Create namespace
kubectl create namespace redis

# Add Bitnami Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install Redis
helm install --namespace redis redis bitnami/redis -f redis-values.yml
```

---

## Configuration

### Main Settings (redis-values.yml)

Key configuration options:
- **Architecture:** standalone or replication
- **Auth:** Authentication settings
- **Master:** Master configuration
- **Replica:** Replica configuration (if using replication)
- **Resources:** CPU and memory limits
- **Persistence:** Storage configuration

---

## Storage

### Persistent Volume Claim

Redis uses a PVC for data persistence (configured in values file):

- **Storage Class:** `local-path`
- **Size:** Configured in values file
- **Access Mode:** ReadWriteOnce

---

## Clients

The following services use Redis:

| Service | Purpose |
|---------|---------|
| Pterodactyl | Caching, sessions, queue |

---

## Access

### Connection String Pattern
```
redis://:<password>@redis-master.redis.svc.cluster.local:6379/0
```

### Internal Access
```bash
# Using redis-cli from within the cluster
kubectl exec -it -n redis deployment/redis-master -- redis-cli

# Or run a redis-cli pod
kubectl run -it --rm redis-client --image=redis:7 --restart=Never -- redis-cli -h redis-master.redis.svc.cluster.local -a <password>
```

### Command-Line Access
```bash
# Connect to Redis
kubectl exec -it -n redis deployment/redis-master -- redis-cli -a <password>

# Test connection
127.0.0.1:6379> PING
PONG

# Get information
127.0.0.1:6379> INFO

# List all keys
127.0.0.1:6379> KEYS *
```

---

## Management

### Check Status
```bash
kubectl get pods -n redis
kubectl logs -f deployment/redis-master -n redis
```

### Access Shell
```bash
kubectl exec -it deployment/redis-master -n redis -- /bin/bash
```

### View Configuration
```bash
kubectl get secret redis -n redis -o yaml
```

---

## Common Operations

### Set Value
```bash
kubectl exec -n redis deployment/redis-master -- redis-cli -a <password> SET key value
```

### Get Value
```bash
kubectl exec -n redis deployment/redis-master -- redis-cli -a <password> GET key
```

### Delete Key
```bash
kubectl exec -n redis deployment/redis-master -- redis-cli -a <password> DEL key
```

### Flush All
```bash
kubectl exec -n redis deployment/redis-master -- redis-cli -a <password> FLUSHALL
```

### Monitor Commands
```bash
kubectl exec -n redis deployment/redis-master -- redis-cli -a <password> MONITOR
```

---

## Data Types

Redis supports various data types:

### Strings
```bash
SET key value
GET key
```

### Lists
```bash
LPUSH mylist value1
RPUSH mylist value2
LRANGE mylist 0 -1
```

### Sets
```bash
SADD myset value1 value2
SMEMBERS myset
```

### Hashes
```bash
HSET myhash field1 value1
HGET myhash field1
HGETALL myhash
```

### Sorted Sets
```bash
ZADD myzset 1 member1
ZRANGE myzset 0 -1
```

---

## Troubleshooting

### Service Not Starting
1. Check pod status: `kubectl get pods -n redis`
2. Review logs: `kubectl logs -f deployment/redis-master -n redis`
3. Check PVC: `kubectl get pvc -n redis`
4. Verify storage class: `kubectl get storageclass`

### Connection Issues
1. Check service: `kubectl get svc -n redis`
2. Verify service endpoints: `kubectl get endpoints -n redis`
3. Check network policies
4. Verify password in secret

### Memory Issues
1. Check memory usage: `kubectl top pod -n redis`
2. Review Redis INFO: `kubectl exec -n redis deployment/redis-master -- redis-cli INFO memory`
3. Consider increasing memory limits
4. Enable maxmemory policy

### Performance Issues
1. Monitor commands: `kubectl exec -n redis deployment/redis-master -- redis-cli --latency`
2. Review slow log: `kubectl exec -n redis deployment/redis-master -- redis-cli SLOWLOG GET`
3. Check connection count: `kubectl exec -n redis deployment/redis-master -- redis-cli INFO clients`

---

## Backup

### Backup RDB File
```bash
# Trigger save
kubectl exec -n redis deployment/redis-master -- redis-cli -a <password> BGSAVE

# Wait for save to complete
kubectl exec -n redis deployment/redis-master -- redis-cli -a <password> LASTSAVE

# Copy RDB file
kubectl cp -n redis deployment/redis-master:/data/dump.rdb ./redis-backup.rdb
```

### Restore from Backup
```bash
# Stop Redis
kubectl scale deployment redis-master -n redis --replicas=0

# Copy backup file
kubectl cp ./redis-backup.rdb -n redis deployment/redis-master:/data/dump.rdb

# Start Redis
kubectl scale deployment redis-master -n redis --replicas=1
```

---

## Upgrade

### Using Helm
```bash
helm upgrade --namespace redis redis bitnami/redis -f redis-values.yml
```

### Manual Upgrade
```bash
# Set image tag
kubectl set image deployment/redis-master redis=bitnami/redis:<version> -n redis

# Watch rollout
kubectl rollout status deployment/redis-master -n redis
```

---

## Configuration Options

### Max Memory
Configure max memory policy in values file:

```yaml
master:
  command:
    - redis-server
    - --maxmemory 256mb
    - --maxmemory-policy allkeys-lru
```

### Persistence
Configure persistence options:

```yaml
master:
  persistence:
    enabled: true
    path: /data
```

---

## Security

### Authentication
Redis is configured with a password:
- Stored in the `redis` secret
- Required for all operations
- Do not expose Redis externally without authentication

### Best Practices
1. Always use strong passwords
2. Do not expose Redis publicly
3. Use network policies to restrict access
4. Enable SSL/TLS for connections (if needed)
5. Regularly update Redis version
6. Monitor memory usage

---

## Monitoring

### Key Metrics
Monitor these metrics:
- Memory usage
- Connection count
- Command statistics
- Hit/miss ratio (for caching)
- Key count

### Redis INFO Commands
```bash
# Server info
INFO server

# Memory info
INFO memory

# Persistence info
INFO persistence

# Replication info
INFO replication

# Stats
INFO stats
```

---

## Notes

- Redis is deployed via Helm chart in the `redis` namespace
- Used primarily by Pterodactyl for caching and queues
- Password authentication is enabled
- Data persistence is configured via RDB files
- Consider setting maxmemory limits to prevent OOM
- Regular backups recommended for production use
