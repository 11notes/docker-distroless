# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=2.44
  ARG BUILD_ROOT=/binutils-${APP_VERSION} \
      BUILD_TAR=binutils-${APP_VERSION}.tar.gz
  ARG BUILD_BIN=${BUILD_ROOT}/dist/bin/strip \
      BUILD_SRC=https://ftp.gnu.org/gnu/binutils/${BUILD_TAR} \
      GPG_KEY=13FCEF89DD9E3C4F


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: STRIP
  FROM alpine AS build
  COPY --from=util-bin / /
  COPY ./src/pv /
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN \
      BUILD_TAR \
      GPG_KEY

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
    gpg --keyserver keys.gnupg.net --recv-keys ${GPG_KEY};

  RUN set -ex; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC}; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC}.sig;

  RUN set -ex; \
    gpg --verify ${BUILD_TAR}.sig ${BUILD_TAR}; \
    pv ${BUILD_TAR} | tar xz;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./configure \
      --disable-nls \
      --prefix="${PWD}/dist"; \
    make configure-host; \
    make -s -j $(nproc) LDFLAGS="-all-static" 2>&1 > /dev/null; \
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
  ENTRYPOINT ["/usr/local/bin/strip"]
  CMD ["--version"]