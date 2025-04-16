ARG APP_UID=1000
ARG APP_GID=1000

# :: Util
  FROM 11notes/util AS util

# :: Header
  FROM alpine AS build
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  ENV BUILD_ROOT=/curl-${APP_VERSION}
  ENV BUILD_BIN=/curl-${APP_VERSION}/src/curl
  ENV CC=clang
  USER root
  COPY --from=util /usr/local/bin/ /usr/local/bin

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
      upx \
      wget;

  RUN set -ex; \
    wget https://curl.se/download/curl-${APP_VERSION}.tar.gz; \
    tar xzf curl-${APP_VERSION}.tar.gz;

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
    make -s -j $(nproc) V=1 LDFLAGS="-static -all-static";

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    eleven strip ${BUILD_BIN}; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;

# :: Distroless
  FROM 11notes/distroless AS distroless
  FROM scratch
  ARG APP_ROOT
  ARG APP_UID
  ARG APP_GID
  COPY --from=distroless --chown=${APP_UID}:${APP_GID} / /
  COPY --from=build --chown=${APP_UID}:${APP_GID} ${APP_ROOT}/ /

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/curl"]