#!/bin/bash
set -euo pipefail

mount /var
touch /var/lib/reencrypt_system
umount /var

systemctl enable fde-reencrypt-and-grow.service || true
