# OpenResty Docker image

This repository contains Dockerfiles for [nexbit/openresty](https://hub.docker.com/r/nexbit/openresty/) image, which has two flavors.

The alpine version is an updated version of the [ficusio/openresty](https://github.com/ficusio/openresty) one, but it isn't actively maintained.

The debian version is the result of a merge between [ficusio/openresty](https://github.com/ficusio/openresty) and [openresty/docker-openresty](https://github.com/openresty/docker-openresty), and it is the recommended flavor to use if you want an updated OpenResty setup based on latest debian:jessie.

### Flavors

The first one is [Alpine linux](https://hub.docker.com/_/alpine/)-based `nexbit/openresty:alpine`. Its virtual size is just 31MB, yet it contains a fully functional [OpenResty](http://openresty.org) bundle v1.9.15.1 and [`apk` package manager](http://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management), which allows you to easily install [lots of  pre-built packages](https://pkgs.alpinelinux.org/packages).

The other flavor is `nexbit/openresty`, and it is the recommended variant. It is based on `debian:jessie` and even if much bigger in size, it is a full fledged OpenResty 1.9.15.1 installation with custom compiled OpenSSL 1.0.2h, PCRE 8.38, and LuaRocks 2.3.0.

### Paths & config

NginX is configured with `/opt/openresty/nginx` [prefix path](http://nginx.org/en/docs/configure.html), which means that, by default, it loads configuration from `/opt/openresty/nginx/conf/nginx.conf` file. The default HTML root path is `/opt/openresty/nginx/html/`.

OpenResty bundle includes several useful Lua modules located in `/opt/openresty/lualib/` directory. This directory is already present in Lua package path, so you don't need to specify it in NginX `lua_package_path` directive.

The Lua NginX module is built with LuaJIT 2.1, which is also available as stand-alone `lua` binary.

NginX stores various temporary files in `/var/nginx/` directory. If you wish to launch the container in [read-only mode](https://github.com/docker/docker/pull/10093), you need to convert that directory into volume to make it writable:

```sh
# To launch container
docker run --name nginx --read-only -v /var/nginx ... nexbit/openresty

# To remove container and its volume
docker rm -v nginx
```

See [this PR](https://github.com/ficusio/openresty/pull/7) for background.

### `ONBUILD` variant

The `*:onbuild` image variants use [`ONBUILD` hooks](http://docs.docker.com/engine/reference/builder/#onbuild) that automatically copies all files and subdirectories from the `nginx/` directory located at the root of Docker build context (i.e. next to your `Dockerfile`) into `/opt/openresty/nginx/`. The minimal configuration needed to get NginX running is the following:

```coffee
project_root/
 ├ nginx/ # all subdirs/files will be copied to /opt/openresty/nginx/
 |  └ conf/
 |     └ nginx.conf # your NginX configuration file
 └ Dockerfile
```

Dockerfile:

```dockerfile
FROM nexbit/openresty
EXPOSE 8080
```

Check [the sample application](https://github.com/nexbit/openresty/tree/master/_example) for more useful example.

### Command-line parameters

NginX is launched with the `nginx -g 'daemon off; error_log /dev/stderr error;'` command. This means that you should not specify the `daemon` directive in your `nginx.conf` file, because it will lead to NginX config check error (duplicate directive).

No-daemon mode is needed to allow host OS' service manager, like `systemd`, or [Docker itself](http://docs.docker.com/engine/reference/commandline/cli/#restart-policies) to detect that NginX has exited and restart the container. Otherwise in-container service manager would be required.

Error log is redirected to `stderr` to simplify debugging and log collection with [Docker logging drivers](https://docs.docker.com/engine/reference/logging/overview/) or tools like [logspout](https://github.com/gliderlabs/logspout).

The Dockerfiles uses the `ENTRYPOINT` directive to run nginx, and thus if you want to override the default command you must use the `--entrypoint` flag of `docker run` command (albeit not supported nor recommended):

```text
$ docker run --entrypoint <your command> nexbit/openresty
```

If you only want to add other parameters to the `nginx` command, you can simply add a `CMD` directive with the additional parameters (remember that you must use the `exec` form and not the `shell` one, or the resulting command won't be correct).

### Usage during development

To avoid rebuilding your Docker image after each modification of Lua code or NginX config, you can add a simple script that mounts config/content directories to appropriate locations and starts NginX:

```bash
#!/usr/bin/env bash

exec docker run --rm -it \
  --name my-app-dev \
  -v "$(pwd)/nginx/conf":/opt/openresty/nginx/conf \
  -v "$(pwd)/nginx/lualib":/opt/openresty/nginx/lualib \
  -p 8080:8080 \
  nexbit/openresty "$@"

# you may add more -v options to mount another directories, e.g. nginx/html/

# do not do -v "$(pwd)/nginx":/opt/openresty/nginx because it will hide
# the NginX binary located at /opt/openresty/nginx/sbin/nginx
```

Place it next to your `Dockerfile`, make executable and use during development. You may also want to temporarily disable [Lua code cache](https://github.com/openresty/lua-nginx-module#lua_code_cache) to allow testing code modifications without re-starting NginX.
