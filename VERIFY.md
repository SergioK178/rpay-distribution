# Verify a release manually

This procedure downloads one selected GitHub Release and verifies its Debian package before installation. Replace `<tag>` with an actual release tag such as `vX.Y.Z` or `vX.Y.Z-rc.N`; these are format examples, not claims that a particular release is available.

The release process maps stable `vX.Y.Z` to Debian version `X.Y.Z-1` and asset `rpay_X.Y.Z-1_amd64.deb`. It maps `vX.Y.Z-rc.N` to Debian version `X.Y.Z~rcN-1` and public asset `rpay_X.Y.Z-rcN-1_amd64.deb`.

## Download assets

Set `TAG` to the selected release and set `ASSET` to the corresponding package name:

```bash
TAG='<tag>'
ASSET='rpay_<version-and-revision>_amd64.deb'
BASE="https://github.com/SergioK178/rpay-distribution/releases/download/$TAG"
mkdir -m 700 "verify-$TAG"
cd "verify-$TAG"
curl --fail --location --output "$ASSET" "$BASE/$ASSET"
curl --fail --location --output SHA256SUMS "$BASE/SHA256SUMS"
curl --fail --location --output SHA256SUMS.asc "$BASE/SHA256SUMS.asc"
```

Run these commands from a clone of this repository so `keys/rpay-release-key.asc` is available. For stable `v0.1.1`, for example, use `ASSET='rpay_0.1.1-1_amd64.deb'`. Do not use this example as evidence that a release is currently available.

## Verify the key and signed manifest

Use an isolated temporary GPG home. The expected primary fingerprint is exactly `38679AC26C1301E382E0DD3AA5A08B9510CFF266`; the key UID is not the trust decision.

```bash
EXPECTED=38679AC26C1301E382E0DD3AA5A08B9510CFF266
GNUPGHOME="$(mktemp -d)"
chmod 700 "$GNUPGHOME"
export GNUPGHOME
trap 'gpgconf --kill all 2>/dev/null || true; rm -rf "$GNUPGHOME"' EXIT
gpg --batch --import ../keys/rpay-release-key.asc
ACTUAL="$(gpg --batch --with-colons --fingerprint | awk -F: '$1 == "fpr" {print $10; exit}')"
test "$ACTUAL" = "$EXPECTED"
gpg --batch --verify SHA256SUMS.asc SHA256SUMS
```

## Verify checksum and package metadata

Confirm the manifest entry for the chosen asset, then verify it:

```bash
awk -v name="$ASSET" '$2 == name || $2 == "*" name {print; found++} END {if (found != 1) exit 1}' SHA256SUMS
sha256sum --check --strict -- "$ASSET" < SHA256SUMS
test "$(dpkg-deb --field "$ASSET" Package)" = rpay
test "$(dpkg-deb --field "$ASSET" Architecture)" = amd64
dpkg-deb --field "$ASSET" Version
```

Compare the displayed Debian version with the selected tag using the mapping above. For example, `vX.Y.Z-rc.N` must have package version `X.Y.Z~rcN-1`. Stop if the manifest is invalid, the signature or checksum fails, or any metadata differs.

Only after all checks pass, install the verified package through apt:

```bash
sudo apt install "./$ASSET"
```
