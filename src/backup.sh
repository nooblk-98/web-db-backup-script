#!/bin/bash

# Load environment variables
source .env

# Current timestamp for backup naming
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create a new backup folder based on the current timestamp
CURRENT_BACKUP_FOLDER="${BACKUP_FOLDER}/backup_${TIMESTAMP}"

# Define the backup file names
SOURCE_BACKUP="${CURRENT_BACKUP_FOLDER}/source_backup.tar.gz"
SECOND_SOURCE_BACKUP_FILE="${CURRENT_BACKUP_FOLDER}/second_source_backup.tar.gz"
DB_BACKUP_FILE="${CURRENT_BACKUP_FOLDER}/db_backup.sql.gz"

# Step 1: Check if the backup folder exists, if not, create it
if [ ! -d "$CURRENT_BACKUP_FOLDER" ]; then
    echo "Creating new backup folder: $CURRENT_BACKUP_FOLDER"
    mkdir -p "$CURRENT_BACKUP_FOLDER"
fi

# Step 2: Backup the main source folder
echo "Starting main source folder backup..."
tar -czf "$SOURCE_BACKUP" -C "$SOURCE_FOLDER" .

# Step 3: Backup the second source folder if SECOND_SOURCE_BACKUP is true
if [ "$SECOND_SOURCE_BACKUP" == "true" ]; then
    echo "Starting second source folder backup..."
    tar -czf "$SECOND_SOURCE_BACKUP_FILE" -C "$SECOND_SOURCE_FOLDER" .
fi

# Step 4: Backup the database if DB_BACKUP is true
if [ "$DB_BACKUP" == "true" ]; then
    echo "Starting database backup..."
    mysqldump -u "$DB_USER" -p"$DB_PASSWORD" -h "$DB_HOST" "$DB_NAME" | gzip > "$DB_BACKUP_FILE"
fi

# Step 5: Calculate the total size of the existing backup folders excluding the current one
TOTAL_BACKUP_SIZE=$(du -sh "$BACKUP_FOLDER"/* | grep -v "$CURRENT_BACKUP_FOLDER" | cut -f1 | sed 's/[A-Za-z]*//g' | awk '{s+=$1} END {print s}')

# Step 6: If the backup folder size exceeds the maximum size, remove the oldest backup folder(s)
if (( $(echo "$TOTAL_BACKUP_SIZE > $MAX_BACKUP_SIZE" | bc -l) )); then
    echo "Backup folder size exceeds $MAX_BACKUP_SIZE GB, removing oldest backup folder(s)..."

    # List all backup folders and sort them by date (oldest first), then remove the oldest one(s)
    OLDEST_FOLDERS=$(ls -t "$BACKUP_FOLDER" | tail -n 2)
    for folder in $OLDEST_FOLDERS; do
        echo "Removing folder: $BACKUP_FOLDER/$folder"
        rm -rf "$BACKUP_FOLDER/$folder"
    done
    echo "Oldest backup folders removed."
fi

echo "Backup completed successfully."
