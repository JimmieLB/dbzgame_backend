#!/bin/sh
echo -ne '\033c\033]0;brawls_backend\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/linux_dist.x86_64" "$@"
