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
# :: OPENSSL
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG APP_VERSION \
      APP_ROOT \
      TARGETARCH \
      TARGETVARIANT

  RUN set -ex; \
    apk --update --no-cache add \
      perl \
      g++ \
      make \
      linux-headers \
      git \
      cmake \
      build-base \
      samurai \
      python3 \
      py3-pkgconfig \
      pkgconfig;

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
    esac;

  RUN set -ex; \
    cd /openssl-${APP_VERSION}; \
    make -s -j $(nproc) 2>&1 > /dev/null;

  RUN set -ex; \
    eleven distroless /openssl-${APP_VERSION}/apps/openssl;

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/etc/ssl; \
    cp /openssl-${APP_VERSION}/apps/openssl.cnf ${APP_ROOT}/etc/ssl;


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
  ENTRYPOINT ["/usr/local/bin/openssl"]
  CMD ["--version"]