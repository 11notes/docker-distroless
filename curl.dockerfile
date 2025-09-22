# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=8.15.0
  ARG BUILD_TAR=curl-${APP_VERSION}.tar.gz
  ARG BUILD_SRC=https://curl.se/download/${BUILD_TAR} \
      BUILD_ROOT=/curl-${APP_VERSION} \
      BUILD_BIN=/curl-${APP_VERSION}/src/curl

  # :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: CURL
  FROM alpine AS build
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN \
      BUILD_TAR

  ENV CC=clang

# :: Build
  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      clang \
      openssl-dev \
      nghttp2-dev \
      nghttp2-static \
      libssh2-dev \
      libssh2-static \
      perl \
      openssl-libs-static \
      zlib-static \
      tar \
      wget \
      upx \
      binutils \
      gpg \
      gpg-agent \
      pv;

  RUN set -ex; \
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 27EDEAF22F3ABCEB50DB9A125CC908FDB71E12C2;

  RUN set -ex; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC}; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC}.asc;

  RUN set -ex; \
    gpg --verify ${BUILD_TAR}.asc ${BUILD_TAR}; \
    pv ${BUILD_TAR} | tar xz;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    LDFLAGS="-static" PKG_CONFIG="pkg-config --static" \
      ./configure \
        --disable-shared \
        --enable-static \
        --disable-ldap \
        --disable-ipv6 \
        --enable-unix-sockets \
        --with-ssl  \
        --disable-docs \
        --disable-manual \
        --without-libpsl; \
    make -s -j $(nproc) V=1 LDFLAGS="-static -all-static"  2>&1 > /dev/null;

  RUN set -ex; \
    strip -v "${BUILD_BIN}" &> /dev/null; \
    upx -q --no-backup -9 --best --lzma "${BUILD_BIN}" &> /dev/null; \
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
    COPY --from=distroless / /
    COPY --from=build ${APP_ROOT}/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/curl"]
  CMD ["--version"]