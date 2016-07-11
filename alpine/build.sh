#!/usr/bin/env bash
docker build --rm=true --force-rm -t nexbit/openresty-alpine .
docker build --rm=true --force-rm -t nexbit/openresty-alpine:onbuild ./onbuild
