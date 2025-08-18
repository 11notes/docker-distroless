# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/tini \
      BUILD_SRC=https://github.com/krallin/tini.git
  ARG BUILD_BIN=${BUILD_ROOT}/tini-static


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: TINI
  FROM alpine AS build
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  ENV CFLAGS="-DPR_SET_CHILD_SUBREAPER=36 -DPR_GET_CHILD_SUBREAPER=37"

  RUN set -ex; \
    apk --update --no-cache add \
      g++ \
      make \
      cmake \
      upx \
      binutils \
      git;

  RUN set -ex; \
    git clone --recurse-submodules -j8 ${BUILD_SRC};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    cmake \
      -DCMAKE_EXE_LINKER_FLAGS="-static";

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    make -s -j $(nproc) 2>&1 > /dev/null;

  RUN set -ex; \
    strip -v "${BUILD_BIN}" &> /dev/null; \
    upx -q --no-backup -9 --best --lzma "${BUILD_BIN}" &> /dev/null; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin/tini;


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
  ENTRYPOINT ["/usr/local/bin/tini"]
  CMD ["--version"]