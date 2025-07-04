# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

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
      APP_VERSION
  ENV BUILD_DIR=/node-v${APP_VERSION} \
      BUILD_BIN=/node-v${APP_VERSION}/out/Release/node \
      BUILD_SRC=node-v${APP_VERSION}.tar.gz

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
    wget https://nodejs.org/dist/v${APP_VERSION}/${BUILD_SRC}; \
    wget https://nodejs.org/dist/v${APP_VERSION}/SHASUMS256.txt;

  RUN set -ex; \
    SHA256=$(cat SHASUMS256.txt | grep ${BUILD_SRC} | awk -F ' ' '{print $1}'); \
    echo "${SHA256} ${BUILD_SRC}" | sha256sum -c; \
    pv ${BUILD_SRC} | tar xz;

  RUN set -ex; \
    cd ${BUILD_DIR}; \
    ./configure --fully-static --enable-static; \
    make -s -j $(nproc);

  RUN set -ex; \
    mv ${BUILD_DIR}/out/Release ${BUILD_DIR}/out/release; \
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

  # :: multi-stage
    COPY --from=distroless  / /
    COPY --from=build  /distroless/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/node"]
  CMD ["--version"]