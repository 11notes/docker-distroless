${{ content_synopsis }} This image and its different layers can be used to build a distroless boiler plate for your application. Simply add the base layer and any additional layers (tags) with the stuff you need to run your application. The base layer containers Root CA certificates as well as time zone data and the user configuration for root and docker. Additional layers (tags) are:

* [11notes/distroless:curl](https://github.com/11notes/docker-distroless/blob/master/curl.dockerfile) - curl

${{ content_build }}

${{ content_source }}