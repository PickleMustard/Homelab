# Firefly III - Personal Finance Manager

**Namespace:** `finance`

**URL:** https://firefly.picklemustard.dev

---

## Overview

Firefly III is a personal finance manager that helps you track finances, budgets, and transactions. It's self-hosted and provides a complete solution for financial management.

---

## Configuration Files

- `firefly/firefly-values.yml` - Helm chart values for Firefly III
- `firefly/firefly-importer-values.yml` - Helm chart values for Firefly Importer
- `firefly/firefly-ingress.yml` - Ingress configuration

---

## Deployment

Firefly III is deployed using Helm:

```bash
# Create namespace
kubectl create namespace finance

# Add Firefly III Helm repository
helm repo add firefly-iii https://firefly-iii.github.io/docker-helm-chart
helm repo update

# Install Firefly III
helm install --namespace finance firefly-iii firefly-iii/firefly-iii -f firefly/firefly-values.yml

# Install Firefly Importer
helm install --namespace finance firefly-iii-importer firefly-iii/firefly-iii-importer -f firefly/firefly-importer-values.yml
```

---

## Components

### Firefly III
Main application for tracking:
- Transactions
- Accounts
- Budgets
- Bills
- Categories
- Tags

### Firefly Importer
Tool for importing transactions from external sources:
- Bank CSV exports
- Financial institutions
- Other finance apps

---

## Configuration

### Main Settings (firefly-values.yml)

Key configuration options:
- **App URL:** https://firefly.picklemustard.dev
- **Database:** PostgreSQL connection
- **Static environment variables:** APP_ENV, APP_KEY, etc.
- **App settings:** Timezone, locale, etc.

### Importer Settings (firefly-importer-values.yml)

Configuration for the importer:
- **App URL:** https://firefly.picklemustard.dev
- **Firefly URL:** Firefly III API endpoint
- **Import sources:** Configured banks and financial institutions

---

## Database

Firefly III uses PostgreSQL for data storage:

- **Host:** `postgres-postgresql.postgres.svc.cluster.local`
- **Port:** 5432
- **Database:** Configured in values file
- **User:** Configured in values file

---

## Access

### Web Interface
URL: https://firefly.picklemustard.dev

Initial setup requires creating an admin account and configuring application settings.

### Firefly Importer
URL: https://firefly.picklemustard.dev/importer

Use the importer to upload CSV files or connect to financial institutions.

---

## Management

### Check Status
```bash
kubectl get pods -n finance
kubectl logs -f deployment/firefly-iii -n finance
kubectl logs -f deployment/firefly-iii-importer -n finance
```

### Access Shell
```bash
kubectl exec -it deployment/firefly-iii -n finance -- /bin/sh
```

---

## Troubleshooting

### Cannot Access Web Interface
1. Check pod status: `kubectl get pods -n finance`
2. Verify service: `kubectl get svc -n finance`
3. Check ingress: `kubectl get ingress -n finance`

### Database Connection Issues
1. Verify PostgreSQL is running: `kubectl get pods -n postgres`
2. Check database credentials in values file
3. Test connection: `kubectl exec -n finance deployment/firefly-iii -- nc -zv postgres-postgresql.postgres.svc.cluster.local 5432`

### Importer Not Working
1. Check importer logs: `kubectl logs -f deployment/firefly-iii-importer -n finance`
2. Verify Firefly API is accessible
3. Check import source configuration

### Transaction Import Issues
1. Verify CSV format matches expected format
2. Check for duplicate transactions
3. Review importer logs for errors

---

## Backup

### Backup Database
```bash
# Replace <database-name> with actual database name
kubectl exec -n postgres postgres-postgresql-0 -- pg_dump -U postgres <database-name> > firefly-backup.sql
```

### Backup Uploads
```bash
kubectl exec -n finance deployment/firefly-iii -- tar czf /tmp/firefly-uploads-backup.tar.gz /var/www/html/storage/export
kubectl cp -n finance deployment/firefly-iii:/tmp/firefly-uploads-backup.tar.gz ./firefly-uploads-backup.tar.gz
```

---

## Upgrade

### Firefly III
```bash
helm upgrade --namespace finance firefly-iii firefly-iii/firefly-iii -f firefly/firefly-values.yml
```

### Firefly Importer
```bash
helm upgrade --namespace finance firefly-iii-importer firefly-iii/firefly-iii-importer -f firefly/firefly-importer-values.yml
```

### Run Database Migrations
After upgrading Firefly III, run migrations:

```bash
kubectl exec -n finance deployment/firefly-iii -- php artisan migrate --force
```

---

## Configuration

### Initial Setup

1. Access the web interface
2. Create an admin account
3. Configure currency and locale
4. Set up account types (asset, liability, etc.)
5. Configure categories and tags

### Bank Import Configuration

Configure import sources in the Firefly Importer:
1. Access the importer interface
2. Add bank configuration
3. Map CSV columns to Firefly fields
4. Test import with sample data

### Automation

Firefly III supports recurring transactions:
- Set up recurring bills and income
- Configure automatic transaction rules
- Create budget categories
- Set spending limits

---

## Notes

- Firefly III is deployed via Helm chart in the `finance` namespace
- The importer runs as a separate deployment
- Uses PostgreSQL for data storage
- No PVC is explicitly configured in the values file (may use chart defaults)
- Consider adding ingress annotations for Authelia protection
- Regular backups are recommended for financial data
