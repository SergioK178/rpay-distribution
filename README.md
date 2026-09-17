# rpay distribution

This is the public distribution repository for `rpay` releases.

The repository contains the installer and release verification material. Binary packages are published as assets in [GitHub Releases](https://github.com/SergioK178/rpay-distribution/releases), not committed to git.

## Install

```bash
curl -fsSL \
  https://raw.githubusercontent.com/SergioK178/rpay-distribution/main/install.sh \
  | sudo sh
```

The installer currently supports Debian/Ubuntu systems on `amd64` and requires `apt`, `dpkg`, and `curl`.

The package does not automatically start or enable the `rpay` service. Service bootstrap and configuration are performed separately.

## Manual installation

Download `rpay_amd64.deb` from the appropriate [release](https://github.com/SergioK178/rpay-distribution/releases), verify it using [VERIFY.md](VERIFY.md), and install it with:

```bash
sudo apt install ./rpay_amd64.deb
```

## Supported systems

- Debian or Ubuntu
- Linux `amd64`
- systemd-based installations
