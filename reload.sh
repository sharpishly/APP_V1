#!/bin/bash

docker compose exec nginx nginx -t
docker compose exec nginx nginx -s reload