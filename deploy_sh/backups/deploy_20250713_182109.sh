#!/bin/bash

# Configuration
SITE_DIR="/Users/aleksandrkosenko/xksnk_site_github/xksnk"
TOOLS_DIR="$SITE_DIR/tools"
SOURCE_DIR="/Users/aleksandrkosenko/xksnk_site_github/axksnk/Tools"

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

# Function to check if we're in the right directory
check_directory() {
    if [ ! -d "$SITE_DIR" ]; then
        log "${RED}Site directory not found:${NC} $SITE_DIR"
        return 1
    fi
    
    if [ ! -d "$SITE_DIR/.git" ]; then
        log "${RED}Not a git repository:${NC} $SITE_DIR"
        return 1
    fi
    
    return 0
}

# Function to sync all files
sync_files() {
    if [ ! -d "$SOURCE_DIR" ]; then
        log "${RED}Source directory not found:${NC} $SOURCE_DIR"
        return 1
    fi
    
    # Create tools directory if it doesn't exist
    mkdir -p "$TOOLS_DIR"
    
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
        
        local target_file="$TOOLS_DIR/$filename"
        log "Syncing: $filename"
        
        # Copy file with preserved timestamps
        if cp -p "$file" "$target_file"; then
            log "${GREEN}Synced:${NC} $filename"
            ((synced_count++))
        else
            log "${RED}Failed to sync:${NC} $filename"
            ((failed_count++))
        fi
    done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -print0)
    
    if [ $synced_count -gt 0 ]; then
        log "${GREEN}Files synced successfully!${NC}"
        log "Successfully synced: $synced_count files"
        if [ $failed_count -gt 0 ]; then
            log "${RED}Failed to sync: $failed_count files${NC}"
        fi
        return 0
    else
        log "${RED}No files were synced${NC}"
        return 1
    fi
}

# Function to check if there are changes to commit
check_changes() {
    cd "$SITE_DIR"
    
    # Check if there are any changes
    if git diff --quiet && git diff --cached --quiet; then
        log "${YELLOW}No changes to commit${NC}"
        return 1
    else
        log "${GREEN}Changes detected, ready to commit${NC}"
        return 0
    fi
}

# Function to deploy to GitHub
deploy() {
    log "${GREEN}Starting deployment...${NC}"
    
    # Check directory
    if ! check_directory; then
        return 1
    fi
    
    # Change to site directory
    cd "$SITE_DIR"
    
    # Sync files first
    if ! sync_files; then
        log "${YELLOW}No files to sync or sync failed${NC}"
        # Continue anyway to check for other changes
    fi
    
    # Check if there are changes
    if ! check_changes; then
        log "${YELLOW}No changes detected after sync${NC}"
        return 0
    fi
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    log "Current branch: $current_branch"
    
    # Add all changes
    log "Adding changes..."
    git add .
    
    # Create commit message with timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local commit_message="Update tools files - $timestamp"
    
    # Commit changes
    log "Committing changes..."
    if git commit -m "$commit_message"; then
        log "${GREEN}Changes committed successfully!${NC}"
    else
        log "${RED}Failed to commit changes${NC}"
        return 1
    fi
    
    # Push to GitHub
    log "Pushing to GitHub..."
    if git push origin "$current_branch"; then
        log "${GREEN}Successfully deployed to GitHub!${NC}"
        log "Branch: $current_branch"
        log "Commit: $commit_message"
        return 0
    else
        log "${RED}Failed to push to GitHub${NC}"
        return 1
    fi
}

# Function to show status
show_status() {
    log "${GREEN}Checking deployment status...${NC}"
    
    if ! check_directory; then
        return 1
    fi
    
    cd "$SITE_DIR"
    
    # Show current branch
    local current_branch=$(git branch --show-current)
    log "Current branch: $current_branch"
    
    # Show last commit
    local last_commit=$(git log -1 --oneline 2>/dev/null)
    if [ -n "$last_commit" ]; then
        log "Last commit: $last_commit"
    else
        log "${YELLOW}No commits yet${NC}"
    fi
    
    # Show status
    log "Git status:"
    git status --short
    
    # Check if there are changes
    if check_changes; then
        log "${GREEN}Ready to deploy!${NC}"
    else
        log "${YELLOW}No changes to deploy${NC}"
    fi
}

# Function to show help
show_help() {
    echo "GitHub Deploy Script for Tools Directory"
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  deploy   - Deploy changes to GitHub (default)"
    echo "  sync     - Sync files only (no git operations)"
    echo "  status   - Show current status"
    echo "  help     - Show this help"
    echo
    echo "Excluded files:"
    printf "  %s\n" "${EXCLUDE_FILES[@]}"
    echo
    echo "Examples:"
    echo "  $0 deploy  # Deploy to GitHub"
    echo "  $0 sync    # Sync files only"
    echo "  $0 status  # Show status"
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "sync")
        log "Syncing files only..."
        sync_files
        ;;
    "status")
        show_status
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