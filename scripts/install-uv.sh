#!/usr/bin/env bash
set -euo pipefail

if command -v uvx >/dev/null 2>&1; then
  echo "uvx is already available."
  exit 0
fi

temporary_installer="$(mktemp)"
trap 'rm -f "$temporary_installer"' EXIT
curl --fail --location --retry 3 https://astral.sh/uv/install.sh --output "$temporary_installer"
UV_NO_MODIFY_PATH=1 sh "$temporary_installer"
