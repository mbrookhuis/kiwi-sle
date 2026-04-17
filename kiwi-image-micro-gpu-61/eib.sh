#!/bin/bash
podman run \
	--rm --privileged \
	-v $PWD/eib:/eib \
	registry.suse.com/edge/3.4/edge-image-builder:1.3.0 \
	generate \
	--definition-file eib.yaml \
	--output-type tar \
	--output eib.tar \
	--arch aarch64
rm -rf root
mkdir -p root/oem
tar xvf eib/eib.tar -C root/oem
rm eib/eib.tar
#xorriso -osirrox on -indev eib/combustion.iso extract / root/oem

# workaround for mount problem - eib looks for "install" but combustion looks for "combustion"
sed -i 's/INSTALL/COMBUSTION/g' root/oem/combustion/script
# workaround for rw mount in fstab but ro mount in eib combustion script
sed -i 's/-o ro//g' root/oem/combustion/script

