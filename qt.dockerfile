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
    eleven github asset openssl/openssl openssl-${APP_OPENSSL_VERSION} openssl-${APP_OPENSSL_VERSION}.tar.gz;

  RUN set -ex; \
    apk --update --no-cache add \
      perl \
      make \
      linux-headers;

  RUN set -ex; \
    cd /openssl-${APP_OPENSSL_VERSION}; \
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

  RUN set -ex; \
    eleven git clone qt/qttools.git v${APP_VERSION};

  RUN set -ex; \
    cd /qttools; \
    cmake -Wno-dev -B build -G Ninja \
      -DCMAKE_BUILD_TYPE="Release" \
      -DCMAKE_INSTALL_PREFIX="/opt/qt" \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_PREFIX_PATH="/opt/qt" \
      -DCMAKE_EXE_LINKER_FLAGS="-static" \
      -DBUILD_SHARED_LIBS=OFF;

  RUN set -ex; \
    cd /qttools; \
    cmake --build build; \
    cmake --install build;


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
    COPY --from=build /opt/qt /opt/qt

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/opt/qt/bin/qmake"]
  CMD ["--version"]