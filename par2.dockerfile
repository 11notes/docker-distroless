ARG APP_UID=1000
ARG APP_GID=1000

# :: Util
  FROM 11notes/util AS util

# :: Header
  FROM alpine AS build
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  ENV BUILD_ROOT=/par2cmdline-turbo
  ENV BUILD_BIN=${BUILD_ROOT}/par2
  USER root
  COPY --from=util /usr/local/bin/ /usr/local/bin

# :: Build
  RUN set -ex; \
    apk --no-cache --update add \
      autoconf \
      automake \
      build-base \
      libffi-dev \
      openssl-dev \
      python3-dev \
      git;

  RUN set -ex; \
    git clone https://github.com/animetosho/par2cmdline-turbo -b v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    ./automake.sh; \
    ./configure \
      --prefix="/usr"; \
    make -s -j $(nproc) V=1 LDFLAGS="--static";

  RUN set -ex; \
    mkdir -p ${APP_ROOT}/usr/local/bin; \
    eleven strip ${BUILD_BIN}; \
    cp ${BUILD_BIN} ${APP_ROOT}/usr/local/bin;

# :: Distroless
  FROM scratch
  ARG APP_ROOT
  ARG APP_UID
  ARG APP_GID
  COPY --from=build --chown=${APP_UID}:${APP_GID} ${APP_ROOT}/ /

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/par2"]