#!/usr/bin/env bash
docker pull $1
docker-compose build
docker-compose up -d
chmod -R g+w tests/
docker-compose logs -f
