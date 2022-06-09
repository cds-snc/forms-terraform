#!/bin/bash
set -euo pipefail

# Listens for Docker container `start` events and updates the new 
# container's `/etc/hosts` file with an entry for `host.docker.internal`
# that references the host running Docker.
#
# This is required because the devcontainer is running the AWS SAM lambda
# containers using docker-in-docker (DinD), which does not add
# this host entry.

HOST_IP="$(dig +short host.docker.internal)"
docker events \
    --filter 'event=start' \
    --format '{{.ID}}' | \
    while read ID; do docker exec $ID sh -c "echo '$HOST_IP host.docker.internal' >> /etc/hosts"; done;