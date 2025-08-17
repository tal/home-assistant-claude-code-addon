ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install packages in a single layer to minimize image size
RUN apk add --no-cache \
    nodejs \
    npm \
    bash \
    curl \
    nano \
    pipx \
    && npm install -g @anthropic-ai/claude-code@latest \
    && pipx install homeassistant-cli \
    && pipx inject homeassistant-cli click==8.0.4 \
    && npm cache clean --force

# Ensure pipx binaries are in PATH
ENV PATH="/root/.local/bin:$PATH"

# Create directory for Claude configuration and set working directory
RUN mkdir -p /config/claude-config
WORKDIR /config

# Copy startup script and modular scripts
COPY run.sh /run.sh
COPY scripts/ /opt/scripts/
RUN chmod +x /run.sh \
    && chmod +x /opt/scripts/*.sh

# Use exec form for better signal handling
CMD ["/run.sh"]