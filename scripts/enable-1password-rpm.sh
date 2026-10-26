#!/usr/bin/env bash
set -euo pipefail

if ! command -v dnf >/dev/null 2>&1 || ! command -v rpm >/dev/null 2>&1; then
  echo "The 1Password RPM repository can only be enabled on Fedora-family systems." >&2
  exit 1
fi

if dnf repolist --enabled | awk 'tolower($1) == "1password" { found = 1 } END { exit !found }'; then
  echo "The 1Password RPM repository is already enabled."
  exit 0
fi

temporary_repo="$(mktemp)"
trap 'rm -f "$temporary_repo"' EXIT
cat >"$temporary_repo" <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

if ((EUID == 0)); then
  rpm --import https://downloads.1password.com/linux/keys/1password.asc
  install -D -m 0644 "$temporary_repo" /etc/yum.repos.d/1password.repo
else
  sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
  sudo install -D -m 0644 "$temporary_repo" /etc/yum.repos.d/1password.repo
fi
