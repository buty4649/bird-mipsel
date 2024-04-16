#!/bin/bash

set -x
docker buildx build -t bird-mipsel .
docker run --rm -v $(pwd):/mnt bird-mipsel bash -c 'cp /bird-*-mipsel.tar.gz /mnt'
