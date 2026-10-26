$ErrorActionPreference = "Stop"

$version = "3.5.1"
$expectedSha256 = "3e746fc4393e1e6a72c2a311af6cc95ce66c3a39eb37216907ba28d7bf699bd2"
$archiveName = "ComicShannsMono.zip"
$archiveUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v$version/$archiveName"
$fontRoot = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$fontDirectory = Join-Path $fontRoot "Dotfiles\ComicShannsMonoNerdFont"
$markerPath = Join-Path $fontDirectory ".nerd-fonts-version"
$registryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

if ((Test-Path $markerPath) -and ((Get-Content $markerPath -Raw).Trim() -eq $version)) {
    Write-Output "ComicShannsMono Nerd Font $version is already installed for this Windows user."
    exit 0
}

$temporaryDirectory = Join-Path $env:TEMP ("comicshanns-" + [guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $temporaryDirectory $archiveName
$extractDirectory = Join-Path $temporaryDirectory "extracted"

try {
    New-Item -ItemType Directory -Path $extractDirectory -Force | Out-Null
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath

    $actualSha256 = (Get-FileHash -Path $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSha256 -ne $expectedSha256) {
        throw "SHA-256 mismatch for $archiveName. Expected $expectedSha256; got $actualSha256."
    }

    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractDirectory -Force
    $fontFiles = Get-ChildItem -Path $extractDirectory -Filter "ComicShannsMonoNerdFont*.otf" -File
    if ($fontFiles.Count -eq 0) {
        throw "No Comic Shanns Mono Nerd Font files were found in the release archive."
    }

    New-Item -ItemType Directory -Path $fontDirectory -Force | Out-Null
    New-Item -Path $registryPath -Force | Out-Null

    foreach ($fontFile in $fontFiles) {
        $destination = Join-Path $fontDirectory $fontFile.Name
        Copy-Item -LiteralPath $fontFile.FullName -Destination $destination -Force

        if ($fontFile.Name -match "NerdFontMono-(Bold|Regular)\.otf$") {
            $family = "ComicShannsMono Nerd Font Mono"
        } elseif ($fontFile.Name -match "NerdFontPropo-(Bold|Regular)\.otf$") {
            $family = "ComicShannsMono Nerd Font Propo"
        } else {
            $family = "ComicShannsMono Nerd Font"
        }

        if ($fontFile.Name -match "-(Bold|Regular)\.otf$") {
            $style = $Matches[1]
        } else {
            throw "Unexpected Comic Shanns Mono font filename: $($fontFile.Name)"
        }

        $registryName = "$family $style (OpenType)"
        New-ItemProperty -Path $registryPath -Name $registryName -Value $destination `
            -PropertyType String -Force | Out-Null
    }

    Set-Content -Path $markerPath -Value $version -NoNewline
    Write-Output "Installed ComicShannsMono Nerd Font $version for the current Windows user. Restart terminal apps to pick it up."
} finally {
    if (Test-Path $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}
