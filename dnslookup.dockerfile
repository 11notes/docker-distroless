ARG APP_UID=1000
ARG APP_GID=1000

# :: Util
  FROM 11notes/util AS util

# :: Header
  FROM golang:1.24-alpine AS distroless
  ARG APP_ROOT
  ARG APP_VERSION
  ENV BUILD_ROOT=/go/dnslookup
  ENV BUILD_BIN=${BUILD_ROOT}/dnslookup
  ENV CGO_ENABLED=0
  COPY --from=util /usr/local/bin/ /usr/local/bin
  USER root

# :: Build
  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      upx \
      git; \
    git clone https://github.com/ameshkov/dnslookup.git -b v${APP_VERSION}; \
    cd ${BUILD_ROOT}; \
    eleven patchGoMod go.mod "golang.org/x/crypto|v0.31.0|CVE-2024-45337"; \
    eleven patchGoMod go.mod "github.com/quic-go/quic-go|v0.48.2|CVE-2024-53259"; \
    eleven patchGoMod go.mod "golang.org/x/net|v0.36.0|CVE-2025-22870"; \
    go mod tidy; \
    go build -ldflags="-extldflags=-static";

  RUN set -ex; \
    eleven checkStatic ${BUILD_BIN}; \
    eleven strip ${BUILD_BIN}; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;

# :: Distroless
  FROM scratch
  ARG APP_ROOT
  ARG APP_UID
  ARG APP_GID
  COPY --from=distroless ${APP_ROOT}/ /

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/dnslookup"]