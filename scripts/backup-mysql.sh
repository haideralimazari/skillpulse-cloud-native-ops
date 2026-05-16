#!/bin/bash
# MySQL Backup Script for SkillPulse
# Usage: ./backup-mysql.sh

set -e

BACKUP_DIR="${BACKUP_DIR:-.backup}"
NAMESPACE="skillpulse"
MYSQL_POD="mysql-0"
DB_USER="skillpulse"
DB_PASSWORD="skillpulse123"
DB_NAME="skillpulse"

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/skillpulse_backup_${TIMESTAMP}.sql"

echo "[INFO] Starting MySQL backup..."
echo "[INFO] Target: $BACKUP_FILE"

# Execute mysqldump
kubectl exec -n "$NAMESPACE" "$MYSQL_POD" -- \
  mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
  # Compress the backup
  gzip "$BACKUP_FILE"
  BACKUP_FILE="${BACKUP_FILE}.gz"
  
  # Get file size
  FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  
  echo "[SUCCESS] Backup completed: $BACKUP_FILE ($FILE_SIZE)"
  
  # Keep only last 7 backups
  echo "[INFO] Cleaning old backups (keeping last 7)..."
  ls -t "$BACKUP_DIR"/skillpulse_backup_*.sql.gz | tail -n +8 | xargs -r rm
  
  # List recent backups
  echo "[INFO] Recent backups:"
  ls -lh "$BACKUP_DIR"/skillpulse_backup_*.sql.gz | tail -n 5
else
  echo "[ERROR] Backup failed!"
  exit 1
fi
