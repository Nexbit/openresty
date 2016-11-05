#!/usr/bin/env bash
docker build --rm=true --force-rm -t nexbit/openresty . && \
docker build --rm=true --force-rm -t nexbit/openresty:onbuild ./onbuild
