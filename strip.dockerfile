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
  ARG BUILD_ROOT=/binutils-${APP_VERSION}
  ARG BUILD_BIN=${BUILD_ROOT}/dist/bin/strip
  USER root

  RUN set -ex; \
    apk --update --no-cache add \
      gpg \
      gpg-agent \
      pv \
      binutils \
      upx \
      g++ \
      make \
      wget;

  RUN set -ex; \
    gpg --keyserver keys.gnupg.net --recv-keys 13FCEF89DD9E3C4F;

  RUN set -ex; \
    wget https://ftp.gnu.org/gnu/binutils/binutils-${APP_VERSION}.tar.gz; \
    wget https://ftp.gnu.org/gnu/binutils/binutils-${APP_VERSION}.tar.gz.sig;

  RUN set -ex; \
    gpg --verify binutils-${APP_VERSION}.tar.gz.sig binutils-${APP_VERSION}.tar.gz || exit 1; \
    pv binutils-${APP_VERSION}.tar.gz | tar xz;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./configure \
      --disable-nls \
      --prefix="${PWD}/dist"; \
    make configure-host; \
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
CMD ["--version"]