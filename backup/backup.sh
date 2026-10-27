#!/bin/sh
# Nightly WordPress database backup -> S3 (MinIO locally, AWS S3 in production)
set -eu
umask 077

: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID must be set}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY must be set}"
: "${DB_PASSWORD:?DB_PASSWORD must be set}"

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

S3_ENDPOINT="${S3_ENDPOINT:-http://s3:9000}"
BUCKET="${S3_BUCKET:-bsf-backups}"
PREFIX="site-x"

STAMP=$(date +%Y%m%d-%H%M%S)
SQL_FILE="/tmp/wordpress-$STAMP.sql"
FILE="/tmp/wordpress-$STAMP.sql.gz"

cleanup() {
  rm -f "$SQL_FILE" "$FILE"
}
trap cleanup EXIT HUP INT TERM

echo "[backup] dumping database ..."
if ! mariadb-dump -h db -u root --password="$DB_PASSWORD" --all-databases > "$SQL_FILE"; then
  echo "[backup] ERROR: database dump failed" >&2
  exit 1
fi

if ! gzip -c "$SQL_FILE" > "$FILE"; then
  echo "[backup] ERROR: compression failed" >&2
  exit 1
fi
rm -f "$SQL_FILE"

echo "[backup] uploading ..."
if ! aws --endpoint-url "$S3_ENDPOINT" s3 cp "$FILE" \
  "s3://$BUCKET/$PREFIX/$(basename "$FILE")"; then
  echo "[backup] ERROR: upload failed" >&2
  exit 1
fi

echo "[backup] backup uploaded successfully"
