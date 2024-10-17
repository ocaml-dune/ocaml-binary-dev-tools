#!/bin/sh
set -eu

url="$1"
tmp_dir=$(mktemp -d)
trap 'rm -r "$tmp_dir"' EXIT
wget -P "$tmp_dir" "$url"
file=$(find "$tmp_dir" -type f | head -n1)
sha256=$(sha256sum "$file" | cut -f1 -d' ')
sha512=$(sha512sum "$file" | cut -f1 -d' ')
cat <<EOF
url {
  src: "$url"
  checksum: [
    "sha256=$sha256"
    "sha512=$sha512"
  ]
}
EOF
