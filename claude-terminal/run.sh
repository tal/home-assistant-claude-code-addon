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
    apk add --no-cache ttyd jq curl
}

# Setup credential management scripts
setup_credential_scripts() {
    # Copy modular scripts to system locations
    if [ -d "/config/scripts" ]; then
        cp /config/scripts/credentials-manager.sh /usr/local/bin/credentials-manager
        cp /config/scripts/credentials-service.sh /usr/local/bin/credentials-service  
        cp /config/scripts/claude-auth.sh /usr/local/bin/claude-auth
    else
        # Fallback to embedded scripts for backward compatibility
        bashio::log.warning "Script modules not found, using embedded versions"
        # Keep existing embedded script creation here as fallback
    fi
    
    # Make scripts executable
    chmod +x /usr/local/bin/credentials-manager
    chmod +x /usr/local/bin/credentials-service
    chmod +x /usr/local/bin/claude-auth

    # Create convenience aliases
    ln -sf /usr/local/bin/credentials-manager /usr/local/bin/claude-logout
    ln -sf /usr/local/bin/claude-auth /usr/local/bin/debug-claude-auth
}

# Start credential monitoring service
start_credential_service() {
    bashio::log.info "Starting credential monitoring service..."
    /usr/local/bin/credentials-service &
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