# SkillPulse Automation Scripts

Helper scripts for SkillPulse Kubernetes deployment, monitoring, and operations.

## Scripts Overview

### 1. `deploy.sh` — Smart Deployment with Rollback
**Purpose**: Deploy with automatic health checks and rollback protection
**Usage**:
```bash
./scripts/deploy.sh
```
**What it does**:
- Saves previous deployment state
- Applies kustomize manifests
- Waits for rollouts
- Runs health checks (5 retries)
- Auto-rollsback if checks fail
- Shows final pod status

**When to use**: After pushing new code and running `make apply`

---

### 2. `health-check.sh` — System Health Verification
**Purpose**: Verify all components are healthy and running
**Usage**:
```bash
./scripts/health-check.sh
```
**What it does**:
- Checks Kubernetes cluster availability
- Validates namespace exists
- Shows pod status (ready count)
- Lists all services
- Tests API health endpoint
- Shows node status

**When to use**: After deployment, for troubleshooting, or in monitoring

---

### 3. `backup-mysql.sh` — Manual Database Backup
**Purpose**: Create a one-off backup of the MySQL database
**Usage**:
```bash
./scripts/backup-mysql.sh
```
**What it does**:
- Connects to MySQL pod
- Runs mysqldump
- Compresses with gzip
- Stores in `.backup/` directory
- Auto-cleans old backups (keeps last 7)
- Shows backup file size

**When to use**: Before major changes, manual backup needs

**Backup location**: `.backup/skillpulse_backup_YYYYMMDD_HHMMSS.sql.gz`

---

## Setup & Prerequisites

### 1. Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

### 2. Ensure `kubectl` is in PATH
```bash
# Verify kubectl works
kubectl cluster-info
```

### 3. Cluster Must Be Running
```bash
# Start cluster if not running
make up

# Verify cluster
kubectl get pods -n skillpulse
```

### 4. For Backup Script
- MySQL must be running in the cluster
- Credentials must match `k8s/10-mysql.yaml`

---

## Integration with CI/CD

### Automatic Backups (No Manual Script Needed)
Backups run automatically via CronJob:
- **Schedule**: Daily at 2 AM UTC
- **Storage**: Persistent volume (5Gi)
- **Retention**: Last 7 backups
- **No action needed** — fully automated

---

## Troubleshooting

### Script Returns "Permission Denied"
```bash
chmod +x scripts/deploy.sh scripts/health-check.sh scripts/backup-mysql.sh
```

### kubectl: command not found
Install kubectl or add to PATH:
```bash
# macOS
brew install kubectl

# Linux
sudo apt-get install kubectl

# Windows (via Chocolatey)
choco install kubernetes-cli
```

### Pod not ready during deploy
- Check logs: `kubectl logs -n skillpulse -l app=backend`
- Check events: `kubectl describe pod <pod-name> -n skillpulse`
- Wait longer: deployments can take 30-60s first time

### Backup script fails
```bash
# Verify MySQL pod is running
kubectl get pods -n skillpulse mysql-0

# Check credentials in secret
kubectl get secret skillpulse-db -n skillpulse -o yaml

# Test connection manually
kubectl exec -it -n skillpulse mysql-0 -- mysql -uroot -prootpassword123
```

---

## Manual Operations

### Restore from Backup
```bash
# Find backup file
ls -lh .backup/

# Decompress
gzip -d .backup/skillpulse_backup_YYYYMMDD_HHMMSS.sql.gz

# Restore to MySQL pod
kubectl exec -i -n skillpulse mysql-0 -- mysql -uskillpulse -pskillpulse123 skillpulse < backup.sql
```

### View Recent Logs
```bash
# All app logs
./scripts/health-check.sh
# or
kubectl logs -n skillpulse -l 'app in (mysql,backend,frontend)' --tail=50 -f
```

### Check Resource Usage
```bash
# CPU/Memory usage
kubectl top pods -n skillpulse

# Node usage
kubectl top nodes
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (check output) |
| 130 | Interrupted (Ctrl+C) |

---

## Example Workflows

### Fresh Deployment
```bash
make up
./scripts/health-check.sh
```

### After Code Changes
```bash
git push  # triggers CI/CD
# Wait for GitHub Actions to push images
git pull  # get updated k8s/kustomization.yaml
./scripts/deploy.sh
```

### Daily Operations
```bash
# Morning check
./scripts/health-check.sh

# Before making changes
./scripts/backup-mysql.sh

# After changes
./scripts/deploy.sh

# Evening check
./scripts/health-check.sh
```

### Emergency Rollback
```bash
# Deploy automatically handles this, but manual:
kubectl rollout undo deployment/backend -n skillpulse
kubectl rollout undo deployment/frontend -n skillpulse
```

---

## Advanced Usage

### Customize Backup Location
```bash
BACKUP_DIR=/custom/path ./scripts/backup-mysql.sh
```

### Customize Deploy Timeout
Edit `scripts/deploy.sh` and change `TIMEOUT=300` to desired seconds

### Manual Health Check Loop
```bash
while true; do
  ./scripts/health-check.sh
  sleep 60
done
```

---

**Last Updated**: May 2026
**Version**: 1.0
**Status**: Production-Ready 🚀
