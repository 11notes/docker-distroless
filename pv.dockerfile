# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=1.9.31
  ARG BUILD_ROOT=/pv-${APP_VERSION} \
      BUILD_TAR=pv-${APP_VERSION}.tar.gz
  ARG BUILD_BIN=${BUILD_ROOT}/dist/bin/pv \
      BUILD_SRC=http://ivarch.com/s/${BUILD_TAR}


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: PV
  FROM alpine AS build
  COPY ./src/pv /
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN \
      BUILD_TAR

  RUN set -ex; \
    apk --update --no-cache add \
      binutils \
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
    gpg --import /key.txt;

  RUN set -ex; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC}; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC}.txt;

  RUN set -ex; \
    gpg --verify ${BUILD_TAR}.txt ${BUILD_TAR}; \
    pv ${BUILD_TAR} | tar xz;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    CFLAGS="$CFLAGS -flto=auto" \
    ./configure \
      --prefix="${BUILD_ROOT}/dist" \
      --disable-nls \
      --disable-shared \
      --enable-static; \
    make -s -j $(nproc) LDFLAGS="--static" 2>&1 > /dev/null; \
    make install;

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;


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
  ENTRYPOINT ["/usr/local/bin/pv"]
  CMD ["--version"]