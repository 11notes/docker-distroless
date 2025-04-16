# :: Util
FROM 11notes/util AS util

# :: Header
  FROM golang:1.24-alpine AS build
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  ENV BUILD_ROOT=/go/lego
  ENV BUILD_BIN=${BUILD_ROOT}/dist/lego
  ENV CGO_ENABLED=0
  COPY --from=util /usr/local/bin/ /usr/local/bin
  USER root

# :: Build
  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      upx \
      git; \
    git clone https://github.com/go-acme/lego.git -b v${APP_VERSION}; \
    cd ${BUILD_ROOT}; \
    go mod tidy; \
    go build -trimpath -ldflags '-X "main.version='${APP_VERSION}'" -extldflags=-static' -o  dist/lego ./cmd/lego/;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    eleven strip ${BUILD_BIN}; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;

# :: Distroless
  FROM 11notes/distroless AS distroless
  FROM scratch
  ARG APP_ROOT
  ARG APP_UID
  ARG APP_GID
  COPY --from=distroless --chown=${APP_UID}:${APP_GID} / /
  COPY --from=build --chown=${APP_UID}:${APP_GID} ${APP_ROOT}/ /

# :: Start
  ENTRYPOINT ["/usr/local/bin/lego"]