import os
import shutil
import subprocess
import gzip
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get environment variables
SOURCE_FOLDER = os.getenv("SOURCE_FOLDER")
SECOND_SOURCE_FOLDER = os.getenv("SECOND_SOURCE_FOLDER")
BACKUP_FOLDER = os.getenv("BACKUP_FOLDER")
DB_BACKUP = os.getenv("DB_BACKUP") == "true"  # Convert to boolean
SECOND_SOURCE_BACKUP = os.getenv("SECOND_SOURCE_BACKUP") == "true"  # Convert to boolean
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
MAX_BACKUP_SIZE = float(os.getenv("MAX_BACKUP_SIZE"))  # Convert to float (GB)

# Generate a timestamp for the backup folder
TIMESTAMP = datetime.now().strftime("%Y%m%d_%H%M%S")
CURRENT_BACKUP_FOLDER = os.path.join(BACKUP_FOLDER, f"backup_{TIMESTAMP}")

# Function to check total size of a folder
def get_folder_size(folder):
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(folder):
        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            total_size += os.path.getsize(filepath)
    return total_size / (1024 * 1024 * 1024)  # Convert to GB

# Function to create a backup of a folder
def backup_folder(source, backup_file):
    print(f"Backing up folder {source} to {backup_file}...")
    shutil.make_archive(backup_file.replace('.tar.gz', ''), 'gztar', source)

# Function to backup the database
def backup_database(backup_file):
    print("Backing up database...")
    dump_command = f"mysqldump -u {DB_USER} -p{DB_PASSWORD} -h {DB_HOST} {DB_NAME} | gzip > {backup_file}"
    subprocess.run(dump_command, shell=True, check=True)

# Ensure the backup folder exists
if not os.path.exists(CURRENT_BACKUP_FOLDER):
    print(f"Creating new backup folder: {CURRENT_BACKUP_FOLDER}")
    os.makedirs(CURRENT_BACKUP_FOLDER)

# Step 
