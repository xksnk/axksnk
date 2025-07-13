#!/bin/bash

# Configuration
AXKSNK_DIR="/Users/aleksandrkosenko/xksnk_site_github/axksnk"
XKSNK_DIR="/Users/aleksandrkosenko/xksnk_site_github/xksnk"

# Source and target directories for sync
STYLES_SOURCE="$AXKSNK_DIR/styles"
STYLES_TARGET="$XKSNK_DIR/styles"
TOOLS_SOURCE="$AXKSNK_DIR/tools"
TOOLS_TARGET="$XKSNK_DIR/tools"

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

# Function to check if directory exists and is a git repo
check_git_repo() {
    local dir="$1"
    local name="$2"
    
    if [ ! -d "$dir" ]; then
        log "${RED}Directory not found:${NC} $dir"
        return 1
    fi
    
    if [ ! -d "$dir/.git" ]; then
        log "${RED}Not a git repository:${NC} $dir"
        return 1
    fi
    
    log "${GREEN}✓${NC} $name repository found"
    return 0
}

# Function to check for changes in directory
check_directory_changes() {
    local source_dir="$1"
    local target_dir="$2"
    local dir_name="$3"
    
    if [ ! -d "$source_dir" ]; then
        log "${YELLOW}Source directory not found:${NC} $source_dir"
        return 1
    fi
    
    if [ ! -d "$target_dir" ]; then
        log "${YELLOW}Target directory doesn't exist, will create:${NC} $target_dir"
        return 0
    fi
    
    # Compare directories using rsync dry-run
    local changes=$(rsync -avn --delete "$source_dir/" "$target_dir/" 2>/dev/null | grep -E '^[^d]' | wc -l)
    
    if [ "$changes" -gt 0 ]; then
        log "${GREEN}Changes detected in${NC} $dir_name"
        return 0
    else
        log "${YELLOW}No changes in${NC} $dir_name"
        return 1
    fi
}

# Function to sync directory
sync_directory() {
    local source_dir="$1"
    local target_dir="$2"
    local dir_name="$3"
    
    if [ ! -d "$source_dir" ]; then
        log "${RED}Source directory not found:${NC} $source_dir"
        return 1
    fi
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Sync using rsync
    log "Syncing $dir_name..."
    if rsync -av --delete "$source_dir/" "$target_dir/"; then
        log "${GREEN}✓${NC} $dir_name synced successfully"
        return 0
    else
        log "${RED}✗${NC} Failed to sync $dir_name"
        return 1
    fi
}

# Function to check git status and commit changes
commit_and_push() {
    local repo_dir="$1"
    local repo_name="$2"
    
    cd "$repo_dir"
    
    # Check if there are changes
    if git diff --quiet && git diff --cached --quiet; then
        log "${YELLOW}No changes to commit in${NC} $repo_name"
        return 0
    fi
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    log "Current branch in $repo_name: $current_branch"
    
    # Add all changes
    log "Adding changes in $repo_name..."
    git add .
    
    # Create commit message with timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local commit_message="Auto-sync from axksnk - $timestamp"
    
    # Commit changes
    log "Committing changes in $repo_name..."
    if git commit -m "$commit_message"; then
        log "${GREEN}✓${NC} Changes committed in $repo_name"
    else
        log "${RED}✗${NC} Failed to commit in $repo_name"
        return 1
    fi
    
    # Push to GitHub
    log "Pushing to GitHub from $repo_name..."
    if git push origin "$current_branch"; then
        log "${GREEN}✓${NC} Successfully pushed $repo_name to GitHub"
        return 0
    else
        log "${RED}✗${NC} Failed to push $repo_name to GitHub"
        return 1
    fi
}

# Function to perform full deployment
deploy() {
    log "${GREEN}🚀 Starting deployment process...${NC}"
    
    # Check both repositories
    if ! check_git_repo "$AXKSNK_DIR" "axksnk"; then
        return 1
    fi
    
    if ! check_git_repo "$XKSNK_DIR" "xksnk"; then
        return 1
    fi
    
    local has_changes=false
    
    # Check for changes in styles directory
    if check_directory_changes "$STYLES_SOURCE" "$STYLES_TARGET" "styles"; then
        if sync_directory "$STYLES_SOURCE" "$STYLES_TARGET" "styles"; then
            has_changes=true
        else
            log "${RED}Failed to sync styles directory${NC}"
            return 1
        fi
    fi
    
    # Check for changes in tools directory
    if check_directory_changes "$TOOLS_SOURCE" "$TOOLS_TARGET" "tools"; then
        if sync_directory "$TOOLS_SOURCE" "$TOOLS_TARGET" "tools"; then
            has_changes=true
        else
            log "${RED}Failed to sync tools directory${NC}"
            return 1
        fi
    fi
    
    if [ "$has_changes" = false ]; then
        log "${YELLOW}No changes detected, nothing to deploy${NC}"
        return 0
    fi
    
    # Commit and push changes to xksnk repository
    log "${GREEN}📝 Committing changes to xksnk repository...${NC}"
    if ! commit_and_push "$XKSNK_DIR" "xksnk"; then
        log "${RED}Failed to commit/push xksnk repository${NC}"
        return 1
    fi
    
    # Commit and push changes to axksnk repository (if there are any local changes)
    log "${GREEN}📝 Committing changes to axksnk repository...${NC}"
    if ! commit_and_push "$AXKSNK_DIR" "axksnk"; then
        log "${YELLOW}No changes to commit in axksnk repository${NC}"
    fi
    
    log "${GREEN}✅ Deployment completed successfully!${NC}"
    return 0
}

