# rpay distribution

This is the public distribution repository for `rpay` releases.

The repository contains the installer and release verification material. Binary packages are published as assets in [GitHub Releases](https://github.com/SergioK178/rpay-distribution/releases), not committed to git.

## Install

On a clean Debian/Ubuntu VPS, bootstrap the installer dependencies first. Run this
as `root`:

```bash
apt-get update && \
apt-get install -y ca-certificates curl gpgv && \
curl -fL https://raw.githubusercontent.com/SergioK178/rpay-distribution/main/install.sh \
  -o /tmp/rpay-install.sh && \
sh /tmp/rpay-install.sh
```

If you are not logged in as `root`, prefix the `apt-get` and installer commands
with `sudo`.

The installer downloads the pinned public release key, verifies its fingerprint,
checks the signed `SHA256SUMS` manifest with `gpgv`, verifies the Debian package
checksum, and only then installs the package.

For an already prepared machine, the short convenience form is also supported:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/SergioK178/rpay-distribution/main/install.sh \
  | sudo sh
```

The installer currently supports Debian/Ubuntu systems on `amd64` and requires
`apt-get`, `dpkg`, `curl`, `gpgv`, and `sha256sum`.

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
