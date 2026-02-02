#!/usr/bin/env bash
set -euxo pipefail

# Variables from instance metadata (templated by Terraform)
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DISK_DEVICE="/dev/disk/by-id/google-n8n-pd"
MOUNT_POINT="/mnt/postgres"

# Update and install Docker
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Prepare persistent disk
mkdir -p "$MOUNT_POINT"
if ! blkid "$DISK_DEVICE" >/dev/null 2>&1; then
  mkfs.ext4 -F "$DISK_DEVICE"
fi
mount | grep -q "$MOUNT_POINT" || mount "$DISK_DEVICE" "$MOUNT_POINT"
echo "$DISK_DEVICE $MOUNT_POINT ext4 defaults 0 0" >> /etc/fstab

# Create data dir
mkdir -p "$MOUNT_POINT/data"

# Run Postgres container
docker pull postgres:15-alpine
# If container exists, replace it
if docker ps -a --format '{{.Names}}' | grep -q '^postgres$'; then
  docker rm -f postgres || true
fi

docker run -d \
  --name postgres \
  -e POSTGRES_DB="$DB_NAME" \
  -e POSTGRES_USER="$DB_USER" \
  -e POSTGRES_PASSWORD="$DB_PASSWORD" \
  -v "$MOUNT_POINT/data:/var/lib/postgresql/data" \
  -p 5432:5432 \
  --restart unless-stopped \
  postgres:15-alpine

# Simple health check loop
for i in $(seq 1 30); do
  if docker exec postgres pg_isready -U "$DB_USER" -d "$DB_NAME"; then
    echo "Postgres is ready"
    exit 0
  fi
  sleep 2
done

echo "Postgres failed to become ready in time"
exit 1
