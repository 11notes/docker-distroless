ARG APP_ROOT

# :: Header
  FROM alpine AS distroless
  USER root

# :: create users
  RUN set -ex; \
    mkdir -p ${APP_ROOT}/etc; \
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
  COPY --from=distroless ${APP_ROOT}/ /

# :: Start
  ENTRYPOINT ["/"]