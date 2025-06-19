#!/usr/bin/with-contenv bashio

# Initialize credentials and environment
init_environment() {
    # Ensure claude-config directory exists with proper permissions
    mkdir -p /config/claude-config
    chmod 777 /config/claude-config

    # Create links between credential locations and our persistent directory
    mkdir -p /root/.config
    ln -sf /config/claude-config /root/.config/anthropic

    # Link the found credential files to our persistent directory
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
}

# Install required tools
install_tools() {
    bashio::log.info "Installing additional tools..."
    if ! apk add --no-cache ttyd jq curl; then
        bashio::log.error "Failed to install required tools"
        exit 1
    fi
    bashio::log.info "Tools installed successfully"
}

# Setup credential management scripts
setup_credential_scripts() {
    # Copy modular scripts to system locations
    if [ -d "/config/scripts" ]; then
        if ! cp /config/scripts/credentials-manager.sh /usr/local/bin/credentials-manager; then
            bashio::log.error "Failed to copy credentials-manager script"
            exit 1
        fi
        if ! cp /config/scripts/credentials-service.sh /usr/local/bin/credentials-service; then
            bashio::log.error "Failed to copy credentials-service script"
            exit 1
        fi
        if ! cp /config/scripts/claude-auth.sh /usr/local/bin/claude-auth; then
            bashio::log.error "Failed to copy claude-auth script"
            exit 1
        fi
    else
        # Fallback to embedded scripts for backward compatibility
        bashio::log.warning "Script modules not found, using embedded versions"
        
        # Create embedded credentials-manager script
        cat > /usr/local/bin/credentials-manager << 'EOF'
#!/bin/bash
mkdir -p /config/claude-config
save_credentials() {
    for location in "/root/.claude" "/root/.claude.json" "/root/.config/anthropic/credentials.json"; do
        if [ -f "$location" ]; then
            cp -f "$location" "/config/claude-config/$(basename "$location")"
            chmod 600 "/config/claude-config/$(basename "$location")"
        fi
    done
}
logout() {
    echo "Clearing all credentials..."
    rm -rf /config/claude-config/.claude* /root/.claude*
    rm -rf /root/.config/anthropic /config/claude-config/credentials.json
    echo "Credentials cleared. Please restart to re-authenticate."
}
case "$1" in
    save) save_credentials ;;
    logout) logout ;;
    *) save_credentials ;;
esac
EOF

        # Create embedded credentials-service script
        cat > /usr/local/bin/credentials-service << 'EOF'
#!/bin/bash
sleep 5
while true; do
    /usr/local/bin/credentials-manager save > /dev/null 2>&1
    sleep 30
done
EOF

        # Create embedded claude-auth script
        cat > /usr/local/bin/claude-auth << 'EOF'
#!/bin/bash
show_help() {
    echo "Claude Auth Tool - Manage Claude authentication"
    echo "Usage: claude-auth [debug|save|logout|help]"
}
debug_info() {
    echo "===== CLAUDE AUTH DEBUG ====="
    echo "Directory contents of /config/claude-config:"
    ls -la /config/claude-config/ 2>/dev/null || echo "Directory does not exist"
    echo "Environment variables:"
    echo "CLAUDE_CREDENTIALS_DIRECTORY=$CLAUDE_CREDENTIALS_DIRECTORY"
    echo "ANTHROPIC_CONFIG_DIR=$ANTHROPIC_CONFIG_DIR"
    echo "HOME=$HOME"
}
save_credentials() {
    /usr/local/bin/credentials-manager save
}
logout() {
    /usr/local/bin/credentials-manager logout
}
case "$1" in
    debug) debug_info ;;
    save) save_credentials ;;
    logout) logout ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
EOF
    fi
    
    # Make scripts executable
    chmod +x /usr/local/bin/credentials-manager
    chmod +x /usr/local/bin/credentials-service
    chmod +x /usr/local/bin/claude-auth

    # Create convenience aliases
    ln -sf /usr/local/bin/credentials-manager /usr/local/bin/claude-logout
    ln -sf /usr/local/bin/claude-auth /usr/local/bin/debug-claude-auth
    
    bashio::log.info "Credential management scripts installed successfully"
}

# Start credential monitoring service
start_credential_service() {
    bashio::log.info "Starting credential monitoring service..."
    /usr/local/bin/credentials-service &
    # Give the service a moment to start before proceeding
    sleep 2
}

# Start main web terminal
start_web_terminal() {
    local port=7681
    bashio::log.info "Starting web terminal on port ${port}..."
    
    # Log environment information for debugging
    bashio::log.info "Environment variables:"
    bashio::log.info "CLAUDE_CREDENTIALS_DIRECTORY=${CLAUDE_CREDENTIALS_DIRECTORY}"
    bashio::log.info "ANTHROPIC_CONFIG_DIR=${ANTHROPIC_CONFIG_DIR}"
    bashio::log.info "HOME=${HOME}"

    # Run ttyd with improved configuration
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        bash -c "clear && echo 'Welcome to Claude Terminal!' && echo '' && echo 'To log out: run claude-logout' && echo '' && echo 'Starting Claude...' && sleep 1 && node \$(which claude) && /usr/local/bin/credentials-manager save"
}

# Main execution
main() {
    bashio::log.info "Initializing Claude Terminal add-on..."
    
    init_environment
    install_tools
    setup_credential_scripts
    start_credential_service
    start_web_terminal
}

# Execute main function
main "$@"