#!/bin/bash

show_help() {
    echo "Claude Auth Tool - Manage Claude authentication"
    echo ""
    echo "Usage:"
    echo "  claude-auth debug     - Show debugging information"
    echo "  claude-auth find      - Search for credential files"
    echo "  claude-auth save      - Save credentials to persistent storage"
    echo "  claude-auth logout    - Clear credentials and force re-authentication"
    echo "  claude-auth help      - Show this help message"
}

find_credentials() {
    echo "Searching for credential files..."
    echo ""
    echo "Looking in common locations:"
    # Only search in safe user directories, not system-wide
    find /root /home /tmp /config -name "auth.json" -o -name "*claude*" -o -name "*anthropic*" 2>/dev/null | grep -v "node_modules\|npm\|bin/" | sort
}

debug_info() {
    echo "===== CLAUDE AUTH DEBUG ====="
    echo "Directory contents of /config/claude-config:"
    ls -la /config/claude-config/
    echo ""
    echo "Default config directory contents:"
    ls -la /root/.config/anthropic/ 2>/dev/null || echo "Directory does not exist"
    echo ""
    echo "Home directory contents:"
    ls -la "$HOME/.config/" 2>/dev/null || echo "Directory does not exist"
    echo ""
    echo "Environment variables:"
    echo "CLAUDE_CREDENTIALS_DIRECTORY=$CLAUDE_CREDENTIALS_DIRECTORY"
    echo "ANTHROPIC_CONFIG_DIR=$ANTHROPIC_CONFIG_DIR"
    echo "HOME=$HOME"
    echo ""
    echo "Node executable path:"
    which node
    echo ""
    echo "Claude executable path:"
    which claude
    echo ""
}

save_credentials() {
    echo "Attempting to save credentials to persistent storage..."
    
    # Save the specific Claude credential files we've identified
    if [ -f "/root/.claude" ]; then
        echo "Copying /root/.claude to /config/claude-config/.claude"
        cp -v "/root/.claude" "/config/claude-config/.claude"
    else
        echo "Claude credential file not found at /root/.claude"
    fi
    
    if [ -f "/root/.claude.json" ]; then
        echo "Copying /root/.claude.json to /config/claude-config/.claude.json"
        cp -v "/root/.claude.json" "/config/claude-config/.claude.json"
    else
        echo "Claude JSON credential file not found at /root/.claude.json"
    fi
    
    # Also search for any other potential credential files in safe directories only
    cred_files=$(find /root /home /tmp -maxdepth 3 -name "auth.json" -o -name "*claude*" -o -name "*anthropic*" 2>/dev/null | grep -v "node_modules\|npm\|/config/claude-config\|bin/" | head -20)
    if [ -z "$cred_files" ]; then
        echo "No additional credential files found."
    else
        echo "Found additional potential credential files:"
        for file in $cred_files; do
            # Exclude directories and executables
            if [ -f "$file" ] && [ ! -x "$file" ]; then
                dest="/config/claude-config/$(basename "$file")"
                echo "Copying $file to $dest"
                cp -v "$file" "$dest"
            fi
        done
    fi
    
    echo "Setting permissions on credential files..."
    chmod -R 600 /config/claude-config/
    
    echo "Done saving credentials."
}

logout() {
    echo "Clearing credentials and symlinks..."
    # Safely remove only credential files we created
    rm -rf /config/claude-config/.claude* /config/claude-config/auth.json /config/claude-config/credentials.json
    rm -rf /root/.config/anthropic/ /root/.claude* 
    # Remove any credential files in safe user directories only
    find /root /tmp -maxdepth 2 -name ".claude*" -o -name "auth.json" 2>/dev/null | grep -v "node_modules\|npm\|bin/" | xargs rm -f 2>/dev/null
    echo "Credentials cleared. Please restart the add-on to re-authenticate."
}

case "$1" in
    debug)
        debug_info
        ;;
    find)
        find_credentials
        ;;
    save)
        save_credentials
        ;;
    logout)
        logout
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        ;;
esac