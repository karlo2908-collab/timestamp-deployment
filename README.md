# Timestamp-deployment

This repo contains the necessary scripts for the deployment of the timestamp-formatter and timestamp-generator.

## Prerequisites

- Docker
- curl

## Usage

```bash
bash deploy.sh [OPTIONS]
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--version_generator` | `latest` | Generator image version |
| `--version_formatter` | `latest` | Formatter image version |
| `--generator_port` | `8080` | Host port for generator |
| `--formatter_port` | `8081` | Host port for formatter |
| `--generator_cpu` | `0.5` | CPU limit for generator |
| `--formatter_cpu` | `0.5` | CPU limit for formatter |
| `--generator_memory` | `128m` | Memory limit for generator |
| `--formatter_memory` | `128m` | Memory limit for formatter |
| `--docker_network` | `timestamp-network` | Docker network name |

Default values are sourced from `deploy.conf`

### Examples

```bash
# Deploy with defaults
bash deploy.sh

# Deploy specific versions
bash deploy.sh --version_generator=sha-abc1234 --version_formatter=sha-abc1234

# Custom ports and resources
bash deploy.sh --generator_port=9090 --formatter_port=9091 --generator_memory=256m
```

### Notes

Script does automatic cleanup so that subsequent runs can work without failure.

## Tests

Simple integration test is provided alongside with its `Dockerfile` in `tests` directory.

### Running tests

Ensure that both generator and formatter are running on the host you are running this from.

```bash 
docker build -t timestamp-integration-test ./tests/integration/
docker run --network host -e FORMATTER_URL=http://localhost:8081 timestamp-integration-test
```

## CD

Pipeline ensures running the `deploy.sh` script with defaults provided in `deploy.conf` and activates on push to the main branch.

Pipeline also runs tests and are mixed here with the deploy step just to show them. Real integration tests would, in production setup, be run on different runner that serves just for testing and that run would be prerequisite for the actual deploy step. 