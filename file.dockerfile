# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=5.46 \
      BUILD_BIN=/usr/local/bin/file
  ARG BUILD_TAR=file-${APP_VERSION}.tar.gz
  ARG BUILD_ROOT=/file-${APP_VERSION} \
      BUILD_SRC=https://astron.com/pub/file/${BUILD_TAR}


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: FILE
  FROM alpine AS build
  ARG TARGETARCH \
      APP_ROOT \
      APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN \
      BUILD_TAR

  RUN set -ex; \
    apk --update --no-cache add \
      binutils \
      upx \
      pv \
      tar \
      wget \
      curl \
      xz \
      gpg \
      gpg-agent \
      libmagic-static \
      file-dev \
      file-doc \
      make \
      g++;

  RUN set -ex; \
    gpg --keyserver hkp://keys.gnupg.net --recv-keys BE04995BA8F90ED0C0C176C471112AB16CB33B3A;

  RUN set -ex; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC}; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC}.asc;

  RUN set -ex; \
    gpg --verify ${BUILD_TAR}.asc ${BUILD_TAR}; \
    pv ${BUILD_TAR} | tar xz;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./configure \
      --prefix="/usr/local" \
      --disable-shared \
      --enable-static; \
    make -s -j $(nproc) LDFLAGS="-all-static"  2>&1 > /dev/null; \
    make install;

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/usr/local/share/misc; \
    cp /usr/local/share/misc/magic.mgc ${APP_ROOT}/usr/local/share/misc;


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
  ENTRYPOINT ["/usr/local/bin/file"]
  CMD ["--version"]