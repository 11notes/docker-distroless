# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: upx
  FROM alpine AS distroless
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  USER root

  RUN set -ex; \
    apk --update --no-cache add \
      g++ \
      git \
      cmake \
      samurai;

  RUN set -ex; \
    git clone --recurse-submodules https://github.com/upx/upx.git -b v${APP_VERSION};

  RUN set -ex; \
    cd /upx; \
    cmake -B build -G Ninja \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release \
      -DUPX_CONFIG_DISABLE_WERROR=ON \
      -DUPX_CONFIG_DISABLE_SANITIZE=ON \
      -DCMAKE_EXE_LINKER_FLAGS="-static" \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
      -DUPX_CONFIG_DISABLE_GITREV=ON; \
    cmake --build build; \
    /upx/build/upx -q /upx/build/upx; \
    /upx/build/upx --version; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    cp /upx/build/upx ${APP_ROOT}/usr/local/bin;

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
ENTRYPOINT ["/usr/local/bin/upx"]