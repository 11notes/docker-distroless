# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: PS
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG APP_VERSION \
      BUILD_SRC=https://gitlab.com/procps-ng/procps.git \
      BUILD_ROOT=/procps \
      BUILD_BIN=/procps/src/ps/pscommand \
      BUILD_BIN_RENAME=/ps

  RUN set -ex; \
    apk --update --no-cache add \
      git \
      g++ \
      make \
      ncurses-static \
      autoconf \
      automake \
      gettext-dev \
      libtool \
      ncurses-dev \
      utmps-dev;

  RUN set -ex; \
    git clone ${BUILD_SRC} -b v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./autogen.sh;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./configure \
      --disable-shared \
      LDFLAGS=--static;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    make -s -j $(nproc) LDFLAGS="-static -all-static" 2>&1 > /dev/null;

  RUN set -ex; \
    mv ${BUILD_BIN} ${BUILD_BIN_RENAME}; \
    eleven distroless ${BUILD_BIN_RENAME};


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
  ENTRYPOINT ["/usr/local/bin/ps"]
  CMD ["--version"]