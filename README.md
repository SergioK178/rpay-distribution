# rpay distribution

`rpay` is self-hosted software for running participant and validator nodes in an rpay network. This repository contains only public release and installation material. Packages are published as signed Debian assets on [GitHub Releases](https://github.com/SergioK178/rpay-distribution/releases).

## Supported platform

The verified production baseline is Debian 12, `amd64`, with systemd.

## Install

```bash
git clone https://github.com/SergioK178/rpay-distribution.git
cd rpay-distribution
./install.sh
```

The default selects the latest stable release. A prerelease requires an explicit tag:

```bash
./install.sh --version <release-tag>
```

To download and fully verify a release without installing it:

```bash
./install.sh --verify-only --version <release-tag>
```

Downgrades are refused by default. An intentional downgrade requires `--version <release-tag> --allow-downgrade`.

For manual verification, see [VERIFY.md](VERIFY.md).

## After installation

Inspect the currently supported setup commands with:

```bash
rpay-setup --help
```

For founding a network, `sudo rpay-setup --new-network --validators 4 --public-ip <PUBLIC_IP>` creates a four-validator genesis network. Other founding validators join with `sudo rpay-setup --join <INVITE_FILE> --public-ip <PUBLIC_IP>`. Check a configured node with `rpay status --config /etc/rpay/participant.toml` or `rpay doctor --config /etc/rpay/participant.toml`. Founding validator admission is not ordinary participant onboarding; a general post-genesis participant onboarding path is not currently implemented.

Network setup is a separate action from package installation. The operator API on port `7878` and validator client RPC on port `6100` are loopback-only by default; use SSH forwarding for operator access.
