# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: file
  FROM alpine AS distroless
  ARG TARGETARCH \
      APP_ROOT \
      APP_VERSION
  ARG BUILD_ROOT=/pv-${APP_VERSION}
  ARG BUILD_BIN=${BUILD_ROOT}/pv \
      BUILD_SRC=pv-${APP_VERSION}.tar.gz
  COPY ./src/pv /
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
    gpg --import /key.txt;

  RUN set -ex; \
    wget http://ivarch.com/s/${BUILD_SRC}; \
    wget http://ivarch.com/s/${BUILD_SRC}.txt;

  RUN set -ex; \
    gpg --verify ${BUILD_SRC}.txt ${BUILD_SRC} || exit 1; \
    pv ${BUILD_SRC} | tar xz;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    CFLAGS="$CFLAGS -flto=auto" \
    ./configure \
      --disable-nls; \
    make -s -j $(nproc) LDFLAGS="--static";

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
ENTRYPOINT ["/usr/local/bin/pv"]
CMD ["--version"]