![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/rclone-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/rclone-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/rclone-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/rclone-debian)

<h1>
   <p align="center">
     <a href="https://rclone.org/"><img src="https://github.com/dariogriffo/rclone-debian/blob/main/rclone.png" alt="rclone Logo" width="220" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/rclone-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>rclone for Debian
   </p>
</h1>
<p align="center">
 rclone is "rsync for cloud storage" — sync files and directories to and from
 more than 70 cloud storage providers.
</p>

# rclone for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [rclone](https://github.com/rclone/rclone/) hosted at [deb.griffo.io](https://deb.griffo.io)

Debian ships rclone in its own archive, but it lags a long way behind upstream:
Debian 13 (Trixie) carries **1.60.1**, roughly fifteen minor releases behind the
current upstream release. These packages track upstream directly and are built
to be a drop-in, newer replacement for Debian's `rclone` package — same package
name, same section, same paths, same `/usr/sbin/mount.rclone` helper.

Currently supported Debian distros are:
- Bookworm (v12)
- Trixie (v13)
- Forky (v14)
- Sid (testing)

Currently supported Ubuntu distros are:
- Jammy (22.04)
- Noble (24.04)
- Questing (25.10)
- Resolute (26.04)

Supported architectures:
- amd64 (x86_64) - All distributions
- arm64 (aarch64) - All distributions
- armhf (ARM hard float, ARMv7) - All distributions
- i386 (x86 32-bit) - Debian only

Upstream publishes no `riscv64` Linux build and no soft-float ARMv5 build, so
`riscv64` and `armel` are not offered. Upstream's `mips`/`mipsle` builds do not
map onto a current Debian release architecture and are likewise not offered.

The packages include the rclone binary, the `rclone.1` manual page, the
`/usr/sbin/mount.rclone` mount helper (so `mount -t rclone` and `fstab` entries
work, matching Debian's own package) and shell completions for bash, fish and
zsh. Upstream does not ship completion scripts in its release archives, so they
are generated at build time with `rclone completion <shell>`.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the rclone source code, see
[rclone](https://github.com/rclone/rclone/).

## Install/Update

📖 **Step-by-step install guide:** [Debian](https://deb.griffo.io/install-latest-rclone-in-debian.html) · [Ubuntu](https://deb.griffo.io/install-latest-rclone-in-ubuntu.html)

### The Debian way

> ⚠️ **From 1 October 2026, apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/rclone-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y rclone
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/rclone-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Building

### Build for single architecture
```sh
./build.sh <rclone_version> <build_version> <architecture>
# Example: ./build.sh 1.75.0 1 arm64
```

### Build for all architectures
```sh
./build.sh <rclone_version> <build_version> all
# Example: ./build.sh 1.75.0 1 all
```

`unzip` is required on the build host: upstream ships its Linux binaries as
`.zip` archives rather than tarballs.

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates
- [x] Multi-architecture support (amd64, arm64, armhf, i386)

## Disclaimer

- This repo is not open for issues related to rclone. This repo is only for _unofficial_ Debian packaging.
