#!/bin/bash

# ================================================
# Create preview image and embedded it to mp4 file.
# ./create_video_preview.sh <file_name>
#
# ================================================

START_TIME=$(date +%s)

INPUT="$1"
IMAGES_TO_PREVIEW=9
TMP_DIR=$(mktemp -d)
TMP_PREVIEW_FILE="$TMP_DIR/preview.png"
OUTPUT="${INPUT%.*}_preview.mp4"
# ================================================
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [ $# -ne 1 ]; then
    echo "[ERROR] Bad input: ./create_video_preview.sh <file_name>"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "[ERROR] File '$INPUT' not found!"
    exit 1
fi

if ! ffprobe -v error "$INPUT" 2>/dev/null; then
    echo "[ERROR] '$INPUT' is not a valid video file!"
    exit 1
fi

DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")

if [ -z "$DURATION" ] || [ "$(echo "$DURATION <= 0" | bc)" -eq 1 ]; then
    echo "[ERROR] Can't get video duration."
    exit 1
fi

echo "Generate preview (seeking)..."
echo "[DEBUG] $INPUT $OUTPUT $DURATION"

for i in $(seq 0 $((IMAGES_TO_PREVIEW - 1))); do
    TIMESTAMP=$(echo "$DURATION * ($i + 0.5) / $IMAGES_TO_PREVIEW" | bc -l)
    ffmpeg -ss "$TIMESTAMP" -i "$INPUT" -vframes 1 -q:v 2 "$TMP_DIR/frame_${i}.jpg" 2>/dev/null
done

TILE_COLS=3
TILE_ROWS=3
montage "${TMP_DIR}/frame_"*.jpg -tile ${TILE_COLS}x${TILE_ROWS} -geometry +2+2 "$TMP_PREVIEW_FILE" 2>/dev/null

if [ ! -f "$TMP_PREVIEW_FILE" ] || [ ! -s "$TMP_PREVIEW_FILE" ]; then
    echo "[ERROR] Can't create temp preview."
    exit 1
fi

echo "Embedded preview into file..."
ffmpeg -i "$INPUT" -i "$TMP_PREVIEW_FILE" -map 0 -map 1 -c copy -c:v:1 png -disposition:v:1 attached_pic "$OUTPUT" 2>/dev/null

if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
    echo "[INFO] Success!"
    echo "[INFO] (attached_pic)"
else
    echo "[ERROR] Something went wrong!"
    exit 1
fi

if command -v ffprobe &> /dev/null; then
    if ffprobe -v quiet -show_streams -select_streams v:1 "$OUTPUT" 2>/dev/null | grep -q "attached_pic=1"; then
        echo "Validated: true"
    fi
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "[INFO] Time elapsed: ${ELAPSED}s"
