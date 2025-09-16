# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_SRC=qt/qtbase.git \
      BUILD_ROOT=/qtbase

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: QT
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  RUN set -ex; \
    apk --no-cache --update add \
      git \
      g++ \
      samurai \
      cmake \
      mesa-dev;

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./configure \
      -static \
      -release \
      -no-pch \
      -prefix "/qt" \
      -nomake tools \
      -nomake tests \
      -nomake examples

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    cmake --build . --parallel; \
    cmake --install .;

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
    COPY --from=build /qt /qt

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/qt/bin/qmake"]
  CMD ["--version"]