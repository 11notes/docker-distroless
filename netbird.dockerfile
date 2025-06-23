# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000

  # :: FOREIGN IMAGES
  FROM 11notes/netbird:${APP_VERSION} AS netbird


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: HEADER
  FROM scratch

  ARG APP_UID \
      APP_GID

  COPY --from=netbird --chown=${APP_UID}:${APP_GID} / /

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}