# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: unrar
  FROM alpine AS distroless
  ARG TARGETARCH \
      APP_ROOT \
      APP_VERSION
  ARG BUILD_ROOT=/unrar
  ARG BUILD_BIN=${BUILD_ROOT}/unrar \
      BUILD_SRC=unrarsrc-${APP_VERSION}.tar.gz
  USER root

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
      gpg-agent;

  RUN set -ex; \
    apk --update --no-cache add \
      g++ \
      make;

  RUN set -ex; \
    wget https://www.rarlab.com/rar/${BUILD_SRC};

  RUN set -ex; \
    echo "9ec7765a948140758af12ed29e3e47db425df79a9c5cbb71b28769b256a7a014 ${BUILD_SRC}" | sha256sum -c || exit 1; \
    pv ${BUILD_SRC} | tar xz;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    make -s -j $(nproc) V=1 LDFLAGS="--static";

  RUN set -ex; \
    file ${BUILD_BIN} | grep -q "statically linked" || exit 1; \
    strip -v ${BUILD_BIN}; \
    upx -q -9 ${BUILD_BIN};

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

  COPY --from=distroless ${APP_ROOT}/ /

# :: EXECUTE
USER ${APP_UID}:${APP_GID}
ENTRYPOINT ["/usr/local/bin/unrar"]
CMD ["--version"]