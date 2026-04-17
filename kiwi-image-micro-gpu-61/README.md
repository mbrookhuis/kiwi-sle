Steps required:

- run eib.sh to generate combustion drive content
  see https://github.com/suse-edge/edge-image-builder/blob/main/docs/generating-combustion-drive.md
  hint: EIB requires the combustion partition to be labeled "install" and there is a challenge with ro mount - so modified the script that eib creates a bit
- run build-x86.sh to build the image with included combustion
- run eib-kiwi-kvm-01.sh to launch a kvm VM with the image
