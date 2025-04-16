ARG APP_UID=1000
ARG APP_GID=1000

# :: Header
  FROM alpine AS distroless
  ARG TARGETARCH
  ARG APP_ROOT
  ARG APP_VERSION
  USER root

# :: create base folders
  RUN set -ex; \
    mkdir -p ${APP_ROOT}/etc; \
    mkdir -p ${APP_ROOT}/run;

# :: create users
  RUN set -ex; \
    echo "root:x:0:0:root:/root:/sbin/nologin" > ${APP_ROOT}/etc/passwd; \
    echo "root:x:0:root" > ${APP_ROOT}/etc/group; \
    echo "docker:x:1000:1000:docker:/:/sbin/nologin" >> ${APP_ROOT}/etc/passwd; \
    echo "docker:x:1000:docker" >> ${APP_ROOT}/etc/group;

# :: add ca-certificates
  RUN set -ex; \
    apk --update --no-cache add \
      ca-certificates \
      tzdata; \
    mkdir -p ${APP_ROOT}/usr/share/ca-certificates; \
    mkdir -p ${APP_ROOT}/etc/ssl/certs; \
    cp -R /usr/share/ca-certificates/* ${APP_ROOT}/usr/share/ca-certificates; \
    cp -R /etc/ssl/certs/* ${APP_ROOT}/etc/ssl/certs;

# :: add timezones
  RUN set -ex; \
    apk --update --no-cache add \
      tzdata; \
    mkdir -p ${APP_ROOT}/usr/share/zoneinfo; \
    cp -R /usr/share/zoneinfo/* ${APP_ROOT}/usr/share/zoneinfo;

# :: Distroless
  FROM scratch
  ARG APP_ROOT
  ARG APP_UID
  ARG APP_GID
  COPY --from=distroless --chown=${APP_UID}:${APP_GID} ${APP_ROOT}/ /

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/"]