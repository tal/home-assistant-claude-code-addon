# Claude Code Helper for Home Assistant Add-ons

## Build Commands
- Build add-on: `docker build -t local/claude-terminal ./claude-terminal`
- Run add-on locally: `docker run -p 7681:7681 -v $(pwd)/config:/config local/claude-terminal`
- Validate: `docker run --rm -v $(pwd):/data homeassistant/amd64-builder --validate`
- Lint Dockerfile: `hadolint ./claude-terminal/Dockerfile`

## Test Commands
- Basic functionality test: `curl -X GET http://localhost:7681/`
- Web terminal test: Open browser to `http://localhost:7681/` to verify web terminal loads

## Code Style Guidelines
- **Indentation**: 2 spaces for YAML, 4 spaces for shell scripts
- **Naming**: Use snake_case for variables, functions, and file names
- **Docker**: Include comments for complex RUN commands
- **Shell Scripts**: Use `#!/usr/bin/with-contenv bashio` for add-on scripts
- **Error Handling**: Use bashio::log.error for error reporting
- **YAML**: Keep configuration files well-documented with comments
- **Addon Structure**: Follow Home Assistant add-on specification with required files (config.yaml, Dockerfile, etc.)