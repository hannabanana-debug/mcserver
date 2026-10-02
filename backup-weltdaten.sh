#!/bin/bash

# Define source and destination directories
SOURCE_DIR="/home/admin/mcserver/weltdaten"     # Source directory to back up
BACKUP_DIR="/mnt/backup/weltdaten"       # Destination directory for backups

# Create a timestamp for the backup folder
TIMESTAMP=$(date +'%Y%m%d%H%M%S')

# Create a new backup folder with the timestamp
BACKUP_FOLDER="$BACKUP_DIR/backup_$TIMESTAMP"
mkdir -p "$BACKUP_FOLDER"

# Copy files to the backup folder
cp -r "$SOURCE_DIR"/* "$BACKUP_FOLDER"

# Log the completion of the backup
echo "Backup completed at $TIMESTAMP" >> "$BACKUP_DIR/backup_log.txt"

# Optional: Remove backups older than 30 days
find "$BACKUP_DIR" -type d -name "backup_*" -mtime +30 -exec rm -rf {} \;