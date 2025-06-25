${{ content_synopsis }} This image and its different layers can be used to build a distroless boiler plate for your application. Simply add the base layer and any additional layers (tags) with the stuff you need to run your application. All binaries are statically compiled and do not depend on any OS libraries or clib. The base layer contains Root CA certificates as well as time zone data and the user configuration for root and docker. Additional layers (tags) with statically compiled binaries are:

# STAND-ALONE BINARIES
* [11notes/distroless:curl](https://github.com/11notes/docker-distroless/blob/master/curl.dockerfile) - curl
* [11notes/distroless:dnslookup](https://github.com/11notes/docker-distroless/blob/master/dnslookup.dockerfile) - dnslookup
* [11notes/distroless:lego](https://github.com/11notes/docker-distroless/blob/master/lego.dockerfile) - lego
* [11notes/distroless:par2](https://github.com/11notes/docker-distroless/blob/master/par2.dockerfile) - par2
* [11notes/distroless:unrar](https://github.com/11notes/docker-distroless/blob/master/unrar.dockerfile) - unrar

# CONTAINER ENTRYPOINTS
* [11notes/distroless:tini-pm](https://github.com/11notes/go-tini-pm) - tini-pm

# CONTAINER HELPERS
* [11notes/distroless:cmd-socket](https://github.com/11notes/go-cmd-socket) - cmd-socket

# APPLICATION SERVICES
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

Each tag has sub tags like latest, stable or semver, check the tags available for each binary. If you need more binaries, open a PR or feature request. Some of the images have their own dedicated container images to run the applications within, simply check the link for the source and explanation on how to use them.

**These images are meant as base layers for your own images!** If you want to use adguard for instance, use [11notes/adguard](https://github.com/11notes/docker-adguard) instead!

${{ content_build }}

${{ content_source }}