#!/bin/bash
# Script to ensure all required Airbyte Docker Compose host files and directories exist
set -e

# Change to the script's directory (should be /home/maqmalak/Airbyte-Docker/airflow)
cd "$(dirname "$0")"

# Load .env variables
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

# List of required files and directories
REQUIRED_PATHS=(
  "./flags.yml"
  "./configs"
  "./temporal/dynamicconfig"
  "./include"
  "./dags"
  "./logs"
  "./plugins"
  "${LOCAL_ROOT:-/tmp/airbyte_local}"
)

# Create directories and files if missing
for path in "${REQUIRED_PATHS[@]}"; do
  if [[ "$path" == *.yml ]]; then
    if [ ! -f "$path" ]; then
      echo "Creating file: $path"
      touch "$path"
    fi
  else
    if [ ! -d "$path" ]; then
      echo "Creating directory: $path"
      mkdir -p "$path"
    fi
  fi
done

echo "All required files and directories are present."
