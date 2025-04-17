ARG APP_VERSION=stable
ARG APP_UID=1000
ARG APP_GID=1000

# :: Distroless
  FROM 11notes/distroless AS distroless
  FROM 11notes/adguard-sync:${APP_VERSION} AS adguard-sync
  FROM scratch
  ARG APP_UID
  ARG APP_GID
  COPY --from=distroless --chown=${APP_UID}:${APP_GID} / /
  COPY --from=adguard-sync --chown=${APP_UID}:${APP_GID} /usr/local/bin/adguardhome-sync /usr/local/bin/adguardhome-sync

# :: Start
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/adguardhome-sync"]