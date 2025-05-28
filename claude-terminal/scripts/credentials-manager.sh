#!/bin/bash

# Ensure credential directory exists
mkdir -p /config/claude-config

# Function to check if a file looks like valid credential data
is_valid_credential() {
    local file=$1
    
    # Check if it's a non-empty file
    if [ ! -s "$file" ]; then
        return 1
    fi
    
    # Check if the file contains credential data
    if grep -q "token\|key\|auth\|cred" "$file" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to find and save credentials
save_credentials() {
    # Look in known credential locations
    for location in "/root/.claude" "/root/.claude.json" "/root/.config/anthropic/credentials.json"; do
        if [ -f "$location" ]; then
            cp -f "$location" "/config/claude-config/$(basename "$location")"
            chmod 600 "/config/claude-config/$(basename "$location")"
        fi
    done
    
    # Search for other potential credential files
    while IFS= read -r -d '' file; do
        if [ -f "$file" ] && is_valid_credential "$file"; then
            cp -f "$file" "/config/claude-config/$(basename "$file")"
            chmod 600 "/config/claude-config/$(basename "$file")"
        fi
    done < <(find /root /tmp -type f \( -name "*claude*" -o -name "*auth*" -o -name "*token*" \) -print0 2>/dev/null | grep -zv "node_modules\|/proc\|/sys\|/dev")
}

# Function to clear credentials
logout() {
    echo "Clearing all credentials..."
    rm -rf /config/claude-config/.claude* /root/.claude*
    rm -rf /root/.config/anthropic /config/claude-config/credentials.json
    echo "Credentials cleared. Please restart to re-authenticate."
}

# Process commands
case "$1" in
    save)
        save_credentials
        echo "Credentials saved to persistent storage"
        ;;
    logout)
        logout
        ;;
    *)
        # Default behavior: save credentials
        save_credentials
        ;;
esac