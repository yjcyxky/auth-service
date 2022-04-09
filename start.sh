#!/bin/bash

set -e

# docker network create biominer-lab-network
docker-compose build kong
docker-compose up -d kong-db
docker-compose run --rm kong kong migrations bootstrap
docker-compose run --rm kong kong migrations up
docker-compose up -d kong
docker-compose ps
curl -s http://localhost:8001 | jq .plugins.available_on_server.oidc
docker-compose up -d konga
sleep 120
docker-compose up -d keycloak
docker-compose ps
