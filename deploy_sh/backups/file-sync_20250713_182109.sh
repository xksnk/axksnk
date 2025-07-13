#!/bin/bash

# Configuration
SOURCE_DIR="/Users/aleksandrkosenko/xksnk_site_github/axksnk/Tools"
TARGET_DIR="/Users/aleksandrkosenko/xksnk_site_github/xksnk/tools"
BACKUP_DIR="/Users/aleksandrkosenko/xksnk_site_github/axksnk/Tools/backups"

# Files to exclude from sync (script-related files)
EXCLUDE_FILES=(
    "file-sync.sh"
    "deploy.sh"
    "start.sh"
    "server.py"
    "deploy-button.html"
    "README.md"
    "run"
    ".DS_Store"
)

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

# Function to check if file should be excluded
is_excluded() {
    local filename="$1"
    for exclude in "${EXCLUDE_FILES[@]}"; do
        if [[ "$filename" == "$exclude" ]]; then
            return 0  # File should be excluded
        fi
    done
    return 1  # File should be synced
}

# Function to create backup
create_backup() {
    local source_file="$1"
    local filename=$(basename "$source_file")
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/${filename%.*}_${timestamp}.${filename##*.}"
    cp "$source_file" "$backup_file"
    log "${GREEN}Backup created:${NC} $backup_file"
}

# Function to sync single file
sync_single_file() {
    local source_file="$1"
    local filename=$(basename "$source_file")
    local target_file="$TARGET_DIR/$filename"
    
    if [ ! -f "$source_file" ]; then
        log "${RED}Source file not found:${NC} $source_file"
        return 1
    fi
    
    # Create target directory if it doesn't exist
    mkdir -p "$TARGET_DIR"
    
    # Create backup before copying
    create_backup "$source_file"
    
    # Copy file with preserved timestamps
    cp -p "$source_file" "$target_file"
    
    if [ $? -eq 0 ]; then
        log "${GREEN}File synced successfully!${NC}"
        log "Source: $source_file"
        log "Target: $target_file"
        return 0
    else
        log "${RED}Failed to sync file${NC}"
        return 1
    fi
}

# Function to sync all files
sync_all_files() {
    log "${GREEN}Starting sync of all files...${NC}"
    
    local synced_count=0
    local failed_count=0
    
    # Find all files in source directory
    while IFS= read -r -d '' file; do
        local filename=$(basename "$file")
        
        # Skip excluded files
        if is_excluded "$filename"; then
            log "${YELLOW}Skipping excluded file:${NC} $filename"
            continue
        fi
        
        # Skip directories
        if [ -d "$file" ]; then
            log "${YELLOW}Skipping directory:${NC} $filename"
            continue
        fi
        
        log "Syncing: $filename"
        if sync_single_file "$file"; then
            ((synced_count++))
        else
            ((failed_count++))
        fi
    done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)
    
    log "${GREEN}Sync completed!${NC}"
    log "Successfully synced: $synced_count files"
    if [ $failed_count -gt 0 ]; then
        log "${RED}Failed to sync: $failed_count files${NC}"
    fi
}

# Function to check if file has changed
check_file_changes() {
    local source_file="$1"
    local filename=$(basename "$source_file")
    local target_file="$TARGET_DIR/$filename"
    
    if [ ! -f "$source_file" ]; then
        log "${RED}Source file not found:${NC} $source_file"
        return 1
    fi
    
    if [ ! -f "$target_file" ]; then
        log "${YELLOW}Target file doesn't exist, sync needed:${NC} $filename"
        return 0
    fi
    
    # Compare files using md5
    local source_md5=$(md5 -q "$source_file" 2>/dev/null || md5sum "$source_file" 2>/dev/null | cut -d' ' -f1)
    local target_md5=$(md5 -q "$target_file" 2>/dev/null || md5sum "$target_file" 2>/dev/null | cut -d' ' -f1)
    
    if [ "$source_md5" != "$target_md5" ]; then
        return 0  # Files are different
    else
        return 1  # Files are the same
    fi
}

# Function to monitor all files for changes
monitor_files() {
    log "${GREEN}Starting file monitor...${NC}"
    log "Monitoring directory: $SOURCE_DIR"
    log "Target directory: $TARGET_DIR"
    log "Excluded files: ${EXCLUDE_FILES[*]}"
    log "Press Ctrl+C to stop"
    echo
    
    # Initial sync
    sync_all_files
    
    # Monitor for changes
    while true; do
        local changed_files=()
        
        # Check all files for changes
        while IFS= read -r -d '' file; do
            local filename=$(basename "$file")
            
            # Skip excluded files
            if is_excluded "$filename"; then
                continue
            fi
            
            # Skip directories
            if [ -d "$file" ]; then
                continue
            fi
            
            # Check if file has changed
            if check_file_changes "$file"; then
                changed_files+=("$file")
            fi
        done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)
        
        # Sync changed files
        if [ ${#changed_files[@]} -gt 0 ]; then
            log "${YELLOW}Changes detected in ${#changed_files[@]} file(s)!${NC}"
            for file in "${changed_files[@]}"; do
                local filename=$(basename "$file")
                log "Syncing changed file: $filename"
                sync_single_file "$file"
            done
        fi
        
        sleep 2  # Check every 2 seconds
    done
}

# Function to show help
show_help() {
    echo "File Sync Script for Tools Directory"
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  sync     - Sync all files once"
    echo "  monitor  - Monitor all files for changes (default)"
    echo "  backup   - Create backup of all files"
    echo "  help     - Show this help"
    echo
    echo "Excluded files:"
    printf "  %s\n" "${EXCLUDE_FILES[@]}"
    echo
    echo "Examples:"
    echo "  $0 sync     # Sync all files once"
    echo "  $0 monitor  # Monitor for changes"
    echo "  $0 backup   # Create backup"
}

# Main script logic
case "${1:-monitor}" in
    "sync")
        log "Performing one-time sync of all files..."
        sync_all_files
        ;;
    "monitor")
        monitor_files
        ;;
    "backup")
        log "Creating backup of all files..."
        while IFS= read -r -d '' file; do
            local filename=$(basename "$file")
            if ! is_excluded "$filename" && [ -f "$file" ]; then
                create_backup "$file"
            fi
        done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)
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