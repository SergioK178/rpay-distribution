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

## v0.1.1-rc.1 (release candidate)

v0.1.1-rc.1 is a release candidate and is not distributed through the stable
install script. Download the versioned package from the [v0.1.1-rc.1 pre-release](https://github.com/SergioK178/rpay-distribution/releases/tag/v0.1.1-rc.1), verify it using [VERIFY.md](VERIFY.md), then install it directly:

```bash
sudo apt install ./rpay_0.1.1-rc1-1_amd64.deb
```

Do not use `install.sh` for this RC: it deliberately follows GitHub's stable
`latest` release and does not select pre-releases.

### Create a four-validator network

On the first node, run:

```bash
sudo rpay-setup \
  --new-network \
  --validators 4 \
  --public-ip <PUBLIC_IP>
```

This creates three one-time `*.rpay-invite` files, one for each other founding
validator. Transfer each file only to its intended operator.

On another node, join using the **path to an invite file**:

```bash
sudo rpay-setup \
  --join /path/to/node-X.rpay-invite \
  --public-ip <PUBLIC_IP>
```

`--join` does not accept an inline invitation token. The invite file must be
readable by the `rpay` user. `/root` is normally not readable by `rpay`, so an
invite placed there can fail. For example, give the received file to `rpay`
with restrictive permissions, then join with that path:

```bash
sudo install -o rpay -g rpay -m 0600 \
  node-X.rpay-invite \
  /tmp/node-X.rpay-invite

sudo rpay-setup \
  --join /tmp/node-X.rpay-invite \
  --public-ip <PUBLIC_IP>
```

Operational commands:

```bash
rpay status --config /etc/rpay/participant.toml
rpay doctor --config /etc/rpay/participant.toml
systemctl status rpay
journalctl -u rpay
```

Open these TCP ports between validators: participant P2P `7000`, bootstrap and
discovery `7001`, and validator consensus `5100`. The operator API is local at
`127.0.0.1:7878`; the local validator client RPC is `127.0.0.1:6100`.

Configuration is under `/etc/rpay`; state, keys, installation material, and
backups are under `/var/lib/rpay`. To upgrade, install a newer explicit `.deb`
with `sudo apt install ./rpay_<version>_amd64.deb`. To uninstall, run
`sudo apt remove rpay`; preserve or explicitly remove `/etc/rpay` and
`/var/lib/rpay` only according to your backup/retention policy.

### RC status

v0.1.1-rc.1 is a release candidate. Distributed four-validator VPS acceptance
for this public RC is still pending.

## Supported systems

- Debian or Ubuntu
- Linux `amd64`
- systemd-based installations
