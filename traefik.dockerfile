ARG APP_VERSION=stable
ARG APP_UID=1000
ARG APP_GID=1000

# :: Distroless
  FROM 11notes/distroless AS distroless
  FROM 11notes/traefik:${APP_VERSION} AS traefik
  FROM scratch
  ARG APP_UID
  ARG APP_GID
  COPY --from=distroless --chown=${APP_UID}:${APP_GID} / /
  COPY --from=traefik --chown=${APP_UID}:${APP_GID} /usr/local/bin/traefik /usr/local/bin
  COPY --from=traefik --chown=${APP_UID}:${APP_GID} /traefik /

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/traefik"]