#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg >/dev/null 2>&1; then
  echo "The 1Password APT repository can only be enabled on Debian-family systems." >&2
  exit 1
fi

architecture="$(dpkg --print-architecture)"
if [[ "$architecture" != "amd64" ]]; then
  echo "1Password's APT repository setup currently supports amd64; got $architecture." >&2
  exit 1
fi

source_file="/etc/apt/sources.list.d/1password.list"
keyring_file="/usr/share/keyrings/1password-archive-keyring.gpg"
policy_file="/etc/debsig/policies/AC2D62742012EA22/1password.pol"
debsig_key="/usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg"

if [[ -f "$source_file" ]] && grep -qF "downloads.1password.com/linux/debian/$architecture" "$source_file" \
  && [[ -f "$keyring_file" && -f "$policy_file" && -f "$debsig_key" ]]; then
  echo "The 1Password APT repository is already configured."
  exit 0
fi

run_privileged() {
  if ((EUID == 0)); then
    "$@"
  else
    sudo "$@"
  fi
}

temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

curl --fail --location --retry 3 \
  https://downloads.1password.com/linux/keys/1password.asc \
  --output "$temporary_directory/1password.asc"
gpg --batch --yes --dearmor \
  --output "$temporary_directory/1password.gpg" \
  "$temporary_directory/1password.asc"
curl --fail --location --retry 3 \
  https://downloads.1password.com/linux/debian/debsig/1password.pol \
  --output "$temporary_directory/1password.pol"

printf 'deb [arch=%s signed-by=%s] https://downloads.1password.com/linux/debian/%s stable main\n' \
  "$architecture" "$keyring_file" "$architecture" >"$temporary_directory/1password.list"

run_privileged install -D -m 0644 "$temporary_directory/1password.gpg" "$keyring_file"
run_privileged install -D -m 0644 "$temporary_directory/1password.pol" "$policy_file"
run_privileged install -D -m 0644 "$temporary_directory/1password.gpg" "$debsig_key"
run_privileged install -D -m 0644 "$temporary_directory/1password.list" "$source_file"
