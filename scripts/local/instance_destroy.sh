#!/usr/bin/env bash
docker-compose stop
docker-compose kill
docker-compose rm -v --force
