# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=7.1.8 \
      BUILD_ROOT=/unrar
  ARG BUILD_TAR=unrarsrc-${APP_VERSION}.tar.gz
  ARG BUILD_BIN=${BUILD_ROOT}/unrar \
      BUILD_SRC=https://www.rarlab.com/rar/${BUILD_TAR} \
      SHA256_SUM=2e9cbc9d1c250b40f4a7a6a363b6ccfa3703e190534979d18c8c4ac5ae35dafc

  # :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin     


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: UNRAR
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN \
      BUILD_TAR \
      SHA256_SUM

  RUN set -ex; \
    apk --update --no-cache add \
      file \
      binutils \
      upx \
      pv \
      tar \
      wget \
      curl \
      xz \
      gpg \
      gpg-agent \
      g++ \
      make;

  RUN set -ex; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC};

  RUN set -ex; \
    echo "${SHA256_SUM} ${BUILD_TAR}" | sha256sum -c; \
    pv ${BUILD_TAR} | tar xz;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    make -s -j $(nproc) V=1 LDFLAGS="--static" 2>&1 > /dev/null;

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
    COPY --from=build ${APP_ROOT}/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/unrar"]