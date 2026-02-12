#!/bin/bash

set -e

echo "=== Prometheus Deployment Script ==="
echo ""

echo "Step 1: Checking database configuration..."
# Check if grafana-db-credentials secret exists and has been configured
if kubectl get secret grafana-db-credentials -n monitoring &>/dev/null; then
  PASSWORD=$(kubectl get secret grafana-db-credentials -n monitoring -o jsonpath="{.data.password}" | base64 --decode)
  if [ "$PASSWORD" = "SET_PASSWORD_HERE" ]; then
    echo "⚠️  WARNING: grafana-db-credentials secret has not been configured yet!"
    echo ""
    echo "Please complete database setup first:"
    echo "1. Follow instructions in POSTGRESQL-SETUP.md"
    echo "2. Update the secret with your password:"
    echo "   kubectl create secret generic grafana-db-credentials \\"
    echo "     --from-literal=password='YOUR_PASSWORD' \\"
    echo "     -n monitoring"
    echo ""
    echo "Then run this script again."
    exit 1
  else
    echo "✓ Database configuration found"
  fi
else
  echo "⚠️  WARNING: grafana-db-credentials secret not found!"
  echo ""
  echo "Please create the secret first:"
  echo "   kubectl create secret generic grafana-db-credentials \\"
  echo "     --from-literal=password='YOUR_PASSWORD' \\"
  echo "     -n monitoring"
  echo ""
  echo "And complete database setup (see POSTGRESQL-SETUP.md)"
  echo "Then run this script again."
  exit 1
fi
echo ""


echo "Step 5: Deploying kube-prometheus-stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/prometheus-values.yml
echo "✓ kube-prometheus-stack deployed"
echo ""

echo "Step 6: Creating Prometheus ingress..."
kubectl apply -f monitoring/prometheus-ingress.yml
echo "✓ Prometheus ingress created"
echo ""

echo "Step 7: Creating Grafana ingress..."
kubectl apply -f monitoring/grafana-ingress.yml
echo "✓ Grafana ingress created"
echo ""

echo "Step 8: Creating certificates (optional - requires cert-manager)..."
kubectl apply -f monitoring/prometheus-certificate.yml 2>/dev/null || echo "  ! Skipping Prometheus certificate (cert-manager may not be configured)"
kubectl apply -f monitoring/grafana-certificate.yml 2>/dev/null || echo "  ! Skipping Grafana certificate (cert-manager may not be configured)"
echo ""

echo "Step 9: Creating ServiceMonitors..."
kubectl apply -f monitoring/servicemonitors/
echo "✓ ServiceMonitors created"
echo ""

echo "Step 10: Deploying postgres-exporter..."
kubectl apply -f postgres/postgres-exporter-secret.yml
kubectl apply -f postgres/postgres-exporter.yml
echo "✓ postgres-exporter deployed"
echo ""

echo "Step 11: Deploying redis-exporter..."
kubectl apply -f redis/redis-exporter.yml
echo "✓ redis-exporter deployed"
echo ""

echo "=== Deployment Complete ==="
echo ""
echo "Next steps:"
echo "1. Add DNS records:"
echo "   - prometheus.picklemustard.dev"
echo "   - grafana.picklemustard.dev"
echo ""
echo "2. Access dashboards:"
echo "   - Prometheus: http://prometheus.picklemustard.dev"
echo "   - Grafana: http://grafana.picklemustard.dev"
echo "   Default Grafana credentials:"
echo "   Username: admin"
echo "   Password: (run: kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
echo ""
echo "3. Verify Grafana database connection:"
echo "   kubectl logs -n monitoring deployment/prometheus-grafana -c grafana | grep -i 'database'"
echo ""
echo "4. Verify targets:"
echo "   kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090"
echo "   Open http://localhost:9090/targets"
echo ""
echo "5. Verify Grafana PostgreSQL integration:"
echo "   Check that Grafana logs show 'Connecting to DB' with 'dbtype=postgres'"
