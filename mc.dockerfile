# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_GO_VERSION=0.0

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: MC
  FROM 11notes/go:${APP_GO_VERSION} AS build
  COPY --from=util-bin / /
  ARG APP_VERSION \
      APP_VERSION_BUILD \
      BUILD_SRC=minio/mc.git \
      BUILD_ROOT=/go/mc \
      BUILD_BIN=/mc

  RUN set -ex; \
    SEMVER=$(echo ${APP_VERSION} | sed 's|\.|-|g'); \
    eleven git clone ${BUILD_SRC} RELEASE.${SEMVER}T${APP_VERSION_BUILD};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    eleven go patch google.golang.org/grpc v1.79.3 CVE-2026-33186; \
    eleven go patch golang.org/x/crypto v0.45.0 CVE-2025-47914_CVE-2025-58181;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    eleven go build ${BUILD_BIN} main.go;

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
  ENTRYPOINT ["/usr/local/bin/mc"]
  CMD ["version"]