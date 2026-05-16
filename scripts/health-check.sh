#!/bin/bash
# Health Check Script for SkillPulse
# Usage: ./health-check.sh

set -e

NAMESPACE="skillpulse"
HEALTH_API="http://localhost:8888/health"

echo "================================================"
echo "SkillPulse Health Check"
echo "================================================"

# Check if cluster is running
echo "[1] Checking Kubernetes cluster..."
if ! kubectl cluster-info &> /dev/null; then
  echo "    ✗ Cluster not found"
  exit 1
fi
echo "    ✓ Cluster is running"

# Check namespace
echo "[2] Checking namespace: $NAMESPACE..."
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo "    ✗ Namespace $NAMESPACE not found"
  exit 1
fi
echo "    ✓ Namespace exists"

# Check pods
echo "[3] Checking pod status..."
POD_COUNT=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
READY_COUNT=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[?(@.status.conditions[*].type=="Ready")].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -c "True" || true)

if [ "$POD_COUNT" -eq 0 ]; then
  echo "    ✗ No pods found"
  exit 1
fi
echo "    ✓ Pods: $READY_COUNT/$POD_COUNT ready"

# Check services
echo "[4] Checking services..."
kubectl get svc -n "$NAMESPACE" | tail -n +2 | while read line; do
  SVC_NAME=$(echo "$line" | awk '{print $1}')
  echo "    ✓ Service: $SVC_NAME"
done

# Check API health
echo "[5] Checking application health..."
if curl -s "$HEALTH_API" | grep -q "healthy"; then
  echo "    ✓ API health check passed"
else
  echo "    ⚠ API health check failed (app may still be starting)"
fi

# Show pod details
echo "[6] Pod Details:"
kubectl get pods -n "$NAMESPACE" -o wide

# Show node status
echo "[7] Node Status:"
kubectl get nodes

echo "================================================"
echo "✓ Health check completed successfully"
echo "================================================"
