#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
dry_run=false

case "${1:-}" in
  "") ;;
  --dry-run) dry_run=true ;;
  --help)
    echo "Usage: $0 [--dry-run]"
    echo "--dry-run resolves DNF packages without installing them (Fedora only)."
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
    ;;
esac

get_profile() {
  local profile="${DOTFILES_PROFILE:-}"

  if [[ -z "$profile" ]]; then
    if ! command -v chezmoi >/dev/null 2>&1; then
      echo "chezmoi must be initialized, or DOTFILES_PROFILE must be set to home/work." >&2
      return 1
    fi
    profile="$(chezmoi execute-template '{{ .profile }}')"
  fi

  if [[ "$profile" != "home" && "$profile" != "work" ]]; then
    echo "Invalid DOTFILES_PROFILE '$profile'; expected home or work." >&2
    return 1
  fi

  printf '%s\n' "$profile"
}

if [[ -n "${MSYSTEM:-}" ]] && command -v pacman >/dev/null 2>&1; then
  if "$dry_run"; then
    echo "--dry-run is currently supported only for Fedora/DNF." >&2
    exit 2
  fi
  if [[ "$MSYSTEM" != "UCRT64" ]]; then
    echo "Open the MSYS2 UCRT64 terminal, update MSYS2, then rerun this script." >&2
    exit 1
  fi
  profile="$(get_profile)"

  packages=(
    zsh git curl unzip zsh-syntax-highlighting
    mingw-w64-ucrt-x86_64-eza
    mingw-w64-ucrt-x86_64-fastfetch
    mingw-w64-ucrt-x86_64-fd
    mingw-w64-ucrt-x86_64-fzf
    mingw-w64-ucrt-x86_64-github-cli
    mingw-w64-ucrt-x86_64-neovim
    mingw-w64-ucrt-x86_64-nodejs
    mingw-w64-ucrt-x86_64-ripgrep
    mingw-w64-ucrt-x86_64-starship
    mingw-w64-ucrt-x86_64-tmux
    mingw-w64-ucrt-x86_64-zoxide
  )
  if [[ "$profile" == "home" ]]; then
    packages+=(mingw-w64-ucrt-x86_64-uv)
  fi
  available_packages=()
  for package in "${packages[@]}"; do
    if pacman -Si "$package" >/dev/null 2>&1; then
      available_packages+=("$package")
    else
      echo "Skipping unavailable MSYS2 package: $package" >&2
    fi
  done
  if ((${#available_packages[@]})); then
    pacman -S --needed "${available_packages[@]}"
  fi
  if [[ "$profile" == "home" ]]; then
    if ! command -v winget.exe >/dev/null 2>&1; then
      echo "winget.exe is required to install 1Password and Tailscale on Windows." >&2
      exit 1
    fi
    for package_id in AgileBits.1Password AgileBits.1Password.CLI Tailscale.Tailscale; do
      if winget.exe list --id "$package_id" --exact --accept-source-agreements 2>/dev/null \
        | tr -d '\r' | grep -Fqi "$package_id"; then
        echo "$package_id is already installed."
      else
        winget.exe install --id "$package_id" --exact \
          --accept-source-agreements --accept-package-agreements
      fi
    done
    "$repo_root/scripts/install-opencode.sh"
  fi
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass \
    -File "$(cygpath -w "$repo_root/scripts/install-comic-shanns-font-windows.ps1")"
  exit
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  if "$dry_run"; then
    echo "--dry-run is currently supported only for Fedora/DNF." >&2
    exit 2
  fi
  profile="$(get_profile)"
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required on macOS. Install it, then rerun this script." >&2
    exit 1
  fi
  DOTFILES_PROFILE="$profile" brew bundle --file "$repo_root/Brewfile"
  exit
fi

if command -v dnf >/dev/null 2>&1; then
  profile="$(get_profile)"
  packages=(
    zsh git curl fontconfig gcc make eza fastfetch fd-find fzf gh ghostscript ghostty ImageMagick mc
    neovim nodejs pandoc ripgrep ruby starship tmux tree wget zoxide zsh-syntax-highlighting
  )
  if [[ "$profile" == "home" ]]; then
    packages+=(tailscale 1password-cli uv)
    if [[ -d /run/systemd/system ]]; then
      packages+=(1password)
    else
      echo "Skipping the 1Password desktop app: systemd is unavailable in this environment; installing its CLI only."
    fi
  fi
  if ((EUID == 0)) || "$dry_run"; then
    dnf_command=(dnf)
  else
    dnf_command=(sudo dnf)
  fi
  if "$dry_run"; then
    if [[ "$profile" == "home" ]] && ! dnf repolist --enabled | awk 'tolower($1) == "1password" { found = 1 } END { exit !found }'; then
      echo "The 1Password RPM repository is not enabled. Run scripts/enable-1password-rpm.sh, then retry the dry run." >&2
      exit 2
    fi
    if output="$("${dnf_command[@]}" install --assumeno --skip-unavailable "${packages[@]}" 2>&1)"; then
      printf '%s\n' "$output"
    else
      status=$?
      printf '%s\n' "$output"
      if ((status == 1)) && grep -Fq "Operation aborted by the user" <<<"$output"; then
        echo "Dry run complete: the transaction resolved; no packages were installed."
        exit 0
      fi
      exit "$status"
    fi
  else
    if [[ "$profile" == "home" ]]; then
      "$repo_root/scripts/enable-1password-rpm.sh"
    fi
    "${dnf_command[@]}" install -y --skip-unavailable "${packages[@]}"
    "$repo_root/scripts/install-comic-shanns-font.sh"
    if [[ "$profile" == "home" ]]; then
      "$repo_root/scripts/install-opencode.sh"
    fi
    if [[ -n "${WSL_INTEROP:-}${WSL_DISTRO_NAME:-}" ]]; then
      powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass \
        -File "$(wslpath -w "$repo_root/scripts/install-comic-shanns-font-windows.ps1")"
    fi
  fi
  exit
fi

if "$dry_run"; then
  echo "--dry-run is currently supported only for Fedora/DNF." >&2
  exit 2
fi

if command -v apt-get >/dev/null 2>&1; then
  profile="$(get_profile)"
  sudo apt-get update
  packages=(
    zsh git curl fontconfig eza fd-find fzf gh ghostscript imagemagick mc neovim nodejs \
    pandoc ripgrep ruby starship tmux tree wget zoxide zsh-syntax-highlighting
  )
  if apt-cache show fastfetch >/dev/null 2>&1; then
    packages+=(fastfetch)
  else
    echo "Fastfetch isn't available in the configured APT repositories; skipping it." >&2
  fi
  sudo apt-get install -y "${packages[@]}"
  if [[ "$profile" == "home" ]]; then
    sudo apt-get install -y gnupg
    "$repo_root/scripts/enable-1password-deb.sh"
    sudo apt-get update
    sudo apt-get install -y 1password-cli
    if [[ -d /run/systemd/system ]]; then
      sudo apt-get install -y 1password
    else
      echo "Skipping the 1Password desktop app: systemd is unavailable in this environment; installing its CLI only."
    fi
    "$repo_root/scripts/install-tailscale-linux.sh"
    "$repo_root/scripts/install-uv.sh"
    "$repo_root/scripts/install-opencode.sh"
  fi
  "$repo_root/scripts/install-comic-shanns-font.sh"
  if [[ -n "${WSL_INTEROP:-}${WSL_DISTRO_NAME:-}" ]]; then
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass \
      -File "$(wslpath -w "$repo_root/scripts/install-comic-shanns-font-windows.ps1")"
  fi
  exit
fi

echo "Unsupported platform or package manager. No packages were installed." >&2
exit 1
