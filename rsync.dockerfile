# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: RSYNC
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG TARGETARCH \
      TARGETVARIANT \
      APP_VERSION \
      BUILD_SRC=https://github.com/RsyncProject/rsync.git \
      BUILD_ROOT=/rsync \
      BUILD_BIN=/rsync/rsync

  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      git \
      popt-dev \
      zlib-dev \
      openssl-dev \
      xxhash-dev \
      lz4-dev \
      zstd-dev \
      automake \
      autoconf \
      gettext-dev;

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./configure \
      --disable-openssl \
      --disable-xxhash \
      --disable-lz4 \
      --disable-zstd \
      --disable-md2man \
      CFLAGS="-O2 -static" \
      LDFLAGS="-static"; \
    make -s -j $(nproc) 2>&1 > /dev/null;

  RUN set -ex; \
    eleven distroless ${BUILD_BIN};

  RUN set -ex; \
    /distroless/usr/local/bin${BUILD_BIN} --version | grep -q "${APP_VERSION}";


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
  ENTRYPOINT ["/usr/local/bin/rsync"]
  CMD ["--version"]