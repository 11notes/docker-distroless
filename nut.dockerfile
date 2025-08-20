# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=2.8.4 \
      BUILD_ROOT=/nut \
      BUILD_SRC=https://github.com/networkupstools/nut.git \
      BUILD_DEPENDENCY_OPENSSL_VERSION=3.5.1
  ARG BUILD_BIN=${BUILD_ROOT}/nut \
      BUILD_DEPENDENCY_OPENSSL_TAR=openssl-${BUILD_DEPENDENCY_OPENSSL_VERSION}.tar.gz \
      BUILD_DEPENDENCY_OPENSSL_ROOT=/openssl-${BUILD_DEPENDENCY_OPENSSL_VERSION}

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: OPENSSL
  FROM alpine AS openssl
  COPY --from=util-bin / /
  ARG BUILD_DEPENDENCY_OPENSSL_VERSION \
      BUILD_DEPENDENCY_OPENSSL_TAR \
      BUILD_DEPENDENCY_OPENSSL_ROOT

  RUN set -ex; \
    apk --update --no-cache add \
      git \
      build-base \
      perl \
      libidn2-dev \
      libevent-dev \
      linux-headers \
      apk-tools \
      curl \
      jq \
      tar;

  RUN set -ex; \
    eleven github asset openssl/openssl openssl-${BUILD_DEPENDENCY_OPENSSL_VERSION} ${BUILD_DEPENDENCY_OPENSSL_TAR};

  RUN set -ex; \
    cd ${BUILD_DEPENDENCY_OPENSSL_ROOT}; \
    ./Configure \
      no-weak-ssl-ciphers \
      no-apps \
      no-docs \
      no-legacy \
      no-ssl3 \
      no-err \
      no-autoerrinit \
      enable-tfo \
      enable-quic \
      enable-ktls \
      enable-ec_nistp_64_gcc_128 \
      -fPIC \
      -DOPENSSL_NO_HEARTBEATS \
      -fstack-protector-strong \
      -fstack-clash-protection \
      --prefix=/usr/local/openssl \
      --openssldir=/usr/local/openssl \
      --libdir=/usr/local/openssl/lib; \
    make -s -j $(nproc) 2>&1 > /dev/null; \
    make -s -j $(nproc) install_sw 2>&1 > /dev/null;

# :: NUT
  FROM openssl AS build
  ARG APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  RUN set -ex; \
    apk --update --no-cache add \
      make \
      automake \
      autoconf \
      libtool \
      python3 \
      net-snmp-dev \
      freeipmi-dev \
      neon-dev \
      libusb-dev;

  RUN set -ex; \
    git clone --recurse-submodules -j8 ${BUILD_SRC} -b v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    autoreconf -i; \
    ./autogen.sh;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./configure \
      --prefix=/usr \
      --sysconfdir=/nut/etc \
      --enable-strip \
      --enable-static \
      --disable-shared \
      --disable-dependency-tracking \
      --with-all \
      --with-openssl \
      --with-openssl-libs=/usr/local/openssl \
      --with-freeipmi \
      --with-python3 \
      --with-nut-scanner;

  RUN set -ex; \
    strip -v "${BUILD_BIN}" &> /dev/null; \
    upx -q --no-backup -9 --best --lzma "${BUILD_BIN}" &> /dev/null; \
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
  ENTRYPOINT ["/usr/local/bin/nut"]
  CMD ["--version"]