Automated Backup System

Project Overview: The Automated Backup System is a Bash-based utility that automatically creates compressed backups, verifies their integrity, and cleans up older backups using configurable retention rules. It is designed to run safely, efficiently, and reliably — ideal for developers, system administrators, or anyone who needs automated file backups on Linux/macOS.

This project helps prevent data loss by:

Automatically creating timestamped backups Verifying backup integrity using checksums Managing backup retention (daily, weekly, monthly) Logging every operation for full traceability

Create timestamped .tar.gz backups :

Automatically skip unwanted folders (like .git, node_modules, .cache) Generate checksum (.sha256) for integrity verification Delete old backups based on daily/weekly/monthly rules Dry-run mode (simulate actions without changing anything) Prevent multiple script runs using lock files Restore from any backup archive Comprehensive logging system (backup.log) Configurable via backup.config file

Project Structure:

backup-system/ ├── backup.sh # Main script ├── backup.config # Configuration file ├── README.md # Documentation ├── logs/ │ └── backup.log # Activity logs ├── backups/ │ ├── daily/ │ ├── weekly/ │ └── monthly/ └── test_data/ # Sample data for testing

Configuration File (backup.config) :

Customize all settings here — no need to modify the script itself.
Installation Steps
Clone the repository:
git clone https://github.com/<your-username>/backup-system.git
cd backup-system
 Make the script executable: chmod +x backup.sh

 Ensure folders exist (logs, backups, test_data): mkdir -p logs backups/daily backups/weekly backups/monthly test_data/documents

Basic Usage Examples

*Create a backup: ./backup.sh ./test_data/documents

*Dry run (simulate backup without creating files): ./backup.sh --dry-run ./test_data/documents

List all backups: ./backup.sh --list
*Restore a backup: ./backup.sh --restore backups/daily/backup-2025-11-03-1607.tar.gz --to restored_files

 How It Works

Backup Creation
The script compresses the folder using tar -czf into a .tar.gz file. Excluded folders (like .git, node_modules, .cache) are skipped using patterns from backup.config. Each backup is timestamped, e.g., backup-2025-11-03-1607.tar.gz.

Checksum Verification *A SHA256 checksum is generated for every backup: sha256sum backup-2025-11-03-1607.tar.gz > backup-2025-11-03-1607.tar.gz.sha256
*Verification ensures backup integrity: sha256sum -c backup-2025-11-03-1607.tar.gz.sha256

Backup Rotation (Deletion)
Daily: Keep last 7 backups.

Weekly: Keep last 4 backups.

Monthly: Keep last 3 backups.

The script deletes the oldest backups beyond these limits to save space. All actions are logged in logs/backup.log.
Checksum Verification:

Every backup file has a matching .sha256 file generated via: sha256sum backup-2025-11-07-1030.tar.gz > backup-2025-11-07-1030.tar.gz.sha256

During Verification : sha256sum -c backup-2025-11-07-1030.tar.gz.sha256 If the result is OK, integrity is confirmed.

Design Decisions: 1.Bash chosen for portability and simplicity. 2.Tar + gzip provides efficient compression and easy restore. 3.SHA256 checksums ensure data integrity. 4.Lock file prevents accidental double runs. 5.Config file separates logic from settings, making it user-friendly. 6.Logs provide full audit trail of backups and deletions.

Known Limitations: No email notifications (can be added with mail or sendmail) No incremental backup feature (only full backups for now) Works best on Linux/macOS — not natively tested on Windows PowerShell

Future Improvements: Add email notification system Add incremental backups using rsync Add remote upload (e.g., AWS S3, Google Drive) Add GUI dashboard

Conclusion: This project provides a reliable, configurable, and easy-to-use backup automation system. It helps maintain organized, verified backups while saving time and storage space.
