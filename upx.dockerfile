# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_ROOT=/upx \
      BUILD_SRC=https://github.com/upx/upx.git
  ARG BUILD_BIN=${BUILD_ROOT}/build/upx


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: UPX
  FROM alpine AS build
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  RUN set -ex; \
    apk --update --no-cache add \
      file \
      binutils \
      upx \
      pv \
      tar \
      wget \
      curl \
      xz \
      gpg \
      gpg-agent \
      g++ \
      git \
      cmake \
      samurai;

  RUN set -ex; \
    git clone --recurse-submodules -j8 ${BUILD_SRC} -b v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    cmake -B build -G Ninja \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release \
      -DUPX_CONFIG_DISABLE_WERROR=ON \
      -DUPX_CONFIG_DISABLE_SANITIZE=ON \
      -DCMAKE_EXE_LINKER_FLAGS="-static" \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
      -DUPX_CONFIG_DISABLE_GITREV=ON; \
    cmake --build build 2>&1 > /dev/null;

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
  ENTRYPOINT ["/usr/local/bin/upx"]
  CMD ["--version"]