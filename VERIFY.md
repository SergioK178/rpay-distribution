# Verifying a release

Each release contains:

- `rpay_amd64.deb`
- `SHA256SUMS`
- `SHA256SUMS.asc`

The checksum manifest is signed with the rpay release signing key. The public key is published at [`keys/rpay-release-key.asc`](keys/rpay-release-key.asc).

## Verify the signing key

Import the public key and inspect its fingerprint:

```bash
gpg --import keys/rpay-release-key.asc
gpg --fingerprint 'rpay Release Signing'
```

Compare the fingerprint with the release fingerprint published by the project maintainer through an independent trusted channel:

```text
Fingerprint: 38679AC26C1301E382E0DD3AA5A08B9510CFF266
```

Do not trust a key solely because it was downloaded from the same release repository.

## Verify a downloaded release

Keep `rpay_amd64.deb`, `SHA256SUMS`, and `SHA256SUMS.asc` in the same directory, then run:

```bash
gpg --verify SHA256SUMS.asc SHA256SUMS
sha256sum -c SHA256SUMS
```

The first command verifies the signed checksum manifest. The second verifies the downloaded Debian package against that manifest.

After both checks succeed, install the package with:

```bash
sudo apt install ./rpay_amd64.deb
```

