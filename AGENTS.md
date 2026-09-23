# Agent instructions

Read `README.md` first. Read `VERIFY.md` whenever release artifacts are involved.

## Installation and network setup

- Installation obtains, verifies, and installs the package. `rpay-setup` creates or joins/configures a network. Never make the installer create or join a network.
- Complete package signature, checksum, and metadata verification before installation.
- Never guess CLI flags. Consult `rpay --help`, `rpay <subcommand> --help`, or `rpay-setup --help` on the installed/current package.
- Bootstrap/join is a one-time operation. If it fails: stop, preserve state, and collect evidence. Do not blindly retry a one-time invite.
- Never automatically wipe `/var/lib/rpay` or `/etc/rpay`, regenerate an identity, recreate a network, retry a one-time invite blindly, or edit bootstrap SQLite databases.
- Do not touch unrelated nginx, databases, websites, services, or firewall rules.

## Security and evidence

- Never print private keys, invite capabilities, pairing secrets, or the release private key.
- Prefer read-only diagnostics first. Scope `journalctl` output to relevant units and timestamps. Keep reports concise.
- Preserve existing state during package upgrades; do not purge or reset identities.
- The installer refuses downgrades unless the operator explicitly supplies `--allow-downgrade` with `--version`.

## Current product boundaries

- Founding validator admission is different from ordinary participant onboarding.
- A participant is not necessarily a validator.
- Discovery does not create a counterparty relationship.
- Installation is separate from network setup.
- Do not claim that general post-genesis participant onboarding exists; the current software does not implement it.

Expected production port boundaries:

- `7000/tcp`, `7001/tcp`, and `5100/tcp`: public/reachable as required for node networking.
- `7878/tcp` operator API and `6100/tcp` validator client RPC: loopback-only.
