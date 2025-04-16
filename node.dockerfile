ARG APP_VERSION=stable
ARG APP_UID=1000
ARG APP_GID=1000

# :: Distroless
  FROM 11notes/node:${APP_VERSION} AS node
  FROM scratch
  ARG APP_UID
  ARG APP_GID
  COPY --from=node --chown=${APP_UID}:${APP_GID} /usr/local/bin/node /usr/local/bin

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/node"]