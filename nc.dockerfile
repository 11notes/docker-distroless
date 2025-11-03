# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_SRC=https://salsa.debian.org/debian/netcat-openbsd.git \
      BUILD_ROOT=/netcat-openbsd
  ARG BUILD_BIN=${BUILD_ROOT}/nc

# :: FOREIGN IMAGES
  FROM 11notes/util:bin AS util-bin


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: NC
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  RUN set -ex; \
    apk --update --no-cache add \
      git \
      g++ \
      make \
      patch \
      libbsd-dev \
      libbsd-static;

  RUN set -ex; \
    git clone ${BUILD_SRC} -b debian/${APP_VERSION}-1;

  COPY ./src/nc/ /

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    git apply b64.patch; \
    sed -i -e "/SRCS=/s;\(.*\);& base64.c;" Makefile; \
    while read -r PATCH; do \
		  patch -Np1 < debian/patches/${PATCH} || echo "warning"; \
    done < debian/patches/series;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    make -s -j $(nproc) LDFLAGS="--static" 2>&1 > /dev/null;

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
    COPY --from=build ${APP_ROOT}/ /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/nc"]
  CMD ["-version"]