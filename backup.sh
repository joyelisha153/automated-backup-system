#!/usr/bin/env bash
set -u

timestamp() { date '+%Y-%m-%d-%H%M'; }

log() {
  local level="$1"; shift
  local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $level: $*" | tee -a "$LOG_FILE"
}

die() {
  log "ERROR" "$*"
  cleanup
  exit 1
}

cleanup() {
  if [ -n "${LOCK_FILE:-}" ] && [ -f "$LOCK_FILE" ]; then
    rm -f "$LOCK_FILE"
  fi
  if [ -n "${TMP_ARCHIVE:-}" ] && [ -f "$TMP_ARCHIVE" ]; then
    rm -f "$TMP_ARCHIVE"
  fi
}

trap 'cleanup' EXIT INT TERM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/backup.config"

BACKUP_DESTINATION="$HOME/backups"
EXCLUDE_PATTERNS=".git,node_modules,.cache"
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3
LOG_FILE="$SCRIPT_DIR/backup.log"
LOCK_FILE="/tmp/backup-system.lock"
CHECKSUM_ALGO="md5"

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE" || die "Failed to read config file $CONFIG_FILE"
else
  log "WARN" "Config file not found at $CONFIG_FILE — using defaults."
fi

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ $# -lt 1 ]; then
  cat <<EOF
Usage:
  $0 [--dry-run] /path/to/source
Examples:
  $0 /home/user/documents
  $0 --dry-run /home/user/documents
EOF
  exit 0
fi

SOURCE_DIR="$1"

if [ ! -d "$SOURCE_DIR" ]; then
  die "Error: Source folder not found: $SOURCE_DIR"
fi
if [ ! -r "$SOURCE_DIR" ]; then
  die "Error: Cannot read folder, permission denied: $SOURCE_DIR"
fi

if [ ! -d "$BACKUP_DESTINATION" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    log "INFO" "Would create backup destination: $BACKUP_DESTINATION"
  else
    mkdir -p "$BACKUP_DESTINATION" || die "Cannot create backup destination: $BACKUP_DESTINATION"
    log "INFO" "Created backup destination: $BACKUP_DESTINATION"
  fi
fi

if [ -f "$LOCK_FILE" ]; then
  die "Another backup appears to be running (lock file exists: $LOCK_FILE)"
fi

if [ "$DRY_RUN" -eq 0 ]; then
  echo "$$" > "$LOCK_FILE" || die "Cannot create lock file $LOCK_FILE"
fi

IFS=',' read -r -a EXC_ARR <<< "$EXCLUDE_PATTERNS"
EXCLUDE_ARGS=()
for pat in "${EXC_ARR[@]}"; do
  pat_trim="$(echo "$pat" | xargs)"
  [ -n "$pat_trim" ] && EXCLUDE_ARGS+=(--exclude="$pat_trim")
done

TS="$(timestamp)"
BASENAME="backup-$TS.tar.gz"
TMP_ARCHIVE="$(mktemp --tmpdir "$BASENAME.partial.XXXXXX")"
FINAL_ARCHIVE="$BACKUP_DESTINATION/$BASENAME"
CHECKSUM_FILE="$FINAL_ARCHIVE.$( [ "$CHECKSUM_ALGO" = "sha256" ] && echo sha256 || echo md5 )"

log "INFO" "Starting backup of $SOURCE_DIR -> $FINAL_ARCHIVE"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN: Would create archive: $FINAL_ARCHIVE"
  echo "DRY RUN: Would apply excludes: ${EXCLUDE_ARGS[*]}"
  echo "DRY RUN: Would compute checksum ($CHECKSUM_ALGO) -> ${CHECKSUM_FILE##*/}"
  cleanup
  exit 0
fi

tar -czf "$TMP_ARCHIVE" "${EXCLUDE_ARGS[@]}" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>>"$LOG_FILE" \
  && mv -f "$TMP_ARCHIVE" "$FINAL_ARCHIVE" \
  || die "Failed to create archive"

log "SUCCESS" "Backup created: ${FINAL_ARCHIVE##*/}"

if [ "$CHECKSUM_ALGO" = "sha256" ]; then
  sha256sum "$FINAL_ARCHIVE" > "$CHECKSUM_FILE" || die "Failed to compute checksum"
else
  md5sum "$FINAL_ARCHIVE" > "$CHECKSUM_FILE" || die "Failed to compute checksum"
fi
log "INFO" "Checksum written: ${CHECKSUM_FILE##*/}"

log "INFO" "Backup completed successfully for $SOURCE_DIR"
exit 0

