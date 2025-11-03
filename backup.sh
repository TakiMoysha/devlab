#!/bin/bash

# ==============================================================================
# backup.sh
# Резервное копирование "сырых" файлов со сжатием и проверкой целостности
# Use: ./backup-iso-compressed.sh <input_iso_file> <output_dir>
# Example: ./backup-iso-compressed.sh /mnt/devlab/iso/ubuntu-22.04.iso /mnt/btrfs-backup/iso/
# ==============================================================================

set -euo pipefail  # Exit on error

INPUT_FILE="$1"
OUTPUT_DIR="$2"

# Tools
ZSTD="/usr/bin/zstd"
MD5SUM="/usr/bin/md5sum"

if [[ -z "$INPUT_FILE" ]] || [[ -z "$OUTPUT_DIR" ]]; then
    echo "Bad usage: $0 <input_iso_file> <output_dir>"
    echo "Example: $0 /mnt/devlab/iso/ubuntu-22.04.iso /mnt/btrfs-backup/iso/"
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "File not found: $INPUT_FILE"
    exit 1
fi

if ! command -v "$ZSTD" &> /dev/null; then
    echo "Compression tool not found: $ZSTD"
    exit 1
fi

if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Output directory not found: $OUTPUT_DIR"
    exit 1
fi

# ==============================================================================
# core
# ==============================================================================

BASENAME=$(basename "$INPUT_FILE")
COMPRESSED_NAME="${BASENAME}.zst"
LOG_FILE="/var/log/iso-backup.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: $BASENAME" >> "$LOG_FILE"

# space check
FREE_SPACE=$(df --output=avail -B1 "$OUTPUT_DIR" | tail -n1)
FILE_SIZE=$(stat -c%s "$INPUT_FILE")
if [[ $FREE_SPACE -lt $((FILE_SIZE * 2)) ]]; then
    echo "Warning: Not enough space. Need ~$((FILE_SIZE * 2 / 1024 / 1024)) MB, have $((FREE_SPACE / 1024 / 1024)) MB" >> "$LOG_FILE"
fi

# compressing
echo "Compression: $BASENAME → $COMPRESSED_NAME"
if $ZSTD -19 -q -c "$INPUT_FILE" > "$OUTPUT_DIR/$COMPRESSED_NAME"; then
    echo "Done: $COMPRESSED_NAME" >> "$LOG_FILE"
else
    echo "Error: $BASENAME" >> "$LOG_FILE"
    exit 1
fi

# md5 check
echo "Checking: $COMPRESSED_NAME"
if $ZSTD -t "$OUTPUT_DIR/$COMPRESSED_NAME"; then
    echo "All good: $COMPRESSED_NAME" >> "$LOG_FILE"
else
    echo "Error: $COMPRESSED_NAME" >> "$LOG_FILE"
    exit 1
fi

# Create MD5 hash of the original file
MD5_FILE="$OUTPUT_DIR/${BASENAME}.md5"
if $MD5SUM "$INPUT_FILE" > "$MD5_FILE"; then
    echo "Done: $MD5_FILE" >> "$LOG_FILE"
else
    echo "Error: $MD5_FILE" >> "$LOG_FILE"
    exit 1
fi

# Вывод статистики
ORIGINAL_SIZE=$(stat -c%s "$INPUT_FILE")
COMPRESSED_SIZE=$(stat -c%s "$OUTPUT_DIR/$COMPRESSED_NAME")
COMPRESSION_RATIO=$(awk "BEGIN {printf \"%.2f\", $COMPRESSED_SIZE / $ORIGINAL_SIZE * 100}")
COMPRESSION_SAVED=$(awk "BEGIN {printf \"%.1f\", ($ORIGINAL_SIZE - $COMPRESSED_SIZE) / 1024 / 1024}")

echo "\tLogs" >> "$LOG_FILE"
echo "\tSource:\$(awk "BEGIN {printf \"%.1f\", $ORIGINAL_SIZE / 1024 / 1024}") MB" >> "$LOG_FILE"
echo "\tCompression:\t$(awk "BEGIN {printf \"%.1f\", $COMPRESSED_SIZE / 1024 / 1024}") MB" >> "$LOG_FILE"
echo "\tCompression ratio:\t$COMPRESSION_RATIO% (- $COMPRESSION_SAVED MB)" >> "$LOG_FILE"

echo "Success: $BASENAME" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Time: $BASENAME"

# Final output
echo "Success: $BASENAME → $COMPRESSED_NAME"
echo "Size: $(awk "BEGIN {printf \"%.1f\", $ORIGINAL_SIZE / 1024 / 1024}") MB → $(awk "BEGIN {printf \"%.1f\", $COMPRESSED_SIZE / 1024 / 1024}") MB"
echo "Saved: $COMPRESSION_SAVED MB"
