ARG APP_UID=1000
ARG APP_GID=1000

# :: Util
  FROM 11notes/util AS util

# :: Header
  FROM golang:1.24-alpine AS build
  ARG APP_ROOT
  ENV BUILD_ROOT=/go/go-tini-pm
  ENV BUILD_BIN=${BUILD_ROOT}/tini-pm
  ENV CGO_ENABLED=0
  USER root

  COPY --from=util /usr/local/bin/ /usr/local/bin

  RUN set -ex; \
    apk --update --no-cache add \
      git; \
    git clone https://github.com/11notes/go-tini-pm.git;

  RUN set -ex; \
    eleven printenv;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    go mod tidy; \
    go build -ldflags="-extldflags=-static" -o ${BUILD_BIN} main.go; \
    eleven strip ${BUILD_BIN}; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;

# :: Distroless
  FROM 11notes/distroless:cmd-socket AS distroless-cmd-socket
  FROM scratch
  ARG APP_ROOT
  ARG APP_UID
  ARG APP_GID
  COPY --from=build --chown=${APP_UID}:${APP_GID} ${APP_ROOT}/ /
  COPY --from=distroless-cmd-socket --chown=${APP_UID}:${APP_GID} / /

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/tini-pm"]