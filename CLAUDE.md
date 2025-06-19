# Claude Code Helper for Home Assistant Add-ons

## Development Environment Setup (NixOS)

### Quick Start
```bash
# Enter the development shell
nix develop

# Or with direnv (if installed)
direnv allow
```

### Docker Service Setup
The Docker daemon must be running for container operations:

```bash
# Start Docker service (one-time)
sudo systemctl start docker

# Or enable automatic startup by adding to your NixOS config:
# virtualisation.docker.enable = true;
```

## Development Commands

### Build & Run
- `build-addon` - Build the Claude Terminal add-on
- `run-addon` - Run add-on locally on port 7681
- `lint-dockerfile` - Lint Dockerfile with hadolint
- `test-endpoint` - Test web endpoint availability

### Manual Commands (if not using aliases)
- Build: `docker build -t local/claude-terminal ./claude-terminal`
- Run: `docker run -p 7681:7681 -v $(pwd)/config:/config local/claude-terminal`
- Lint: `hadolint ./claude-terminal/Dockerfile`
- Test: `curl -X GET http://localhost:7681/`

### Without Development Shell
```bash
# Build with nix-shell
nix-shell --packages docker hadolint --run "docker build -t local/claude-terminal ./claude-terminal"

# Lint with nix-shell
nix-shell --packages hadolint --run "hadolint ./claude-terminal/Dockerfile"
```

## Testing
- **Web Interface**: Open `http://localhost:7681/` to verify terminal loads
- **Functionality**: Test Claude authentication and command execution
- **Container Health**: Check logs with `docker logs <container-id>`

## Notes
- Add-on targets Home Assistant OS (Alpine Linux base) for deployment
- Development environment provides NixOS compatibility
- Full HA validation requires Home Assistant OS environment

## Code Style Guidelines
- **Indentation**: 2 spaces for YAML, 4 spaces for shell scripts
- **Naming**: Use snake_case for variables, functions, and file names
- **Docker**: Include comments for complex RUN commands
- **Shell Scripts**: Use `#!/usr/bin/with-contenv bashio` for add-on scripts
- **Error Handling**: Use bashio::log.error for error reporting
- **YAML**: Keep configuration files well-documented with comments
- **Addon Structure**: Follow Home Assistant add-on specification with required files (config.yaml, Dockerfile, etc.)