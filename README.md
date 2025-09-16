![banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# DISTROLESS
![size](https://img.shields.io/docker/image-size/11notes/distroless/latest?color=0eb305)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![version](https://img.shields.io/docker/v/11notes/distroless/latest?color=eb7a09)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![pulls](https://img.shields.io/docker/pulls/11notes/distroless?color=2b75d6)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)[<img src="https://img.shields.io/github/issues/11notes/docker-DISTROLESS?color=7842f5">](https://github.com/11notes/docker-DISTROLESS/issues)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Build your own distroless images with this mini file system and some binaries

# SYNOPSIS 📖
**What can I do with this?** This image and its different layers can be used to build a distroless boiler plate for your application. Simply add the base layer and any additional layers (tags) with the stuff you need to run your application. All binaries are statically compiled and do not depend on any OS libraries or clib. The base layer contains Root CA certificates as well as time zone data and the user configuration for root and docker. Additional layers (tags) with statically compiled binaries are:

# STAND-ALONE BINARIES
* [11notes/distroless:curl](https://github.com/11notes/docker-distroless/blob/master/curl.dockerfile) - curl
* [11notes/distroless:dnslookup](https://github.com/11notes/docker-distroless/blob/master/dnslookup.dockerfile) - dnslookup
* [11notes/distroless:lego](https://github.com/11notes/docker-distroless/blob/master/lego.dockerfile) - lego
* [11notes/distroless:par2](https://github.com/11notes/docker-distroless/blob/master/par2.dockerfile) - par2
* [11notes/distroless:unrar](https://github.com/11notes/docker-distroless/blob/master/unrar.dockerfile) - unrar (freeware!)
* [11notes/distroless:file](https://github.com/11notes/docker-distroless/blob/master/file.dockerfile) - file
* [11notes/distroless:strip](https://github.com/11notes/docker-distroless/blob/master/strip.dockerfile) - strip
* [11notes/distroless:upx](https://github.com/11notes/docker-distroless/blob/master/upx.dockerfile) - upx
* [11notes/distroless:pv](https://github.com/11notes/docker-distroless/blob/master/pv.dockerfile) - pv
* [11notes/distroless:dnspyre](https://github.com/11notes/docker-distroless/blob/master/dnspyre.dockerfile) - dnspyre
* [11notes/distroless:localhealth](https://github.com/11notes/docker-distroless/blob/master/localhealth.dockerfile) - localhealth
* [11notes/distroless:jq](https://github.com/11notes/docker-distroless/blob/master/jq.dockerfile) - jq

# CONTAINER ENTRYPOINTS
* [11notes/distroless:tini](https://github.com/11notes/docker-distroless/blob/master/tini.dockerfile) - tini
* [11notes/distroless:tini-pm](https://github.com/11notes/go-tini-pm) - tini-pm

# CONTAINER HELPERS
* [11notes/distroless:cmd-socket](https://github.com/11notes/go-cmd-socket) - cmd-socket

There are also application services, that are distroless, but don’t serve well as a base layer or only for people who know how to handle them, these are:

# APPLICATION SERVICES WITH THEIR OWN IMAGES
* [11notes/socket-proxy](https://github.com/11notes/docker-socket-proxy) - socket-proxy
* [11notes/node](https://github.com/11notes/docker-node) - node
* [11notes/adguard](https://github.com/11notes/docker-adguard) - adguard
* [11notes/adguard-sync](https://github.com/11notes/docker-adguard-sync) - adguard-sync
* [11notes/nginx](https://github.com/11notes/docker-nginx) - nginx
* [11notes/traefik](https://github.com/11notes/docker-traefik) - traefik
* [11notes/hysteria](https://github.com/11notes/docker-hysteria) - hysteria
* [11notes/chrony](https://github.com/11notes/docker-chrony) - chrony
* [11notes/netbird](https://github.com/11notes/docker-netbird) - netbird
* [11notes/pocket-id](https://github.com/11notes/docker-pocket-id) - pocket-id
* [11notes/unbound](https://github.com/11notes/docker-unbound) - unbound
* [11notes/caddy](https://github.com/11notes/docker-caddy) - caddy
* [11notes/qbittorrent](https://github.com/11notes/docker-qbittorrent) - qbittorrent
* [11notes/tinyauth](https://github.com/11notes/docker-tinyauth) - tinyauth
* [11notes/redis](https://github.com/11notes/docker-redis) - redis

# BUILD 🚧
```yaml
# this will create a distroless image that just contains the curl binary
FROM 11notes/distroless:curl AS distroless-curl
FROM scratch
COPY --from=distroless-curl / /
USER docker
ENTRYPOINT ["/usr/local/bin/curl"]
```

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [latest](https://hub.docker.com/r/11notes/distroless/tags?name=latest)

# REGISTRIES ☁️
```
docker pull 11notes/distroless:latest
docker pull ghcr.io/11notes/distroless:latest
docker pull quay.io/11notes/distroless:latest
```

# SOURCE 💾
* [11notes/distroless](https://github.com/11notes/docker-DISTROLESS)

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-distroless/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-distroless/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-distroless/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 16.09.2025, 03:00:37 (CET)*