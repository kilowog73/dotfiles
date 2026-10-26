#!/usr/bin/env bash
set -euo pipefail

if command -v tailscale >/dev/null 2>&1; then
  echo "Tailscale is already installed."
  exit 0
fi

temporary_installer="$(mktemp)"
trap 'rm -f "$temporary_installer"' EXIT
curl --fail --location --retry 3 https://tailscale.com/install.sh --output "$temporary_installer"
bash "$temporary_installer"
