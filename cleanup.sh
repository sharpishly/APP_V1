#!/bin/bash
docker-compose down
docker ps -a -q | xargs docker rm -f
docker images -q | sort -u | xargs docker rmi -f