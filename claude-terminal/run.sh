#!/usr/bin/with-contenv bashio

# Ensure claude-config directory exists with proper permissions
mkdir -p /config/claude-config
chmod 777 /config/claude-config

# Create links between credential locations and our persistent directory
mkdir -p /root/.config
ln -sf /config/claude-config /root/.config/anthropic

# Link the new found credential files to our persistent directory
if [ -f "/config/claude-config/.claude" ]; then
  ln -sf /config/claude-config/.claude /root/.claude
fi
if [ -f "/config/claude-config/.claude.json" ]; then
  ln -sf /config/claude-config/.claude.json /root/.claude.json
fi

# Set environment variables
export CLAUDE_CREDENTIALS_DIRECTORY="/config/claude-config"
export ANTHROPIC_CONFIG_DIR="/config/claude-config"
export HOME="/root"

# Create credential manager script
cat > /usr/local/bin/credentials-manager << 'EOF'
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
      cp -f "$location" "/config/claude-config/$(basename $location)"
      chmod 600 "/config/claude-config/$(basename $location)"
    fi
  done
  
  # Search for other potential credential files
  for file in $(find /root /tmp -type f -name "*claude*" -o -name "*auth*" -o -name "*token*" 2>/dev/null | grep -v "node_modules\|/proc\|/sys\|/dev"); do
    if [ -f "$file" ] && is_valid_credential "$file"; then
      cp -f "$file" "/config/claude-config/$(basename $file)"
      chmod 600 "/config/claude-config/$(basename $file)"
    fi
  done
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
EOF
chmod +x /usr/local/bin/credentials-manager

# Create a service that checks for new credentials
cat > /usr/local/bin/credentials-service << 'EOF'
#!/bin/bash

# Wait for initial startup
sleep 5

# Run forever, checking for credentials
while true; do
  /usr/local/bin/credentials-manager save > /dev/null 2>&1
  sleep 30
done
EOF
chmod +x /usr/local/bin/credentials-service

# Start credential service in background
/usr/local/bin/credentials-service &

# Create convenience aliases
ln -sf /usr/local/bin/credentials-manager /usr/local/bin/claude-logout

# Install ttyd and other useful tools
sleep 2
apk add --no-cache ttyd jq curl

# Log environment and directory information for debugging
bashio::log.info "Environment variables:"
bashio::log.info "CLAUDE_CREDENTIALS_DIRECTORY=${CLAUDE_CREDENTIALS_DIRECTORY}"
bashio::log.info "ANTHROPIC_CONFIG_DIR=${ANTHROPIC_CONFIG_DIR}"
bashio::log.info "HOME=${HOME}"

# Create an enhanced diagnostic and auth management script
cat > /usr/local/bin/claude-auth << 'EOF'
#!/bin/bash

function show_help {
  echo "Claude Auth Tool - Manage Claude authentication"
  echo ""
  echo "Usage:"
  echo "  claude-auth debug     - Show debugging information"
  echo "  claude-auth find      - Search for credential files"
  echo "  claude-auth save      - Save credentials to persistent storage"
  echo "  claude-auth logout    - Clear credentials and force re-authentication"
  echo "  claude-auth help      - Show this help message"
}

function find_credentials {
  echo "Searching for credential files..."
  echo ""
  echo "Looking in common locations:"
  find / -name "auth.json" -o -name "*claude*" -o -name "*anthropic*" 2>/dev/null | grep -v "node_modules\|npm" | sort
}

function debug_info {
  echo "===== CLAUDE AUTH DEBUG ====="
  echo "Directory contents of /config/claude-config:"
  ls -la /config/claude-config/
  echo ""
  echo "Default config directory contents:"
  ls -la /root/.config/anthropic/ 2>/dev/null || echo "Directory does not exist"
  echo ""
  echo "Home directory contents:"
  ls -la $HOME/.config/ 2>/dev/null || echo "Directory does not exist"
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

function save_credentials {
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
  
  # Also search for any other potential credential files
  CRED_FILES=$(find / -name "auth.json" -o -name "*claude*" -o -name "*anthropic*" 2>/dev/null | grep -v "node_modules\|npm\|/config/claude-config" | grep -v "bin/claude\|bin/claude-auth")
  if [ -z "$CRED_FILES" ]; then
    echo "No additional credential files found."
  else
    echo "Found additional potential credential files:"
    for file in $CRED_FILES; do
      # Exclude directories and executables
      if [ -f "$file" ] && [ ! -x "$file" ]; then
        DEST="/config/claude-config/$(basename $file)"
        echo "Copying $file to $DEST"
        cp -v "$file" "$DEST"
      fi
    done
  fi
  
  echo "Setting permissions on credential files..."
  chmod -R 755 /config/claude-config/
  
  echo "Done saving credentials."
}

function logout {
  echo "Clearing credentials and symlinks..."
  rm -rf /config/claude-config/* /root/.config/anthropic/
  find / -name "auth.json" -o -name "*claude*" -o -name "*anthropic*" 2>/dev/null | grep -v "node_modules\|npm\|claude-terminal" | xargs rm -f 2>/dev/null
  echo "All credentials cleared. Please restart the add-on to re-authenticate."
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
EOF
chmod +x /usr/local/bin/claude-auth

# Create helpful wrapper script
ln -sf /usr/local/bin/claude-auth /usr/local/bin/debug-claude-auth

# Create a simple web-based terminal that directly runs Claude
PORT=7681
bashio::log.info "Starting web terminal on port ${PORT}..."

# Run ttyd directly - no s6 overlay
exec ttyd \
  --port ${PORT} \
  --interface 0.0.0.0 \
  --writable \
  bash -c "clear && echo 'Welcome to Claude Terminal!' && echo '' && echo 'To log out: run claude-logout' && echo '' && echo 'Starting Claude...' && sleep 1 && node $(which claude) && /usr/local/bin/credentials-manager save"