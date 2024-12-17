import os
import shutil
import subprocess
import zipfile
from datetime import datetime
import pytz
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get environment variables
SOURCE_FOLDER = os.getenv("SOURCE_FOLDER")
SECOND_SOURCE_FOLDER = os.getenv("SECOND_SOURCE_FOLDER")
THIRD_SOURCE_FOLDER = os.getenv("THIRD_SOURCE_FOLDER")
BACKUP_FOLDER = os.getenv("BACKUP_FOLDER")
DB_BACKUP = os.getenv("DB_BACKUP") == "true"  # Convert to boolean
SECOND_SOURCE_BACKUP = os.getenv("SECOND_SOURCE_BACKUP") == "true"  # Convert to boolean
THIRD_SOURCE_BACKUP = os.getenv("THIRD_SOURCE_BACKUP") == "true"  # Convert to boolean
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
MAX_BACKUPS = int(os.getenv("MAX_BACKUPS"))  # Limit for number of backups

# Set timezone to Asia/Colombo
colombo_tz = pytz.timezone('Asia/Colombo')

# Get the current time in Asia/Colombo timezone
now_colombo = datetime.now(colombo_tz)

# Generate a timestamp for the backup folder in Asia/Colombo timezone
TIMESTAMP = now_colombo.strftime("%Y-%m-%d_%H-%M")
CURRENT_BACKUP_FOLDER = os.path.join(BACKUP_FOLDER, f"backup_{TIMESTAMP}")

# Function to create a zip backup of a folder
def zip_folder(source, zip_file):
    print(f"Backing up folder {source} to {zip_file}...")
    with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(source):
            for file in files:
                zipf.write(os.path.join(root, file), 
                           os.path.relpath(os.path.join(root, file), source))

# Function to backup the database as a zip file
def backup_database(zip_file):
    print("Backing up database...")
    dump_command = f"mysqldump -u {DB_USER} -p{DB_PASSWORD} -h {DB_HOST} {DB_NAME} | gzip"
    with subprocess.Popen(dump_command, shell=True, stdout=subprocess.PIPE) as proc:
        with open(zip_file, "wb") as f:
            shutil.copyfileobj(proc.stdout, f)

# Ensure the backup folder exists
if not os.path.exists(CURRENT_BACKUP_FOLDER):
    print(f"Creating backup folder: {CURRENT_BACKUP_FOLDER}")
    os.makedirs(CURRENT_BACKUP_FOLDER)

# Step 1: Backup the main source folder as a zip file
SOURCE_FOLDER_NAME = os.path.basename(SOURCE_FOLDER.rstrip('/'))  # Get folder name
SOURCE_BACKUP_ZIP = os.path.join(CURRENT_BACKUP_FOLDER, f"{SOURCE_FOLDER_NAME}_backup.zip")
zip_folder(SOURCE_FOLDER, SOURCE_BACKUP_ZIP)

# Step 2: Backup the second source folder if SECOND_SOURCE_BACKUP is true
if SECOND_SOURCE_BACKUP:
    SECOND_SOURCE_FOLDER_NAME = os.path.basename(SECOND_SOURCE_FOLDER.rstrip('/'))  # Get folder name
    SECOND_SOURCE_BACKUP_ZIP = os.path.join(CURRENT_BACKUP_FOLDER, f"{SECOND_SOURCE_FOLDER_NAME}_backup.zip")
    zip_folder(SECOND_SOURCE_FOLDER, SECOND_SOURCE_BACKUP_ZIP)

# Step 3: Backup the third source folder if THIRD_SOURCE_BACKUP is true
if THIRD_SOURCE_BACKUP:
    THIRD_SOURCE_FOLDER_NAME = os.path.basename(THIRD_SOURCE_FOLDER.rstrip('/'))  # Get folder name
    THIRD_SOURCE_BACKUP_ZIP = os.path.join(CURRENT_BACKUP_FOLDER, f"{THIRD_SOURCE_FOLDER_NAME}_backup.zip")
    zip_folder(THIRD_SOURCE_FOLDER, THIRD_SOURCE_BACKUP_ZIP)

# Step 4: Backup the database if DB_BACKUP is true
if DB_BACKUP:
    DB_BACKUP_ZIP = os.path.join(CURRENT_BACKUP_FOLDER, "db_backup.zip")
    backup_database(DB_BACKUP_ZIP)

# Step 5: Check the number of backups and remove the oldest if the limit is exceeded
existing_backups = sorted([f for f in os.listdir(BACKUP_FOLDER) if f.startswith("backup_")])

# If the number of backups exceeds the limit, remove the oldest ones
if len(existing_backups) > MAX_BACKUPS:
    print(f"Backup limit exceeded. Removing {len(existing_backups) - MAX_BACKUPS} oldest backup folder(s)...")
    for backup in existing_backups[:len(existing_backups) - MAX_BACKUPS]:  # Get the oldest backups
        backup_path = os.path.join(BACKUP_FOLDER, backup)
        print(f"Removing backup folder: {backup_path}")
        shutil.rmtree(backup_path)

print("Backup completed successfully.")
