ARG APP_UID=1000
ARG APP_GID=1000

# :: Util
  FROM 11notes/util AS util

# :: Header
  FROM golang:1.24-alpine AS build
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  ENV BUILD_ROOT=/go/hysteria
  ENV BUILD_BIN=${BUILD_ROOT}/build/hysteria-linux-${TARGETARCH}
  ENV CGO_ENABLED=0
  COPY --from=util /usr/local/bin/ /usr/local/bin
  USER root

# :: Build
  RUN set -ex; \
    apk --update add \
      python3 \
      build-base \
      upx \
      git; \
    git clone https://github.com/apernet/hysteria.git -b app/v${APP_VERSION}; \
    cd ${BUILD_ROOT}; \
    python3 hyperbole.py build -r;

  RUN set -ex; \
    eleven checkStatic ${BUILD_BIN}; \
    eleven strip ${BUILD_BIN}; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin/hysteria;

# :: Distroless
  FROM 11notes/distroless AS distroless
  FROM scratch
  ARG APP_ROOT
  ARG APP_UID
  ARG APP_GID
  COPY --from=distroless --chown=${APP_UID}:${APP_GID} / /
  COPY --from=build --chown=${APP_UID}:${APP_GID} ${APP_ROOT}/ /

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/hysteria"]