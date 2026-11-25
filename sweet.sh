#!/bin/bash
set -euo pipefail

if [ -n "${BASH_SOURCE[0]:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/sync.sh" ]; then
        exec bash "$SCRIPT_DIR/sync.sh" sweet "$@"
    fi
fi

curl -fsSL "https://raw.githubusercontent.com/RapStuff/local_manifest/refs/heads/main/sync.sh" | bash -s -- sweet "$@"
