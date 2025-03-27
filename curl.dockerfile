# :: Header
  FROM alpine AS distroless
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  ENV BUILD_ROOT=/curl-${APP_VERSION}
  ENV CC=clang
  USER root

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
    make -j$(nproc) V=1 LDFLAGS="-static -all-static"; \
    strip src/curl;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    cp ./src/curl ${APP_ROOT}/usr/local/bin;

# :: Distroless
  FROM scratch
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  COPY --from=distroless ${APP_ROOT}/ /

# :: Start
  ENTRYPOINT ["/usr/local/bin/curl"]