#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq nixfmt gnused coreutils gnugrep nix
set -euo pipefail

# based on pkgs/by-name/sp/spotify/update.sh

nix_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/default.nix"
binaries=("vhclientx86_64" "vhclientarm64")
any_updated=false

update_binary() {
  local binary_name="$1"
  local upstream_url="https://www.virtualhere.com/sites/default/files/usbclient/${binary_name}"

  local url_line_num
  url_line_num=$(grep -n "usbclient/${binary_name}" "$nix_file" | head -1 | cut -d: -f1)
  local hash_line_num=$((url_line_num + 1))

  local current_url current_hash
  current_url=$(sed -n "${url_line_num}p" "$nix_file" | sed -E 's/.*"([^"]+)".*/\1/')
  current_hash=$(sed -n "${hash_line_num}p" "$nix_file" | sed -E 's/.*"([^"]+)".*/\1/')

  echo "$binary_name: checking upstream..."
  local upstream_hash
  upstream_hash=$(nix store prefetch-file "$upstream_url" --json | jq -r .hash)

  if [[ "$current_url" == *"web.archive.org"* ]]; then
    echo "$binary_name: verifying current archive.org URL..."
    local archive_hash
    archive_hash=$(nix store prefetch-file "$current_url" --json | jq -r .hash)

    if [ "$archive_hash" = "$upstream_hash" ]; then
      echo "$binary_name: already up-to-date (archive.org matches upstream: $upstream_hash)"
      return
    fi

    echo "$binary_name: upstream changed (archive: $archive_hash, upstream: $upstream_hash)"
  fi

  echo "$binary_name: saving to archive.org..."
  local archived_url
  archived_url=$(curl -s -I -L -o /dev/null -w '%{url_effective}' "https://web.archive.org/save/${upstream_url}")

  if [[ "$archived_url" != *"web.archive.org"* ]]; then
    echo "$binary_name: ERROR - archive.org save failed (got: $archived_url)"
    return 1
  fi

  # Convert to raw/identity URL (no archive.org toolbar/rewriting)
  local timestamp
  timestamp=$(echo "$archived_url" | grep -oP '/web/\K\d+')
  local final_url="https://web.archive.org/web/${timestamp}id_/${upstream_url}"

  echo "$binary_name: archived at $final_url"

  local final_hash
  final_hash=$(nix store prefetch-file "$final_url" --json | jq -r .hash)

  sed --regexp-extended \
    -i "${url_line_num}s|url = \".*\";|url = \"${final_url}\";|" "$nix_file"
  sed --regexp-extended \
    -i "${hash_line_num}s|hash = \".*\";|hash = \"${final_hash}\";|" "$nix_file"

  echo "$binary_name: updated (hash: ${final_hash})"
  any_updated=true
}

for bin in "${binaries[@]}"; do
  update_binary "$bin"
done

if [ "$any_updated" = true ]; then
  today=$(date +%Y-%m-%d)
  sed --regexp-extended \
    -i 's/version = ".*";/version = "unstable-'"${today}"'";/' "$nix_file"
  nixfmt "$nix_file"
  echo "virtualhere-client-cli: updated to unstable-${today}"
else
  echo "virtualhere-client-cli: no changes"
fi
