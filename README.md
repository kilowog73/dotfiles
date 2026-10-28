# Dotfiles

Cross-platform configuration managed with [chezmoi](https://www.chezmoi.io/).
The `home/` directory is the chezmoi source state; the rest of this repository
contains setup scripts and platform package manifests.

## First-time setup

1. Install chezmoi for the current operating system.
2. Run `chezmoi init https://github.com/kilowog73/dotfiles.git`; on first
   initialization, choose the `home` or `work` profile.
3. Review the proposed changes with `chezmoi diff`, then apply them with
   `chezmoi apply`.
4. On standard Fedora, explicitly enable Terra once with
   `cd "$(chezmoi source-path)" && ./scripts/enable-terra.sh`. Nobara already
   enables Terra, so the script detects the enabled repository and does nothing.
5. To install packages, explicitly run the installer after reviewing its
   package list: `cd "$(chezmoi source-path)" && ./scripts/install-packages.sh`.
   On native Windows, install MSYS2 separately, update it, and run the script
   from the UCRT64 terminal.

On Fedora, preview package resolution without installing with
`cd "$(chezmoi source-path)" && ./scripts/install-packages.sh --dry-run`.

The profile is a local chezmoi setting. `home` enables the macOS AeroSpace and
SketchyBar configuration; `work` omits those files. OS detection also keeps
macOS-only configuration off Linux and Windows.

## Supported environments

- macOS: Zsh and Homebrew
- Fedora-family Linux: Zsh and `dnf`
- Debian-family Linux and WSL: Zsh and `apt`
- Native Windows: Zsh through MSYS2

Interactive Zsh runs Fastfetch once per terminal when it is installed. The
Neofetch command is no longer part of shell startup.

For native Windows, configure MSYS2 to use the Windows user home (`db_home:
windows` in MSYS2's `/etc/nsswitch.conf`) so Zsh and chezmoi use the same
dotfile destination. The Windows-only Bash profile starts Zsh after it is
installed. The package script installs available UCRT64 CLI packages; it skips
MSYS2 packages that are not present in the configured repositories.

Package installation remains a separate, explicit operation. The installer
uses Homebrew on macOS, `dnf` on Fedora-family Linux, `apt` on Debian-family
Linux/WSL, and `pacman` inside MSYS2. Applying dotfiles never invokes a package
manager. The Linux and MSYS2 lists cover the shared CLI baseline; macOS keeps
the existing broader app list, with AeroSpace, SketchyBar, and Borders limited
to the `home` profile.

Ghostty is included in the macOS Homebrew bundle and the DNF list when an
enabled repository provides it (available in Terra). Terra is a third-party
rolling RPM repository; this setup enables only its main repository, not its
optional subrepositories. Review Terra's package compatibility notes if using
other third-party repositories such as RPM Fusion.

ComicShannsMono Nerd Font is installed by the Homebrew cask on macOS, the
verified Nerd Fonts release installer on Linux/WSL, and a per-user Windows font
installer from MSYS2. Restart Windows terminal applications after installation.

The `home` profile installs Tailscale, the 1Password desktop app and CLI, and
OpenCode 2. Homebrew uses the 1Password casks and official OpenCode V2 formula;
Fedora enables the signed 1Password RPM repository during package
installation; Debian uses 1Password's signed APT repository; and native Windows
uses Winget from the MSYS2 UCRT64 setup. Tailscale is installed through
Homebrew/DNF/APT/Winget for `home` only. OpenCode uses its official installer
outside Homebrew and is placed in `~/.opencode/bin`, which Zsh adds to `PATH`.
The `home` package sets also provide `uvx` for the configured Blender MCP server.
The Debian 1Password repo helper currently supports amd64. In containers without
systemd, Fedora skips the 1Password desktop app but installs its CLI.

Selecting `work` skips these packages and repositories. It does not uninstall
software that was already installed.
