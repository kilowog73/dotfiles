#!/usr/bin/env bash
set -euo pipefail

if ! command -v dnf >/dev/null 2>&1 || ! command -v rpm >/dev/null 2>&1; then
  echo "Terra can only be enabled on Fedora-family systems with DNF and RPM." >&2
  exit 1
fi

if dnf repolist --enabled | awk 'tolower($1) == "terra" { found = 1 } END { exit !found }'; then
  echo "The Terra repository is already enabled."
  exit 0
fi

if ((EUID == 0)); then
  dnf_command=(dnf)
else
  dnf_command=(sudo dnf)
fi

# Terra's documented bootstrap uses --nogpgcheck only for the initial release
# RPM; terra-gpg-keys installs the signing key used for subsequent packages.
terra_repo='terra,https://repos.fyralabs.com/terra$releasever'
"${dnf_command[@]}" install -y --nogpgcheck --repofrompath "$terra_repo" terra-release terra-gpg-keys
