# Prompt Builder - Development & Deployment Tools

This set of tools allows you to easily develop and deploy `prompt-builder.html` to GitHub.

## 📁 Files

- `prompt-builder.html` - main prompt builder file (located in `../tools/`)
- `file-sync.sh` - script for automatic file synchronization
- `deploy.sh` - script for deployment to GitHub
- `server.py` - HTTP server for web interface
- `start.sh` - script to start the entire development environment

## 🚀 Quick Start

### Option 1: Automatic startup (recommended)

```bash
cd /Users/aleksandrkosenko/xksnk_site_github/axksnk/deploy_sh
chmod +x start.sh
./start.sh
```

This automatically:
- Starts the HTTP server
- Makes all scripts executable

### Option 2: Manual startup

```bash
cd /Users/aleksandrkosenko/xksnk_site_github/axksnk/deploy_sh

# Make scripts executable
chmod +x *.sh
chmod +x server.py

# Start the server
python3 server.py
```

## 🔧 Usage

### 1. Command Line Interface

#### File Synchronization

```bash
# One-time synchronization
./file-sync.sh sync

# Monitor for changes (automatic synchronization)
./file-sync.sh monitor

# Create backup
./file-sync.sh backup
```

#### GitHub Deployment

```bash
# Full deployment
./deploy.sh deploy

# File synchronization only
./deploy.sh sync

# Check status
./deploy.sh status
```

## 📂 Path Structure

- **Source:** `/Users/aleksandrkosenko/xksnk_site_github/axksnk/tools/prompt-builder.html`
- **Target:** `/Users/aleksandrkosenko/xksnk_site_github/xksnk/tools/prompt-builder.html`
- **Backups:** `/Users/aleksandrkosenko/xksnk_site_github/axksnk/deploy_sh/backups/`

## 🔄 Workflow

1. **Development:** Edit `prompt-builder.html` in the `axksnk/tools/` folder
2. **Testing:** Open `http://localhost:8000/prompt-builder.html` for testing
3. **Deployment:** Run `./deploy.sh deploy` for full deployment
4. **Automation:** The script automatically:
   - Copies the file to the target folder
   - Creates a git commit
   - Pushes changes to GitHub

## 🛠 Change Monitoring

For automatic synchronization on every file change:

```bash
./file-sync.sh monitor
```

This mode will track changes and automatically copy the file on each save.

## 📋 Requirements

- Python 3.x
- Git (for deployment)
- Bash (for scripts)

## 🔧 Troubleshooting

### Problem: "Permission denied"
```bash
chmod +x *.sh
chmod +x server.py
```

### Problem: "Python not found"
Install Python 3:
```bash
# macOS (with Homebrew)
brew install python3

# Ubuntu/Debian
sudo apt-get install python3
```

### Problem: "Git repository not found"
Make sure the folder `/Users/aleksandrkosenko/xksnk_site_github/xksnk/` is a git repository.

### Problem: "Port 8000 already in use"
Change the port in `server.py` or stop the process using port 8000.

## 💡 Tips

1. **Quick deployment:** Use `./deploy.sh deploy` for quick deployment
2. **Automation:** Start monitoring for automatic synchronization
3. **Backups:** Scripts automatically create backups before changes
4. **Safety:** All operations are performed with error checking and logging

## 📞 Support

If you encounter problems, check:
1. File permissions
2. All dependencies are installed
3. Correct paths in scripts
4. Console logs for errors 