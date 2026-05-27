# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

# APP
  ARG BUILD_SRC=https://github.com/Y2Z/monolith.git \
      BUILD_ROOT=/monolith

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: MONOLITH
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG TARGETARCH \
      TARGETVARIANT \
      APP_ROOT \
      APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT

  RUN set -ex; \
    apk --update --no-cache add \
      curl \
      gcc \
      perl \
      g++ \
      make \
      linux-headers \
      git \
      cmake \
      build-base \
      samurai \
      python3 \
      py3-pkgconfig \
      pkgconfig;

  RUN set -eux; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs/ | sh;

  RUN set -ex; \
    git clone --recurse-submodules -j8 ${BUILD_SRC} -b v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      "amd64") \
        TARGET="x86_64-unknown-linux-musl"; \
      ;; \
      \
      "arm64") \
        TARGET="aarch64-unknown-linux-musl"; \
      ;; \
      "armv7") \
        TARGET="armv7-unknown-linux-musleabi"; \
      ;; \
    esac; \
    cargo build --release --target ${TARGET}; \
    eleven distroless ${BUILD_ROOT}/target/${TARGET}/release/monolith;


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