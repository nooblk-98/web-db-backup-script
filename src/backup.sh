#!/bin/bash

# Load environment variables
source .env

# Current timestamp for backup naming
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Define backup file names
SOURCE_BACKUP="${BACKUP_FOLDER}/source_backup_${TIMESTAMP}.tar.gz"
SECOND_SOURCE_BACKUP_FILE="${BACKUP_FOLDER}/second_source_backup_${TIMESTAMP}.tar.gz"
DB_BACKUP_FILE="${BACKUP_FOLDER}/db_backup_${TIMESTAMP}.sql.gz"

# Step 1: Check if the backup folder exists, if not, create it
if [ ! -d "$BACKUP_FOLDER" ]; then
    echo "Backup folder does not exist. Creating it..."
    mkdir -p "$BACKUP_FOLDER"
    echo "Backup folder created at $BACKUP_FOLDER."
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

# Step 5: Check the backup folder size
BACKUP_SIZE=$(du -sh "$BACKUP_FOLDER" | cut -f1 | sed 's/[A-Za-z]*//g')  # Get size in GB

# Step 6: If the backup folder size exceeds the maximum size, remove the oldest backup
if (( $(echo "$BACKUP_SIZE > $MAX_BACKUP_SIZE" | bc -l) )); then
    echo "Backup folder size exceeds $MAX_BACKUP_SIZE GB, removing oldest backup..."
    OLDEST_BACKUP=$(ls -t "$BACKUP_FOLDER" | tail -n 1)
    rm -rf "${BACKUP_FOLDER}/${OLDEST_BACKUP}"
    echo "Oldest backup ${OLDEST_BACKUP} removed."
fi

echo "Backup completed successfully."