# Function to sync only (no git operations)
sync_only() {
    log "${GREEN}📁 Starting sync process...${NC}"
    
    local has_changes=false
    
    # Check and sync styles directory
    if check_directory_changes "$STYLES_SOURCE" "$STYLES_TARGET" "styles"; then
        if sync_directory "$STYLES_SOURCE" "$STYLES_TARGET" "styles"; then
            has_changes=true
        else
            log "${RED}Failed to sync styles directory${NC}"
            return 1
        fi
    fi
    
    # Check and sync tools directory
    if check_directory_changes "$TOOLS_SOURCE" "$TOOLS_TARGET" "tools"; then
        if sync_directory "$TOOLS_SOURCE" "$TOOLS_TARGET" "tools"; then
            has_changes=true
        else
            log "${RED}Failed to sync tools directory${NC}"
            return 1
        fi
    fi
    
    if [ "$has_changes" = false ]; then
        log "${YELLOW}No changes detected, nothing to sync${NC}"
    else
        log "${GREEN}✅ Sync completed successfully!${NC}"
    fi
    
    return 0
}

# Function to show status
show_status() {
    log "${GREEN}📊 Checking deployment status...${NC}"
    
    # Check repositories
    check_git_repo "$AXKSNK_DIR" "axksnk"
    check_git_repo "$XKSNK_DIR" "xksnk"
    
    echo
    
    # Check for changes
    log "Checking for changes..."
    local total_changes=0
    
    if check_directory_changes "$STYLES_SOURCE" "$STYLES_TARGET" "styles"; then
        ((total_changes++))
    fi
    
    if check_directory_changes "$TOOLS_SOURCE" "$TOOLS_TARGET" "tools"; then
        ((total_changes++))
    fi
    
    echo
    
    if [ $total_changes -gt 0 ]; then
        log "${GREEN}Ready to deploy! Found changes in $total_changes directory(ies)${NC}"
    else
        log "${YELLOW}No changes detected${NC}"
    fi
    
    # Show git status for both repositories
    echo
    log "Git status for axksnk:"
    cd "$AXKSNK_DIR"
    git status --short
    
    echo
    log "Git status for xksnk:"
    cd "$XKSNK_DIR"
    git status --short
}

# Function to monitor for changes
monitor() {
    log "${GREEN}👀 Starting file monitoring...${NC}"
    log "Monitoring directories:"
    log "  Styles: $STYLES_SOURCE → $STYLES_TARGET"
    log "  Tools:  $TOOLS_SOURCE → $TOOLS_TARGET"
    log "Press Ctrl+C to stop"
    echo
    
    # Initial sync
    sync_only
    
    # Monitor for changes
    while true; do
        local has_changes=false
        
        if check_directory_changes "$STYLES_SOURCE" "$STYLES_TARGET" "styles" >/dev/null; then
            has_changes=true
        fi
        
        if check_directory_changes "$TOOLS_SOURCE" "$TOOLS_TARGET" "tools" >/dev/null; then
            has_changes=true
        fi
        
        if [ "$has_changes" = true ]; then
            log "${YELLOW}Changes detected! Starting sync...${NC}"
            sync_only
        fi
        
        sleep 5  # Check every 5 seconds
    done
}

# Function to show help
show_help() {
    echo "🚀 Deploy to xksnk - Unified Deployment Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  deploy   - Full deployment (sync + commit + push) (default)"
    echo "  sync     - Sync files only (no git operations)"
    echo "  status   - Show current status"
    echo "  monitor  - Monitor for changes and auto-sync"
    echo "  help     - Show this help"
    echo
    echo "Examples:"
    echo "  $0 deploy  # Full deployment"
    echo "  $0 sync    # Sync files only"
    echo "  $0 status  # Check status"
    echo "  $0 monitor # Monitor for changes"
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "sync")
        sync_only
        ;;
    "status")
        show_status
        ;;
    "monitor")
        monitor
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        log "${RED}Unknown command:${NC} $1"
        show_help
        exit 1
        ;;
esac 