#!/bin/bash

set -e

SERVICE_HEALTHY_TIMEOUT=30

docker_cleanup(){
	docker rm -f timestamp-generator timestamp-formatter 2>/dev/null || true
	docker network rm "${DOCKER_NETWORK}" 2>/dev/null || true
}

wait_for_service_to_become_healthy() {
	elapsed=0
	while (( elapsed++ < SERVICE_HEALTHY_TIMEOUT )); do
		if curl --connect-timeout 1 -sf http://localhost:"${1}"/_/health > /dev/null 2>&1; then
			return 0
		fi
		sleep 1
	done
	return 1
}

exit_procedure() {
	echo "$1"
	docker_cleanup 
	exit 1
}

VERSION_GENERATOR="latest"
VERSION_FORMATTER="latest"
GENERATOR_PORT=8080
FORMATTER_PORT=8081
DOCKER_NETWORK="timestamp-network"

for arg in "$@"; do
    case $arg in
        --version_generator=*) VERSION_GENERATOR="${arg#*=}" ;;
        --version_formatter=*) VERSION_FORMATTER="${arg#*=}" ;;
        --generator_port=*) GENERATOR_PORT="${arg#*=}" ;;
        --formatter_port=*) FORMATTER_PORT="${arg#*=}" ;;
        --generator_cpu=*) GENERATOR_CPU="${arg#*=}" ;;
        --formatter_cpu=*) FORMATTER_CPU="${arg#*=}" ;;
        --generator_memory=*) GENERATOR_MEMORY="${arg#*=}" ;;
        --formatter_memory=*) FORMATTER_MEMORY="${arg#*=}" ;;
        --docker_network=*) DOCKER_NETWORK="${arg#*=}" ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

echo "Deploying:"
echo "  timestamp-generator: ${VERSION_GENERATOR}"
echo "  timestamp-formatter: ${VERSION_FORMATTER}"

echo "Cleaning up old containers..."
docker_cleanup

echo "Creating Docker network..."
docker network create "${DOCKER_NETWORK}" 2>/dev/null || true

echo "Starting docker container for generator service"
docker run -d \
    --name timestamp-generator \
    --network "${DOCKER_NETWORK}" \
	  --cpus "${GENERATOR_CPU}" \
	  --memory "${GENERATOR_MEMORY}" \
    -p "${GENERATOR_PORT}":8080 \
    karslo92111/timestamp-generator:"${VERSION_GENERATOR}"

echo "Starting docker container for formatter service"
docker run -d \
    --name timestamp-formatter \
    --network "${DOCKER_NETWORK}" \
	  --cpus "${FORMATTER_CPU}" \
	  --memory "${FORMATTER_MEMORY}" \
    -p "${FORMATTER_PORT}":8080 \
    -e GENERATOR_SERVICE_URL=http://timestamp-generator:8080 \
    karslo92111/timestamp-formatter:"${VERSION_FORMATTER}" 

echo "Services started"


echo "Waiting for generator service to become healty"
if ! wait_for_service_to_become_healthy "${GENERATOR_PORT}"; then
	exit_procedure "Service generator failed to become healty"
fi

echo "Waiting for formatter service to become healty"
if ! wait_for_service_to_become_healthy "${FORMATTER_PORT}"; then
	exit_procedure "Service formatter failed to become healty"
fi

echo "Verifying end-to-end communication..."
if curl -sf -X POST http://localhost:"${FORMATTER_PORT}" > /dev/null; then
    echo "Success."
else
	exit_procedure "Failed"
fi
