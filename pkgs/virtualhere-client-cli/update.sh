#!/usr/bin/env nix-shell
#! nix-shell -i bash -p python3 nixfmt nix
set -euo pipefail

exec python3 "$(dirname "${BASH_SOURCE[0]}")/../update-client.py" cli "$@"
