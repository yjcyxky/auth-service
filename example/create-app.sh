#!/bin/bash

export KONG_ADMIN_API=http://192.168.31.87:8001
export ENDPOINT=http://192.168.31.87:3001/data
export REDIRECT_PATH=/demo
export KEYCLOAK_API=http://192.168.31.87:8180
export REALM=experimental

export SERVICE_NAME=mock-service
export ROUTE_NAME=mock-route
export CONSUMER_NAME=mock-consumer

## Add Service
curl -s -X POST ${KONG_ADMIN_API}/services \
    -d "name=${SERVICE_NAME}" \
    -d "url=$ENDPOINT" \
    | python -mjson.tool

## Add Route
curl -s -X POST ${KONG_ADMIN_API}/services/${SERVICE_NAME}/routes \
    -d "name=${ROUTE_NAME}" \
    -d "paths[]=${REDIRECT_PATH}" \
    | python -mjson.tool

## Add Consumer
curl -s -X POST ${KONG_ADMIN_API}/consumers \
    -d "username=${CONSUMER_NAME}" \
    -d "custom_id=${CONSUMER_NAME}" \
    | python -mjson.tool

## Add CORS Plugin for Service
curl -s -X POST ${KONG_ADMIN_API}/services/${SERVICE_NAME}/plugins \
    -d "name=cors" \
    -d "config.credentials=true" \
    -d "config.exposed_headers[]=X-Auth-Token,Authorization" \
    -d "config.headers[]=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Auth-Token,Authorization" \
    | python -mjson.tool

## Add JWT Plugin for Consumer
export RSA_PUBLIC_KEY=`curl -s -X GET ${KEYCLOAK_API}/realms/${REALM} | python -mjson.tool | jq -r '.public_key'`
curl -s -X POST ${KONG_ADMIN_API}/consumers/${CONSUMER_NAME}/jwt -H "Content-Type: application/json" \
    -d "{\"key\": \"${KEYCLOAK_API}/realms/${REALM}\", \"algorithm\": \"RS256\", \"rsa_public_key\": \"-----BEGIN PUBLIC KEY-----\n${RSA_PUBLIC_KEY}\n-----END PUBLIC KEY-----\"}" \
    | python -mjson.tool

## Add JWT Plugin for Service
curl -s -X POST ${KONG_ADMIN_API}/services/${SERVICE_NAME}/plugins \
    -d "name=jwt" \
    | python -mjson.tool

## Add Token Extractor Plugin for Service
curl -s -X POST ${KONG_ADMIN_API}/plugins \
    -d "name=token-to-header-extractor" \
    -d "config.log_errors=true" \
    | python -mjson.tool

## Configuring Token, Key and Header Name values
curl -s -X POST ${KONG_ADMIN_API}/token_to_header_extractor \
    -d "token_name=Authorization" \
    -d "token_value_name=email" \
    -d "header_name=X-Email" \
    | python -mjson.tool

## Add OIDC Plugin (Only when you don't need to redirect to keycloak login page)
### Get CLIENT_SECRET from Keycloak Client
### Only pay attention to the "bearer_only=yes": with this setting kong will introspect tokens without redirecting. This is useful if you're build an app / webpage and want full control over the login process: infact, kong will not redirect the user to keycloak login page upon an unauthorized request, but will reply with 401.
CLIENT_SECRET="u7LgOqp2Il6CCUjUtcnPy3c8tZIYaCdY"
REALM="${REALM}"

curl -s -X POST ${KONG_ADMIN_API}/plugins \
  -d "name=oidc" \
  -d "config.client_id=kong" \
  -d "config.client_secret=${CLIENT_SECRET}" \
  -d "config.bearer_only=yes" \
  -d "config.realm=${REALM}" \
  -d "config.introspection_endpoint=http://${KEYCLOAK_API}/realms/${REALM}/protocol/openid-connect/token/introspect" \
  -d "config.discovery=http://${KEYCLOAK_API}/auth/realms/${REALM}/.well-known/openid-configuration" \
  | python -mjson.tool
