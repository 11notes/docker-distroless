# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=0

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: OPENSSL
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG APP_ROOT \
      APP_VERSION \
      TARGETARCH \
      TARGETVARIANT

  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      perl \
      libidn2-dev \
      libevent-dev \
      linux-headers \
      apk-tools \
      tar;

  RUN set -ex; \
    eleven github asset openssl/openssl openssl-${APP_VERSION} openssl-${APP_VERSION}.tar.gz;

  RUN set -ex; \
    cd /openssl-${APP_VERSION}; \
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
    make -s -j $(nproc) install_sw 2>&1 > /dev/null; \
    mkdir -p ${APP_ROOT}/usr/lib; \
    cp -af /openssl-${APP_OPENSSL_VERSION}/libssl.a ${APP_ROOT}/usr/lib; \
    cp -af /openssl-${APP_OPENSSL_VERSION}/libcrypto.a ${APP_ROOT}/usr/lib;

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