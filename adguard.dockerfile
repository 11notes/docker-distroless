ARG APP_VERSION=stable
ARG APP_UID=1000
ARG APP_GID=1000

# :: Distroless
  FROM 11notes/distroless AS distroless
  FROM 11notes/adguard:${APP_VERSION} AS adguard
  FROM scratch
  ARG APP_UID
  ARG APP_GID
  COPY --from=distroless --chown=${APP_UID}:${APP_GID} / /
  COPY --from=adguard --chown=${APP_UID}:${APP_GID} /usr/local/bin/AdGuardHome /usr/local/bin/AdGuardHome

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/AdGuardHome"]