ARG APP_VERSION=stable
ARG APP_UID=0
ARG APP_GID=0

# :: Distroless
  FROM 11notes/distroless AS distroless
  FROM 11notes/socket-proxy:${APP_VERSION} AS socket-proxy
  FROM scratch
  ARG APP_UID
  ARG APP_GID
  COPY --from=distroless --chown=${APP_UID}:${APP_GID} / /
  COPY --from=socket-proxy --chown=${APP_UID}:${APP_GID} /usr/local/bin/socket-proxy /usr/local/bin/socket-proxy

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/socket-proxy"]