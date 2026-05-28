# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_RUST_VERSION=0

# APP
  ARG BUILD_SRC=https://github.com/Y2Z/monolith.git \
      BUILD_ROOT=/monolith

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: MONOLITH
  FROM 11notes/rust:${APP_RUST_VERSION} AS build
  COPY --from=util-bin / /
  ARG TARGETARCH \
      TARGETVARIANT \
      APP_ROOT \
      APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT

  RUN set -ex; \
    apk --update --no-cache add \
      perl;

  RUN set -ex; \
    git clone --recurse-submodules -j8 ${BUILD_SRC} -b v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    cargo build --release;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    eleven distroless ./target/release/monolith;


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
    COPY --from=build ${APP_ROOT}/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/monolith"]
  CMD ["--version"]