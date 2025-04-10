# :: Util
  FROM 11notes/util AS util

# :: Header
  FROM golang:1.24-alpine AS build
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  ENV BUILD_ROOT=/go/go-tini-pm
  ENV BUILD_BIN=${BUILD_ROOT}/tini-pm
  ENV CC=clang
  ENV CGO_ENABLED=0
  USER root

  COPY --from=util /usr/local/bin/ /usr/local/bin

  RUN set -ex; \
    apk --update --no-cache add \
      git; \
    git clone https://github.com/11notes/go-tini-pm.git -b v${APP_VERSION};

  RUN set -ex; \
    eleven printenv; \
    cd ${BUILD_ROOT}; \
    ls -lah * ; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    mkdir -p ${APP_ROOT}/run/tini-pm; \
    go mod tidy; \
    go build -ldflags="-extldflags=-static" -o ${BUILD_BIN} main.go; \
    eleven strip ${BUILD_BIN}; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;

# :: Distroless
  FROM scratch
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  COPY --from=build ${APP_ROOT}/ /

# :: Start
  ENTRYPOINT ["/usr/local/bin/tini-pm"]