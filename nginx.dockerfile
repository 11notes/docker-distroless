ARG APP_VERSION=stable
ARG APP_UID=1000
ARG APP_GID=1000

# :: Distroless
  FROM 11notes/nginx:${APP_VERSION} AS nginx
  FROM scratch
  ARG APP_UID
  ARG APP_GID
  COPY --from=nginx --chown=${APP_UID}:${APP_GID} /usr/local/bin/nginx /usr/local/bin
  COPY --from=nginx --chown=${APP_UID}:${APP_GID} /nginx /
  COPY --from=nginx --chown=${APP_UID}:${APP_GID} /etc/nginx /etc

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/nginx"]