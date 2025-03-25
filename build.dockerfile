FROM 11notes/distroless AS distroless
FROM scratch
COPY --from=distroless --chown=1000:1000 /distroless/ /
USER docker
ENTRYPOINT ["/app"]