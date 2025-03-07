ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install basic packages
RUN apk add --no-cache nodejs npm bash curl

# Create directory for Claude configuration and set working directory to /config
RUN mkdir -p /config/claude-config
WORKDIR /config

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code
RUN npm cache clean --force

# Create startup script
COPY run.sh /
RUN chmod a+x /run.sh

# Command to run
CMD ["/run.sh"]