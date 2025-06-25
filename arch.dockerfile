# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: Root CA, timezone and default users
  FROM alpine AS distroless
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  USER root

# :: create base folders
  RUN set -ex; \
    mkdir -p ${APP_ROOT}/etc; \
    mkdir -p ${APP_ROOT}/run; \
    mkdir -p ${APP_ROOT}/tmp;

# :: create users
  RUN set -ex; \
    echo "root:x:0:0:root:/root:/sbin/nologin" > ${APP_ROOT}/etc/passwd; \
    echo "root:x:0:root" > ${APP_ROOT}/etc/group; \
    echo "docker:x:1000:1000:docker:/:/sbin/nologin" >> ${APP_ROOT}/etc/passwd; \
    echo "docker:x:1000:docker" >> ${APP_ROOT}/etc/group;

# :: add ca-certificates
  RUN set -ex; \
    apk --no-cache --update --repository https://dl-cdn.alpinelinux.org/alpine/edge/main add \
      ca-certificates; \
    mkdir -p ${APP_ROOT}/usr/share/ca-certificates; \
    mkdir -p ${APP_ROOT}/etc/ssl/certs; \
    cp -R /usr/share/ca-certificates/* ${APP_ROOT}/usr/share/ca-certificates; \
    cp -R /etc/ssl/certs/* ${APP_ROOT}/etc/ssl/certs;

# :: add timezones
  RUN set -ex; \
    apk --no-cache --update --repository https://dl-cdn.alpinelinux.org/alpine/edge/main add \
      tzdata; \
    mkdir -p ${APP_ROOT}/usr/share/zoneinfo; \
    cp -R /usr/share/zoneinfo/* ${APP_ROOT}/usr/share/zoneinfo;

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
  ENTRYPOINT ["/"]