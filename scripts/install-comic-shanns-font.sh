#!/usr/bin/env bash
set -euo pipefail

version="3.5.1"
font_family="ComicShannsMono Nerd Font"
archive_name="ComicShannsMono.tar.xz"
archive_sha256="0ca2a0aac547d52a395551a19c2bed0d6ee9541feb06c90cbd48f314ec995045"
archive_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${archive_name}"
font_root="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
font_dir="$font_root/ComicShannsMonoNerdFont-dotfiles"

if command -v fc-match >/dev/null 2>&1; then
  installed_family="$(fc-match --format='%{family}' "$font_family" 2>/dev/null || true)"
  if [[ "$installed_family" == *"$font_family"* ]]; then
    echo "$font_family is already available."
    exit 0
  fi
fi

for command_name in curl sha256sum tar fc-cache install; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
done

temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT
archive_path="$temporary_directory/$archive_name"

curl --fail --location --retry 3 "$archive_url" --output "$archive_path"
printf '%s  %s\n' "$archive_sha256" "$archive_path" | sha256sum --check

mkdir -p "$temporary_directory/extracted" "$font_dir"
tar --extract --xz --file "$archive_path" --directory "$temporary_directory/extracted"
find "$font_dir" -maxdepth 1 -type f \
  \( -name 'ComicShannsMonoNerdFont*.otf' -o -name 'ComicShannsMonoNerdFont*.ttf' \) -delete
find "$temporary_directory/extracted" -maxdepth 1 -type f \
  \( -name 'ComicShannsMonoNerdFont*.otf' -o -name 'ComicShannsMonoNerdFont*.ttf' \) \
  -exec install --mode=0644 '{}' "$font_dir/" \;

if ! find "$font_dir" -maxdepth 1 -type f \( -name '*.otf' -o -name '*.ttf' \) -print -quit | grep -q .; then
  echo "No Comic Shanns Mono Nerd Font files were found in the release archive." >&2
  exit 1
fi

fc-cache --force "$font_dir"
installed_family="$(fc-match --format='%{family}' "$font_family")"
if [[ "$installed_family" != *"$font_family"* ]]; then
  echo "Font installation did not resolve to '$font_family' (resolved '$installed_family')." >&2
  exit 1
fi

echo "Installed $font_family $version in $font_dir."
