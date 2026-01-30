#!/bin/bash
podman run \
	--rm --privileged \
	-v $PWD/eib:/eib \
	docker.io/dgiebert/edge-image-builder:1.2.8 \
	build --definition-file=eib.yaml
rm -rf root
mkdir -p root/oem
xorriso -osirrox on -indev eib/combustion.iso extract / root/oem
