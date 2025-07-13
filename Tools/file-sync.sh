#!/bin/bash

# Configuration
SOURCE_FILE="/Users/aleksandrkosenko/xksnk_site_github/axksnk/Tools/prompt-builder.html"
TARGET_DIR="/Users/aleksandrkosenko/xksnk_site_github/xksnk/tools"
TARGET_FILE="$TARGET_DIR/prompt-builder.html"
BACKUP_DIR="/Users/aleksandrkosenko/xksnk_site_github/axksnk/Tools/backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to log messages
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Function to create backup
create_backup() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/prompt-builder_${timestamp}.html"
    cp "$SOURCE_FILE" "$backup_file"
    log "${GREEN}Backup created:${NC} $backup_file"
}

# Function to sync file
sync_file() {
    if [ ! -f "$SOURCE_FILE" ]; then
        log "${RED}Source file not found:${NC} $SOURCE_FILE"
        return 1
    fi
    
    # Create target directory if it doesn't exist
    mkdir -p "$TARGET_DIR"
    
    # Create backup before copying
    create_backup
    
    # Copy file
    cp "$SOURCE_FILE" "$TARGET_FILE"
    
    if [ $? -eq 0 ]; then
        log "${GREEN}File synced successfully!${NC}"
        log "Source: $SOURCE_FILE"
        log "Target: $TARGET_FILE"
        return 0
    else
        log "${RED}Failed to sync file${NC}"
        return 1
    fi
}

# Function to check if file has changed
check_file_changes() {
    if [ ! -f "$SOURCE_FILE" ]; then
        log "${RED}Source file not found:${NC} $SOURCE_FILE"
        return 1
    fi
    
    if [ ! -f "$TARGET_FILE" ]; then
        log "${YELLOW}Target file doesn't exist, initial sync needed${NC}"
        return 0
    fi
    
    # Compare files using md5
    local source_md5=$(md5 -q "$SOURCE_FILE" 2>/dev/null || md5sum "$SOURCE_FILE" 2>/dev/null | cut -d' ' -f1)
    local target_md5=$(md5 -q "$TARGET_FILE" 2>/dev/null || md5sum "$TARGET_FILE" 2>/dev/null | cut -d' ' -f1)
    
    if [ "$source_md5" != "$target_md5" ]; then
        return 0  # Files are different
    else
        return 1  # Files are the same
    fi
}

# Function to monitor file changes
monitor_file() {
    log "${GREEN}Starting file monitor...${NC}"
    log "Monitoring: $SOURCE_FILE"
    log "Target: $TARGET_FILE"
    log "Press Ctrl+C to stop"
    echo
    
    # Initial sync
    if check_file_changes; then
        sync_file
    fi
    
    # Monitor for changes
    while true; do
        if check_file_changes; then
            log "${YELLOW}File changed detected!${NC}"
            sync_file
        fi
        sleep 2  # Check every 2 seconds
    done
}

# Function to show help
show_help() {
    echo "File Sync Script for prompt-builder.html"
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  sync     - Sync file once"
    echo "  monitor  - Monitor file for changes (default)"
    echo "  backup   - Create backup only"
    echo "  help     - Show this help"
    echo
    echo "Examples:"
    echo "  $0 sync     # Sync file once"
    echo "  $0 monitor  # Monitor for changes"
    echo "  $0 backup   # Create backup"
}

# Main script logic
case "${1:-monitor}" in
    "sync")
        log "Performing one-time sync..."
        sync_file
        ;;
    "monitor")
        monitor_file
        ;;
    "backup")
        log "Creating backup..."
        create_backup
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        log "${RED}Unknown option:${NC} $1"
        show_help
        exit 1
        ;;
esac 