# Ghost Backup Script

Secure your Ghost CMS data with this automated backup solution. This script provides seamless backup of your MySQL database and content files to Cloudflare R2 storage, with real-time monitoring through BetterStack Heartbeat. Perfect for Ghost CMS administrators who want reliable, cloud-based backup automation without the complexity.

## Features

- MySQL database backup automation
- Ghost CMS content directory compression
- Cloudflare R2 cloud storage integration
- Automatic cleanup of old backups
- BetterStack Heartbeat status monitoring

## Prerequisites

- Linux or macOS operating system
- `mysqldump` for database backups
- `zip` for content compression
- `rclone` for cloud storage operations
- Cloudflare account with R2 bucket
- BetterStack Heartbeat account

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/shofistwn/ghost-backup-script
   cd ghost-backup-script
   ```

2. Update the configuration in `backup.sh`:

   ```bash
   ROOT_DIR="your_root_directory"
   MYSQL_USER="your_mysql_user"
   MYSQL_PASSWORD="your_mysql_password"
   MYSQL_DATABASE="your_database_name"
   GHOST_CONTENT_DIR="${ROOT_DIR}/ghost/content"
   RCLONE_REMOTE="r2:bucket_name/backup"
   FAILURE_REPORT_URL="https://uptime.betterstack.com/api/v1/heartbeat/xxx"
   ```

3. Configure Rclone for Cloudflare R2:

   ```ini
   [r2]
   type = s3
   provider = Cloudflare
   access_key_id = xxx
   secret_access_key = xxx
   region = auto
   endpoint = https://xxx.r2.cloudflarestorage.com
   ```

4. Make the script executable:

   ```bash
   chmod +x backup.sh
   ```

5. Set up automatic backups (optional):
   ```bash
   crontab -e
   # Add this line to run daily at 2 AM:
   0 2 * * * /path/to/ghost-backup-script/backup.sh > /dev/null 2>&1
   ```

## How It Works

### Backup Process

1. **Initialization**

   - Creates a timestamped backup folder (e.g., `backup/2025-02-01_02-00-00/`)

2. **Database Backup**

   - Generates MySQL database dump
   - Saves as `mysql_backup.sql`

3. **Content Backup**

   - Compresses Ghost CMS content directory
   - Creates `ghost_content.zip`

4. **Cloud Storage**

   - Uploads backup folder to Cloudflare R2
   - Maintains latest 3 backups only

5. **Status Reporting**
   - Reports success/failure to BetterStack Heartbeat
   - Logs all operations locally

### Directory Structure

```
your_root_directory/
├── backup/
│   ├── 2025-02-01_02-00-00/
│   │   ├── mysql_backup.sql
│   │   └── ghost_content.zip
│   └── 2025-02-02_02-00-00/
│       ├── mysql_backup.sql
│       └── ghost_content.zip
└── backup.log
```

## Monitoring and Logs

### Local Logging

- All operations are logged to `backup.log`

### BetterStack Heartbeat Integration

- Success notifications sent to `/api/v1/heartbeat/xxx`
- Failure notifications sent to `/api/v1/heartbeat/xxx/1`

## Issues and Feedback

If you encounter any problems or have suggestions for improvements, please feel free to open an issue in this repository. While this is a personal project, I appreciate feedback that can help make it better.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- [Rclone](https://rclone.org/) - Cloud storage management tool
- [BetterStack Heartbeat](https://betterstack.com/) - Monitoring platform
