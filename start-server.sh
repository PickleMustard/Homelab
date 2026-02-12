#!/bin/bash
k3s server --data-dir /app-storage --token-file /app-storage/server/token --default-runtime nvidia --config /app-storage/k3s/k3s-config/config.yaml --tls-san 'picklemustard.dev' &
