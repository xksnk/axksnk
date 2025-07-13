#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Prompt Builder Development Environment${NC}"
echo

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Python3 not found. Please install Python 3.${NC}"
    exit 1
fi

# Make scripts executable
chmod +x file-sync.sh
chmod +x deploy.sh
chmod +x server.py

echo -e "${BLUE}📁 Making scripts executable...${NC}"

# Start the server in background
echo -e "${BLUE}🌐 Starting HTTP server...${NC}"
python3 server.py &
SERVER_PID=$!

# Wait a moment for server to start
sleep 2

# Open browser
echo -e "${BLUE}🌍 Opening browser...${NC}"
open "http://localhost:8000/deploy-button.html" 2>/dev/null || \
    xdg-open "http://localhost:8000/deploy-button.html" 2>/dev/null || \
    echo -e "${YELLOW}Please open manually: http://localhost:8000/deploy-button.html${NC}"

echo
echo -e "${GREEN}✅ Development environment started!${NC}"
echo -e "${BLUE}📁 Deploy button: http://localhost:8000/deploy-button.html${NC}"
echo -e "${BLUE}🔧 Prompt builder: http://localhost:8000/prompt-builder.html${NC}"
echo -e "${YELLOW}⏹️  Press Ctrl+C to stop the server${NC}"
echo

# Wait for user to stop
trap "echo -e '\n${YELLOW}⏹️  Stopping server...${NC}'; kill $SERVER_PID 2>/dev/null; exit" INT
wait $SERVER_PID 