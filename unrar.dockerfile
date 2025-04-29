ARG APP_UID=1000
ARG APP_GID=1000

# :: Util
  FROM 11notes/util AS util

# :: Header
  FROM alpine AS build
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  ENV BUILD_ROOT=/unrar
  ENV BUILD_BIN=${BUILD_ROOT}/unrar
  USER root
  COPY --from=util /usr/local/bin/ /usr/local/bin

# :: Build
  RUN set -ex; \
    apk --update --no-cache add \
      build-base \
      gcc \
      clang \
      g++ \
      make \
      cmake \
      git \
      curl \
      tar \
      xz;

  RUN set -ex; \
    curl -SL https://www.rarlab.com/rar/unrarsrc-${APP_VERSION}.tar.gz | tar -zxC /;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    make -s -j $(nproc) V=1 LDFLAGS="--static";

  RUN set -ex; \
    eleven checkStatic ${BUILD_BIN}; \
    eleven strip ${BUILD_BIN}; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;

# :: Distroless
  FROM scratch
  ARG APP_ROOT
  ARG APP_UID
  ARG APP_GID
  COPY --from=build --chown=${APP_UID}:${APP_GID} ${APP_ROOT}/ /

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/unrar"]