# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      APP_VERSION=22.17.1
  ARG BUILD_DIR=/node-v${APP_VERSION} \
      BUILD_BIN=/node-v${APP_VERSION}/out/Release/node \
      BUILD_TAR=node-v${APP_VERSION}.tar.gz
  ARG BUILD_SRC=https://nodejs.org/dist/v${APP_VERSION}/${BUILD_TAR} \
      BUILD_CHECKSUM_SRC=https://nodejs.org/dist/v${APP_VERSION}/SHASUMS256.txt

# FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/util:bin AS util


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: NODE
  FROM alpine AS build
  ARG TARGETARCH \
      APP_ROOT \
      APP_VERSION \
      BUILD_DIR \
      BUILD_BIN \
      BUILD_SRC \
      BUILD_TAR \
      BUILD_CHECKSUM_SRC

  COPY --from=util / /

  RUN set -ex; \
    apk --update --no-cache add \
      gpg \
      gpg-agent \
      pv \
      wget \
      g++ \
      libgcc \
      linux-headers \
      make \
      python3 \
      py-setuptools;

  RUN set -ex; \
    wget -q --show-progress --progress=bar:force ${BUILD_SRC}; \
    wget -q --show-progress --progress=bar:force ${BUILD_CHECKSUM_SRC};

  RUN set -ex; \
    SHA256=$(cat SHASUMS256.txt | grep ${BUILD_TAR} | awk -F ' ' '{print $1}'); \
    echo "${SHA256} ${BUILD_TAR}" | sha256sum -c; \
    pv ${BUILD_TAR} | tar xz;

  RUN set -ex; \
    cd ${BUILD_DIR}; \
    ./configure --fully-static --enable-static;

  RUN set -ex; \
    cd ${BUILD_DIR}; \
    make -s -j $(nproc) 2>&1 > /dev/null

  RUN set -ex; \
    eleven distroless ${BUILD_BIN};


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
    COPY --from=distroless / /
    COPY --from=build ${APP_ROOT}/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/node"]
  CMD ["--version"]