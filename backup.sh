#!/bin/bash

# Directories and Configurations
ROOT_DIR="your_root_directory"
BACKUP_DIR="${ROOT_DIR}/backup"
LOG_FILE="${ROOT_DIR}/backup.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FOLDER="${BACKUP_DIR}/${TIMESTAMP}"

# MySQL Configuration
MYSQL_USER="your_mysql_user"
MYSQL_PASSWORD="your_mysql_password"
MYSQL_DATABASE="your_database_name"

# Ghost Content Directory
GHOST_CONTENT_DIR="${ROOT_DIR}/ghost/content"

# Rclone Configuration for R2 Backup
RCLONE_REMOTE="r2:bucket_name/backup"

# Failure Report URL (BetterStack Heartbeat)
FAILURE_REPORT_URL="https://uptime.betterstack.com/api/v1/heartbeat/xxx"

# Create a new backup folder
mkdir -p "$BACKUP_FOLDER"
echo "========================================" | tee -a "$LOG_FILE"
echo "🎉 Creating a new backup folder: $BACKUP_FOLDER" | tee -a "$LOG_FILE"

# Backup Start
echo "🔹 Backup started at $(date)" | tee -a "$LOG_FILE"

# Cleanup old local backups
echo "🔄 Cleaning up old backups (local)..." | tee -a "$LOG_FILE"

BACKUP_COUNT=$(ls -1t ${BACKUP_DIR} | grep -v '/$' | wc -l)

if [ $BACKUP_COUNT -gt 3 ]; then
    TO_REMOVE_COUNT=$((BACKUP_COUNT - 3))
    
    echo "❌ Removing $TO_REMOVE_COUNT oldest local backups..." | tee -a "$LOG_FILE"
    ls -1t ${BACKUP_DIR} | grep -v '/$' | tail -n $TO_REMOVE_COUNT | while read -r OLDEST_BACKUP; do
        echo "❌ Removing old local backup: ${OLDEST_BACKUP}" | tee -a "$LOG_FILE"
        rm -rf "${BACKUP_DIR}/${OLDEST_BACKUP}"
        
        if [ $? -ne 0 ]; then
            echo "❌ Failed to remove old backup locally! Check the logs for errors." | tee -a "$LOG_FILE"
            curl "$FAILURE_REPORT_URL/1" -d "error=Failed to remove old backup locally"
            exit 1
        else
            echo "✅ Successfully removed oldest local backup: ${OLDEST_BACKUP}" | tee -a "$LOG_FILE"
        fi
    done
fi

# Backup MySQL Database
echo "🔄 Backing up MySQL database..." | tee -a "$LOG_FILE"
mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" > "${BACKUP_FOLDER}/mysql_backup.sql"
if [ $? -eq 0 ]; then
    echo "✅ MySQL backup completed successfully." | tee -a "$LOG_FILE"
else
    echo "❌ MySQL backup failed! Check the logs for errors." | tee -a "$LOG_FILE"
    echo "🛑 Exiting the script. No further steps will be taken." | tee -a "$LOG_FILE"

    curl "$FAILURE_REPORT_URL/1" -d "error=MySQL backup failed"
    exit 1
fi

# Backup Ghost Content Directory
echo "🔄 Backing up Ghost CMS content directory..." | tee -a "$LOG_FILE"
zip -r "${BACKUP_FOLDER}/ghost_content.zip" "$GHOST_CONTENT_DIR"
if [ $? -eq 0 ]; then
    echo "✅ Ghost content backup completed successfully." | tee -a "$LOG_FILE"
else
    echo "❌ Ghost content backup failed! Check the logs for errors." | tee -a "$LOG_FILE"
    echo "🛑 Exiting the script. No further steps will be taken." | tee -a "$LOG_FILE"

    curl "$FAILURE_REPORT_URL/1" -d "error=Ghost content backup failed"
    exit 1
fi

# Upload Backup to R2
echo "🔄 Uploading backup to R2..." | tee -a "$LOG_FILE"
rclone copy "$BACKUP_FOLDER" "$RCLONE_REMOTE/${TIMESTAMP}" --progress >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Upload to R2 completed successfully." | tee -a "$LOG_FILE"
else
    echo "❌ Upload to R2 failed! Check the logs for errors." | tee -a "$LOG_FILE"
    echo "🛑 Exiting the script. No further steps will be taken." | tee -a "$LOG_FILE"

    curl "$FAILURE_REPORT_URL/1" -d "error=Upload to R2 failed"
    exit 1
fi

# Cleanup Old Backups in R2
echo "🔄 Cleaning up old backups in R2..." | tee -a "$LOG_FILE"

RCLONE_BACKUP_COUNT=$(rclone lsf "$RCLONE_REMOTE" | wc -l)

if [ $RCLONE_BACKUP_COUNT -gt 3 ]; then
    TO_REMOVE_COUNT=$((RCLONE_BACKUP_COUNT - 3))
    
    echo "❌ Removing $TO_REMOVE_COUNT oldest backups from R2..." | tee -a "$LOG_FILE"
    rclone lsf "$RCLONE_REMOTE" | head -n $TO_REMOVE_COUNT | while read -r OLDEST_BACKUP_R2; do
        echo "❌ Removing old backup from R2: ${OLDEST_BACKUP_R2}" | tee -a "$LOG_FILE"
        rclone delete "$RCLONE_REMOTE/$OLDEST_BACKUP_R2" >> "$LOG_FILE" 2>&1
        
        if [ $? -ne 0 ]; then
            echo "❌ Failed to remove old backup in R2! Check the logs for errors." | tee -a "$LOG_FILE"
            curl "$FAILURE_REPORT_URL/1" -d "error=Failed to remove old backup in R2"
            exit 1
        else
            echo "✅ Successfully removed oldest backup from R2: ${OLDEST_BACKUP_R2}" | tee -a "$LOG_FILE"
        fi
    done
fi

# Backup Completion
echo "🔹 Backup completed at $(date)" | tee -a "$LOG_FILE"
echo "🎉 All steps completed successfully. Your backup is safe!" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Report Success to BetterStack
curl "$FAILURE_REPORT_URL"

exit 0
