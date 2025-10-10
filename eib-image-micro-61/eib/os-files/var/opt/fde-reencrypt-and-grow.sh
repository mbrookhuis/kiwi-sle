#!/bin/bash
#
#   Copyright (C) 2024 SUSE LLC
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#   Written by Jiri Srain <jsrain@suse.com>
#   Extended by Dominic Giebert <dgiebert@suse.com>

. /etc/sysconfig/fde-tools

. /usr/share/fde/util
. /usr/share/fde/luks
. /usr/share/fde/tpm
. /usr/share/fde/uefi
. /usr/share/fde/grub2

# dialog functions that use the firstboot plumbing
. /usr/share/fde/ui/shell

##################################################################
# Values and locations used by KIWI
##################################################################
KIWI_ROOT_KEYFILE=/root/.root.keyfile
FDE_LUKS_PBKDF=pbkdf2

echo "Analyzing the system..."
luks_name=$(expr "$(df --output=source / | grep /dev/)" : ".*/\(.*\)")

luks_dev=$(luks_get_underlying_device "$luks_name")
if [ -z "$luks_dev" ]; then
  display_errorbox "Unable to determine underlying LUKS device for $root_dev"
  exit 1
fi

# sort assures that the device (which is shorter) is before partitions on the first line
system_disk=$(lsblk -no pkname $luks_dev | sort | head -n1)
system_disk="/dev/$system_disk"
part_num=$(echo "$luks_dev" | grep -Eo '[0-9]+$')

echo "LUKS device for root filesystem: $luks_name"
echo "Underlying device holding the LUKS partition: $luks_dev"
echo "System disk: $system_disk"
echo "Partition number: $part_num"

if [ -e "${KIWI_ROOT_KEYFILE}" ]; then
  echo "Removing the initial kiwi key file"
  if ! cryptsetup luksRemoveKey "${luks_dev}" ${KIWI_ROOT_KEYFILE}; then
    display_errorbox "Failed to remove initial random key"
    exit 1
  fi
  rm -f ${KIWI_ROOT_KEYFILE}
fi

echo "Generating a new random password"
luks_old_password="1234"
#result_password="12345" # $(openssl rand -hex 12)
result_password=$(openssl rand -hex 12)

old_keyfile=$(luks_write_password oldpass "${luks_old_password}")
new_keyfile=$(luks_write_password newpass "${result_password}")
if ! luks_set_password "${luks_dev}" "${old_keyfile}" "${new_keyfile}"; then
  echo "Failed to replace the recovery password"
  rm -f ${new_keyfile} ${old_keyfile}
  exit 1
fi

rm -f ${old_keyfile}

echo "Reencrypting the device"
if ! cryptsetup reencrypt --key-file "${new_keyfile}" ${luks_dev}; then
  echo "Failed to reencrypt the device ${luks_dev}"
  rm -f ${new_keyfile}
  exit 1
fi

echo "Sealing with TPM"
if ! fdectl regenerate-key --passfile "${new_keyfile}"; then
  echo "Failed to seal the new key with TPM"
  rm -f ${new_keyfile}
  exit 1
fi

echo "Expanding partition $part_num on disk $system_disk"
if ! growpart $system_disk $part_num; then
  echo "Failed to grow the partition to full device size"
  rm -f ${new_keyfile}
  exit 1
fi

echo "Expanding the encrypted LUKS partition ..."
if ! cryptsetup resize --key-file ${new_keyfile} /dev/mapper/luks; then
  echo "Failed to expand LUKS. It will automatically resize on next reboot"
  rm -f ${new_keyfile}
  exit 1
fi

rm -f ${new_keyfile}

echo "Expanding the filesystem..."
if ! btrfs filesystem resize max /root; then
  echo "Failed to expand the filesystem to full size of the disk"
  exit 1
fi

echo "Updating the bootloader configuration"
if ! transactional-update initrd grub.cfg --continue && transactional-update apply; then
  echo "Failed to update the bootloader"
  exit 1
fi
