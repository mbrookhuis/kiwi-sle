#!/bin/bash

if [ "$(hostname)" == "ip-10-1-0-96" ]; then
	echo krones; 
	SUSEMANAGER=10.1.0.96
	LIFECYCLE=slmicro61-test
	DISTRIBUTION=slmicro61-test
else 
	echo not krones;
	SUSEMANAGER=susemanager.weiss.ddnss.de
	LIFECYCLE=staging-slmicro61-test
	DISTRIBUTION=slmicro61-test
fi

# set variables
TARGET_DIR=.
#PROFILE="aarch64-self_install"
#PROFILE="aarch64-self_install-gpu"
#PROFILE="x86-self_install"
PROFILE="x86-rt-self_install"
KIWI_IMAGE="registry.suse.com/bci/kiwi:10.1.10"

# clean and recreate the build folder
rm -rf $TARGET_DIR/image
mkdir -p $TARGET_DIR/image

# build the image

mkdir -p ./repo
wget http://$SUSEMANAGER/pub/rhn-org-trusted-ssl-cert-osimage-1.0-1.noarch.rpm -O ./repo/rhn-org-trusted-ssl-cert-osimage-1.0-1.noarch.rpm

podman run --privileged \
-v /var/lib/ca-certificates:/var/lib/ca-certificates \
-v ./repo:/var/lib/Kiwi/repo \
-v $TARGET_DIR/kiwi.yml:/etc/kiwi.yml \
-v $TARGET_DIR:/image:Z \
$KIWI_IMAGE kiwi-ng \
--profile $PROFILE \
system build \
--allow-existing-root \
--description /image \
--target-dir /image/image \
--ignore-repos-used-for-build \
--add-repo file:/var/lib/Kiwi/repo,rpm-dir,common_repo,90,false,false \
--add-bootstrap-package findutils \
--add-bootstrap-package rhn-org-trusted-ssl-cert-osimage-1.0-1 \
--add-repo http://$SUSEMANAGER/ks/dist/child/$LIFECYCLE-sl-micro-6.1-pool-x86_64-clone/$DISTRIBUTION \
--add-repo http://$SUSEMANAGER/ks/dist/child/$LIFECYCLE-sl-micro-extras-6.1-pool-x86_64/$DISTRIBUTION \
--add-repo http://$SUSEMANAGER/ks/dist/child/$LIFECYCLE-suse-manager-tools-for-sl-micro-6.1-x86_64/$DISTRIBUTION,repo-md,suse-manager-tools-for-sl-micro-6.1-x86_64
exit

# not required for iso building.. 
rm -rf $TARGET_DIR/image-bundle
mkdir -p $TARGET_DIR/image-bundle
podman run --privileged -v $TARGET_DIR:/image:Z registry.suse.com/bci/kiwi:10.1.10 kiwi-ng result bundle --target-dir /image/image --bundle-dir=/image/image-bundle --id=0
