FROM kong:alpine

LABEL description="Alpine + Kong + kong-oidc plugin + kong-plugin-token-to-header-extractor"

USER root
RUN apk update && apk add curl git gcc musl-dev
RUN luarocks install luaossl OPENSSL_DIR=/usr/local/kong CRYPTO_DIR=/usr/local/kong
RUN luarocks install --pin lua-resty-jwt
RUN luarocks install kong-oidc
# More details on https://github.com/vnwonah/kong-token-to-header-extractor
RUN luarocks install kong-plugin-token-to-header-extractor

USER kong
