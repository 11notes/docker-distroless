# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

  # :: FOREIGN IMAGES
  FROM 11notes/distroless:upx AS distroless-upx


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: upx
  FROM alpine AS distroless
  COPY --from=distroless-upx / /
  ARG TARGETARCH \
      APP_ROOT \
      APP_VERSION
  USER root

  RUN set -ex; \
    apk --update --no-cache add \
      xz \
      g++ \
      make \
      curl;

  RUN set -ex; \
    curl -SL https://ftp.gnu.org/gnu/binutils/binutils-${APP_VERSION}.tar.xz | tar -xJC /;

  RUN set -ex; \
    cd /binutils-${APP_VERSION}; \
    ./configure \
      --disable-nls \
      --prefix="${PWD}/dist"; \
    make configure-host; \
    make LDFLAGS="-all-static"; \
    make install; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    /binutils-${APP_VERSION}/dist/bin/strip -v /binutils-${APP_VERSION}/dist/bin/strip; \
    /usr/local/bin/upx -q -9 /binutils-${APP_VERSION}/dist/bin/strip; \
    /binutils-${APP_VERSION}/dist/bin/strip --version; \
    cp /binutils-${APP_VERSION}/dist/bin/strip ${APP_ROOT}/usr/local/bin;

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

  COPY --from=distroless ${APP_ROOT}/ /

  # :: EXECUTE
USER ${APP_UID}:${APP_GID}
ENTRYPOINT ["/usr/local/bin/strip"]