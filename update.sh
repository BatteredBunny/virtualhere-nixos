#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/pkgs/virtualhere-client-cli/update.sh"
"$SCRIPT_DIR/pkgs/virtualhere-client-gui/update.sh"
