#!/bin/bash
# Smart Deployment Script with Automated Rollback
# Usage: ./deploy.sh

set -e

NAMESPACE="skillpulse"
TIMEOUT=300
HEALTH_CHECK_RETRIES=5

echo "================================================"
echo "SkillPulse Smart Deployment"
echo "================================================"

# Store previous deployment state
echo "[1] Storing previous deployment state..."
PREV_BACKEND=$(kubectl get deployment backend -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "none")
PREV_FRONTEND=$(kubectl get deployment frontend -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "none")
echo "    Previous Backend: $PREV_BACKEND"
echo "    Previous Frontend: $PREV_FRONTEND"

# Apply new manifests
echo "[2] Applying kustomize manifests..."
kubectl apply -k k8s

# Wait for rollouts
echo "[3] Waiting for rollouts..."
kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=${TIMEOUT}s || {
  echo "    ✗ Backend rollout failed, rolling back..."
  kubectl set image deployment/backend backend="$PREV_BACKEND" -n "$NAMESPACE"
  exit 1
}
echo "    ✓ Backend rolled out successfully"

kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=${TIMEOUT}s || {
  echo "    ✗ Frontend rollout failed, rolling back..."
  kubectl set image deployment/frontend frontend="$PREV_FRONTEND" -n "$NAMESPACE"
  exit 1
}
echo "    ✓ Frontend rolled out successfully"

# Health checks
echo "[4] Running health checks..."
RETRIES=0
while [ $RETRIES -lt $HEALTH_CHECK_RETRIES ]; do
  if curl -s http://localhost:8888/health | grep -q "healthy"; then
    echo "    ✓ API is healthy"
    break
  fi
  RETRIES=$((RETRIES + 1))
  if [ $RETRIES -lt $HEALTH_CHECK_RETRIES ]; then
    echo "    ⚠ Health check attempt $RETRIES/$HEALTH_CHECK_RETRIES failed, retrying..."
    sleep 5
  fi
done

if [ $RETRIES -eq $HEALTH_CHECK_RETRIES ]; then
  echo "    ✗ Health checks failed, rolling back..."
  kubectl set image deployment/backend backend="$PREV_BACKEND" -n "$NAMESPACE"
  kubectl set image deployment/frontend frontend="$PREV_FRONTEND" -n "$NAMESPACE"
  exit 1
fi

# Show deployment status
echo "[5] Deployment Status:"
kubectl get pods -n "$NAMESPACE"

echo "================================================"
echo "✓ Deployment completed successfully!"
echo "================================================"
