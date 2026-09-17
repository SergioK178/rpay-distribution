#!/bin/sh
set -eu

REPO="https://github.com/SergioK178/rpay-distribution"
BASE="$REPO/releases/latest/download"
KEY_URL="https://raw.githubusercontent.com/SergioK178/rpay-distribution/main/keys/rpay-release-key.asc"
EXPECTED_FINGERPRINT="38679AC26C1301E382E0DD3AA5A08B9510CFF266"
TMP="$(mktemp -d)"
chmod 755 "$TMP"

cleanup() {
    rm -rf "$TMP"
}
trap cleanup 0

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root or with sudo." >&2
    exit 1
fi

for cmd in apt-get dpkg curl gpgv sha256sum; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing required command: $cmd" >&2
        exit 1
    fi
done

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != "amd64" ]; then
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
fi

curl -fL "$BASE/rpay_amd64.deb" -o "$TMP/rpay_amd64.deb"
chmod 644 "$TMP/rpay_amd64.deb"
curl -fL "$BASE/SHA256SUMS" -o "$TMP/SHA256SUMS"
curl -fL "$BASE/SHA256SUMS.asc" -o "$TMP/SHA256SUMS.asc"
curl -fL "$KEY_URL" -o "$TMP/rpay-release-key.asc"

VERIFY_OUTPUT="$(gpgv --status-fd 1 --keyring "$TMP/rpay-release-key.asc" \
    "$TMP/SHA256SUMS.asc" "$TMP/SHA256SUMS" 2>&1)" || {
    printf '%s\n' "$VERIFY_OUTPUT" >&2
    exit 1
}
printf '%s\n' "$VERIFY_OUTPUT"

ACTUAL_FINGERPRINT="$(printf '%s\n' "$VERIFY_OUTPUT" \
    | awk '$1 == "[GNUPG:]" && $2 == "VALIDSIG" { print $3; exit }')"
if [ "$ACTUAL_FINGERPRINT" != "$EXPECTED_FINGERPRINT" ]; then
    echo "Release signing key fingerprint mismatch." >&2
    echo "Expected: $EXPECTED_FINGERPRINT" >&2
    echo "Actual:   $ACTUAL_FINGERPRINT" >&2
    exit 1
fi

(
    cd "$TMP"
    sha256sum -c SHA256SUMS
)

apt-get install -y "$TMP/rpay_amd64.deb"

echo
if [ -x /usr/bin/sovereign-node ]; then
    /usr/bin/sovereign-node --version
elif command -v sovereign-node >/dev/null 2>&1; then
    sovereign-node --version
else
    echo "Warning: sovereign-node was not found after installation." >&2
fi
echo "rpay installed successfully."
echo
echo "Next:"
echo "  sudo rpay-setup --public-ip <SERVER_PUBLIC_IP>"
