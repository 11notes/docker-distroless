# :: Util
  FROM 11notes/util AS util

# :: Header
  FROM golang:1.24-alpine AS distroless
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  COPY --from=util /usr/local/bin/ /usr/local/bin
  USER root

# :: Build
  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      git; \
    git clone https://github.com/ameshkov/dnslookup.git -b v${APP_VERSION}; \
    cd /go/dnslookup; \
    eleven patchGoMod go.mod "golang.org/x/crypto|v0.31.0|CVE-2024-45337"; \
    eleven patchGoMod go.mod "github.com/quic-go/quic-go|v0.48.2|CVE-2024-53259"; \
    eleven patchGoMod go.mod "golang.org/x/net|v0.36.0|CVE-2025-22870"; \
    go mod tidy; \
    go build -ldflags="-extldflags=-static"; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    strip ./dnslookup; \
    cp ./dnslookup ${APP_ROOT}/usr/local/bin;

# :: Distroless
  FROM scratch
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  COPY --from=distroless ${APP_ROOT}/ /

# :: Start
  ENTRYPOINT ["/usr/local/bin/dnslookup"]