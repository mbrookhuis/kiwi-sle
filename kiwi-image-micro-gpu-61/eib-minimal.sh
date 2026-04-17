#!/bin/bash

if ! [ -f $PWD/eib-minimal/base-images/SL-Micro.aarch64-6.1-Base-SelfInstall-GM.install.iso ]; then
	mkdir -p $PWD/eib-minimal/base-images
	cp -av /srv/www/htdocs/isos/slmicro60/SL-Micro.aarch64-6.1-Base-SelfInstall-GM.install.iso $PWD/eib-minimal/base-images
fi
podman run \
	--rm --privileged \
	-v $PWD/eib-minimal:/eib \
	registry.opensuse.org/isv/suse/edge/edgeimagebuilder/containerfile-sp6/suse/edge-image-builder:1.1.0 \
	build --definition-file=eib.yaml
