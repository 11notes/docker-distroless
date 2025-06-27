# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: file
  FROM alpine AS distroless
  ARG TARGETARCH \
      APP_ROOT \
      APP_VERSION
  ARG BUILD_ROOT=/file-${APP_VERSION}
  ARG BUILD_BIN=${BUILD_ROOT}/dist/file
  USER root

  RUN set -ex; \
    apk --update --no-cache add \
      binutils \
      upx \
      libmagic-static \
      file-dev \
      file-doc \
      make \
      g++ \
      curl \
      tar;

  RUN set -ex; \
    curl -SL https://astron.com/pub/file/file-${APP_VERSION}.tar.gz | tar -zxC /;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./configure \
      --prefix="${BUILD_ROOT}/dist" \
      --disable-shared \
      --enable-static; \
    make -s -j $(nproc) LDFLAGS="-all-static"; \
    make install;

  RUN set -ex; \
    strip -v ${BUILD_BIN}; \
    upx -q -9 ${BUILD_BIN};

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM alpine

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
ENTRYPOINT ["/usr/local/bin/file"]
CMD ["--version"]