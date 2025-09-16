# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_QT_CONFIGURATION=normal \
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
      APP_QT_CONFIGURATION \
      APP_OPENSSL_VERSION \
      TARGETARCH \
      TARGETVARIANT \
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
    eleven github asset openssl/openssl ${APP_OPENSSL_VERSION} ${APP_OPENSSL_VERSION}.tar.gz;

  RUN set -ex; \
    apk --update --no-cache add \
      perl \
      make \
      linux-headers;

  RUN set -ex; \
    cd /${APP_OPENSSL_VERSION}; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      "amd64"|"arm64") \
        ./Configure \
          -static \
          --openssldir=/etc/ssl; \
      ;; \
      \
      "armv7") \
        ./Configure \
          linux-generic32 \
          -static \
          --openssldir=/etc/ssl; \
      ;; \
    esac; \
    make -s -j $(nproc) 2>&1 > /dev/null; \
    make -s -j $(nproc) install_sw 2>&1 > /dev/null;

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    case "${APP_QT_CONFIGURATION}" in \
      "normal") \
        ./configure \
          -static \
          -release \
          -prefix "/opt/qt" \
          -qt-host-path "/usr/src/qt-host/${APP_VERSION}/gcc_64/" \
          -c++std c++17 \
          -nomake tests \
          -nomake examples \
          -no-feature-testlib \
          -openssl \
          -openssl-linked \
          -optimize-size \
          -feature-optimize_full; \
      ;; \
      \
      "minimal") \
        ./configure \
          -static \
          -release \
          -prefix "/opt/qt" \
          -qt-host-path "/usr/src/qt-host/${APP_VERSION}/gcc_64/" \
          -c++std c++17 \
          -nomake tests \
          -nomake examples \
          -no-feature-testlib \
          -no-gui \
          -no-dbus \
          -no-widgets \
          -no-feature-animation \
          -openssl \
          -openssl-linked \
          -optimize-size \
          -feature-optimize_full; \
      ;; \
    esac;

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
  ENTRYPOINT ["/opt/qt/bin/qmake"]
  CMD ["--version"]