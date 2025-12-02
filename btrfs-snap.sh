#!/bin/bash

# ==============================================================================
# btrfs-snap.sh
# Create btrfs subvolumes snapshot. source_subvol SHOULD be formatted like `<string>-subvol`.
# Usage: ./btrfs-snap.sh <source_subvol> <snapshot_dir>
# Examples: ./btrfs-snap.sh /mnt/homelab/template/iso-subvol /mnt/homelab/snapshots-subvol
# ==============================================================================
# Settings
MAX_SNAPSHOTS_COUNT=5
# ==============================================================================

set -euo pipefail

SOURCE_SUBVOL="$1"
SNAPSHOT_DIR="$2"

if [[ ! -d "$SOURCE_SUBVOL" ]]; then
    logger -t "btrfs-snap" -p err "Source subvolume not found: $SOURCE_SUBVOL"
    exit 1
fi

if [[ ! -d "$SNAPSHOT_DIR" ]]; then
    logger -t "btrfs-snap" -p err "Snapshot dir not found: $SNAPSHOT_DIR"
    exit 1
fi

if ! btrfs subvolume show "$SOURCE_SUBVOL" >/dev/null 2>&1; then
    logger -t "btrfs-snap" -p err "Not a Btrfs subvolume: $SOURCE_SUBVOL"
    exit 1
fi


SUBVOL_NAME=$(basename "$SOURCE_SUBVOL" | sed 's/-subvol$//')
SNAP_NAME="$SUBVOL_NAME.snap.$(date +%Y%m%d-%H%M%S)"
SNAP_PATH="$SNAPSHOT_DIR/$SNAP_NAME"

echo "Creating snapshot: $SNAP_NAME from $SOURCE_SUBVOL" | logger -t "btrfs-snap" -p info 

if btrfs subvolume snapshot -r "$SOURCE_SUBVOL" "$SNAP_PATH" 2>&1 | logger -t "btrfs-snap" -p info; then
    logger -t "btrfs-snap" -p info "Snapshot created successfully: $SNAP_NAME"
else
    logger -t "btrfs-snap" -p err "Failed to create snapshot: $SNAP_NAME"
    exit 1
fi

logger -t "btrfs-snap" -p info "Remove old snapshots (MAX_SNAPSHOTS_COUNT=$MAX_SNAPSHOTS_COUNT)"


ls -1t "$SNAPSHOT_DIR"/"$SUBVOL_NAME".snap.* 2>/dev/null | tail -n +$((MAX_SNAPSHOTS_COUNT + 1)) | while read old_snap; do
    SNAP_BASE=$(basename "$old_snap")

    if btrfs subvolume show "$old_snap" >/dev/null 2>&1; then
        if btrfs subvolume delete "$old_snap" 2>&1 | logger -t "btrfs-snap" -p info; then
            logger -t "btrfs-snap" -p info "Deleted old snapshot: $SNAP_BASE"
        else
            logger -t "btrfs-snap" -p err "Failed to delete snapshot: $SNAP_BASE"
        fi
    else
        logger -t "btrfs-snap" -p warn "Skipping non-subvolume: $old_snap"
    fi
done

logger -t "btrfs-snap" -p info "Snapshot process completed for ($SOURCE_SUBVOL -> $SNAPSHOT_DIR $SUBVOL_NAME)"
