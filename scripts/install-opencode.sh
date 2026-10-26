#!/usr/bin/env bash
set -euo pipefail

temporary_installer="$(mktemp)"
trap 'rm -f "$temporary_installer"' EXIT
curl --fail --location --retry 3 https://opencode.ai/v2/install --output "$temporary_installer"
PATH="$HOME/.opencode/bin:$PATH" bash "$temporary_installer" --no-modify-path
