# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_GO_VERSION=0

# APP
  ARG BUILD_SRC=vmware/govmomi.git \
      BUILD_ROOT=/go/govmomi \
      BUILD_BIN=/govc

  # :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: GOVC
  FROM 11notes/go:${APP_GO_VERSION} AS build
  ARG APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    go build -ldflags="-extldflags=-static -X github.com/vmware/govmomi/cli/flags.BuildVersion=${APP_VERSION}" -o ${BUILD_BIN} ./govc/main.go;

  RUN set -ex; \
    ${BUILD_BIN} version | grep -q "${APP_VERSION}";

  RUN set -ex; \
    eleven distroless ${BUILD_BIN};


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=build ${APP_ROOT}/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/govc"]
  CMD ["version"]