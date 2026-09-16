#!/bin/sh
set -eu

# Replace <OWNER> with the GitHub account or organization that owns this repo.
REPO="https://github.com/<OWNER>/rpay-distribution"
BASE="$REPO/releases/latest/download"
TMP="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP"
}
trap cleanup 0

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root or with sudo." >&2
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg >/dev/null 2>&1; then
    echo "This installer currently supports Debian/Ubuntu systems." >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required." >&2
    exit 1
fi

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != "amd64" ]; then
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
fi

curl -fL "$BASE/rpay_amd64.deb" -o "$TMP/rpay_amd64.deb"
curl -fL "$BASE/SHA256SUMS" -o "$TMP/SHA256SUMS"

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
