# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_SRC=https://github.com/jqlang/jq.git \
      BUILD_ROOT=/jq
  ARG BUILD_BIN=${BUILD_ROOT}/jq


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: JQ
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
      git \
      g++ \
      libtool \
      automake \
      autoconf \
      build-base;

  RUN set -ex; \
    git clone --recurse-submodules -j8 ${BUILD_SRC} -b jq-${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    autoreconf -i; \
    ./configure \
      --disable-docs \
      --with-oniguruma=builtin \
      --enable-static \
      --enable-all-static \
      --prefix=/usr/local; \
    make -s -j $(nproc) LDFLAGS="-all-static"  2>&1 > /dev/null;

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
  ENTRYPOINT ["/usr/local/bin/jq"]
  CMD ["--version"]