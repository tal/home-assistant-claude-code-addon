ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install packages in a single layer to minimize image size
RUN apk add --no-cache \
    nodejs \
    npm \
    bash \
    curl \
    && npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

# Create directory for Claude configuration and set working directory
RUN mkdir -p /config/claude-config
WORKDIR /config

# Copy startup script and modular scripts
COPY run.sh /run.sh
COPY scripts/ /config/scripts/
RUN chmod +x /run.sh \
    && chmod +x /config/scripts/*.sh

# Use exec form for better signal handling
CMD ["/run.sh"]