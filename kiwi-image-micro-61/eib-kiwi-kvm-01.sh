#!/bin/bash
HOSTNAME=eib-kiwi-kvm-01
MAC_ADDRESS1="34:8c:b1:4b:16:ff"

if [ "$1" == "" ]; then
	if virsh domstate $HOSTNAME >> /dev/null 2>&1 ; then
			echo "VM is already running"
	else
		virt-install \
			--connect qemu:///system --virt-type kvm  \
			--name $HOSTNAME \
			--memory 4096 \
			--vcpus 4 \
			--network bridge=br0,mac=$MAC_ADDRESS1 \
			--graphics vnc \
			--cdrom https://susemanager.weiss.ddnss.de/os-images/1/SL-Micro-6.0.0-6/SL-Micro.x86_64-6.0.0.install.iso \
			--disk bus=scsi,pool=images-nvme3,size=50,sparse=true \
			--osinfo slem6.0 \
			--boot uefi,loader_secure=yes \
			--check path_in_use=off \
			--sysinfo system.serial=27731BFF
	fi
fi

if [ "$1" == "rm" ]; then
	sudo virsh destroy $HOSTNAME
	sudo virsh undefine $HOSTNAME --nvram
	sudo rm /srv/kvm/images-nvme3/$HOSTNAME.qcow2
fi
