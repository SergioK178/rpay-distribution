#!/usr/bin/env bash
set -euo pipefail

readonly REPOSITORY="SergioK178/rpay-distribution"
readonly API="https://api.github.com/repos/${REPOSITORY}"
readonly RELEASES="https://github.com/${REPOSITORY}/releases"
readonly EXPECTED_FINGERPRINT="38679AC26C1301E382E0DD3AA5A08B9510CFF266"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly BUNDLED_KEY="${SCRIPT_DIR}/keys/rpay-release-key.asc"
readonly DOWNGRADE_FLAG="--allow-downgrade"

usage() {
    cat <<'EOF'
Usage:
  ./install.sh
  ./install.sh --version <tag>
  ./install.sh --verify-only --version <tag>
  ./install.sh --version <tag> --allow-downgrade
  ./install.sh --help

Without --version, installs the latest stable release. Prereleases require an
explicit tag, for example --version v0.1.1-rc.1. Verification downloads and
checks the release without installing it.
Downgrades are refused unless --allow-downgrade is explicitly supplied.
EOF
}

die() { printf 'install.sh: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }

verify_only=0
allow_downgrade=0
requested_tag=
while (($#)); do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --version)
            (($# >= 2)) || die "--version requires a release tag"
            [[ -z "$requested_tag" ]] || die "--version may be specified only once"
            requested_tag=$2; shift 2 ;;
        --verify-only) ((verify_only == 0)) || die "--verify-only may be specified only once"; verify_only=1; shift ;;
        "$DOWNGRADE_FLAG") ((allow_downgrade == 0)) || die "$DOWNGRADE_FLAG may be specified only once"; allow_downgrade=1; shift ;;
        *) die "unknown option: $1 (use --help)" ;;
    esac
done

if [[ -n "$requested_tag" && ! "$requested_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[1-9][0-9]*)?$ ]]; then
    die "invalid release tag: $requested_tag (expected vX.Y.Z or vX.Y.Z-rc.N)"
fi
if ((verify_only)) && [[ -z "$requested_tag" ]]; then
    die "--verify-only requires --version <tag>"
fi
if ((allow_downgrade)) && [[ -z "$requested_tag" ]]; then
    die "$DOWNGRADE_FLAG requires --version <tag>"
fi

for tool in curl gpg gpgconf sha256sum dpkg-deb dpkg dpkg-query apt-get awk python3 sudo; do need "$tool"; done
[[ -r "$BUNDLED_KEY" ]] || die "bundled release key not found: $BUNDLED_KEY"
[[ "$(dpkg --print-architecture)" == amd64 ]] || die "only amd64 packages are supported"
[[ -r /etc/os-release ]] || die "cannot identify operating system; supported baseline is Debian 12"
# shellcheck disable=SC1091
. /etc/os-release
[[ "${ID:-}" == debian && "${VERSION_ID:-}" == 12 ]] || die "supported baseline is Debian 12"

tmpdir=$(mktemp -d) || die "could not create temporary directory"
cleanup() { rm -rf -- "$tmpdir"; }
trap cleanup EXIT
chmod 700 "$tmpdir"

if [[ -z "$requested_tag" ]]; then
    metadata=$(curl --fail --silent --show-error --location --retry 2 --retry-connrefused \
        -H 'Accept: application/vnd.github+json' "$API/releases/latest") || die "could not resolve latest stable release"
    requested_tag=$(printf '%s' "$metadata" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name", ""))')
    prerelease=$(printf '%s' "$metadata" | python3 -c 'import json,sys; print(str(json.load(sys.stdin).get("prerelease", True)).lower())')
    [[ "$requested_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ && "$prerelease" == false ]] || die "latest release endpoint did not return a valid stable release"
fi

version=${requested_tag#v}
if [[ "$version" =~ ^([0-9]+\.[0-9]+\.[0-9]+)-rc\.([1-9][0-9]*)$ ]]; then
    deb_version="${BASH_REMATCH[1]}~rc${BASH_REMATCH[2]}-1"
elif [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    deb_version="${version}-1"
else
    die "unsupported release tag: $requested_tag"
fi
asset="rpay_${deb_version//\~/-}_amd64.deb"
release_url="${RELEASES}/download/${requested_tag}"

download() {
    local name=$1 url=$2
    if ! curl --fail --silent --show-error --location --retry 2 --retry-connrefused \
        --output "$tmpdir/$name" "$url"; then
        die "failed to download $name for $requested_tag (missing release or asset, or network error)"
    fi
    [[ -s "$tmpdir/$name" ]] || die "downloaded asset is empty: $name"
}

download "$asset" "$release_url/$asset"
download SHA256SUMS "$release_url/SHA256SUMS"
download SHA256SUMS.asc "$release_url/SHA256SUMS.asc"

gpg_home="$tmpdir/gnupg"
mkdir -m 700 "$gpg_home"
if ! gpg --batch --homedir "$gpg_home" --import "$BUNDLED_KEY" >/dev/null 2>&1; then
    die "could not load bundled public release key"
fi
actual_fingerprint=$(gpg --batch --homedir "$gpg_home" --with-colons --fingerprint \
    | awk -F: '$1 == "fpr" {print $10; exit}')
[[ "$actual_fingerprint" == "$EXPECTED_FINGERPRINT" ]] || die "bundled release key fingerprint mismatch (expected $EXPECTED_FINGERPRINT, got ${actual_fingerprint:-none})"
if ! gpg --batch --homedir "$gpg_home" --status-fd 1 --verify "$tmpdir/SHA256SUMS.asc" "$tmpdir/SHA256SUMS" >"$tmpdir/gpg-status" 2>"$tmpdir/gpg-error"; then
    cat "$tmpdir/gpg-error" >&2
    die "release checksum signature verification failed"
fi
valid_fingerprint=$(awk '$2 == "VALIDSIG" {print $3; exit}' "$tmpdir/gpg-status")
[[ "$valid_fingerprint" == "$EXPECTED_FINGERPRINT" ]] || die "checksum signature was not made by the pinned release key"

expected_hash=$(awk -v name="$asset" '$2 == name || $2 == "*" name {print $1; found++} END {if (found != 1) exit 1}' "$tmpdir/SHA256SUMS") || die "SHA256SUMS must contain exactly one entry for $asset"
[[ "$expected_hash" =~ ^[[:xdigit:]]{64}$ ]] || die "invalid SHA-256 entry for $asset"
actual_hash=$(sha256sum "$tmpdir/$asset" | awk '{print $1}')
[[ "$actual_hash" == "$expected_hash" ]] || die "SHA-256 mismatch for $asset"

package=$(dpkg-deb --field "$tmpdir/$asset" Package 2>/dev/null) || die "downloaded file is not a valid Debian package"
architecture=$(dpkg-deb --field "$tmpdir/$asset" Architecture 2>/dev/null) || die "cannot read package architecture"
package_version=$(dpkg-deb --field "$tmpdir/$asset" Version 2>/dev/null) || die "cannot read package version"
[[ "$package" == rpay ]] || die "unexpected package name: $package"
[[ "$architecture" == amd64 ]] || die "unexpected package architecture: $architecture"
[[ "$package_version" == "$deb_version" ]] || die "package version mismatch: expected $deb_version, got $package_version"

printf 'Verified %s: %s, Debian version %s, SHA-256 %s, signing fingerprint %s\n' \
    "$requested_tag" "$asset" "$package_version" "$expected_hash" "$EXPECTED_FINGERPRINT"
if ((verify_only)); then exit 0; fi

installed_version=$(dpkg-query -W -f='${Version}' rpay 2>/dev/null || true)
if [[ -n "$installed_version" ]]; then
    printf 'Installed rpay version: %s\n' "$installed_version"
    if ((allow_downgrade == 0)) && dpkg --compare-versions "$package_version" lt "$installed_version"; then
        die "refusing downgrade from $installed_version to $package_version"
    fi
fi

printf 'Installing verified package with apt.\n'
sudo apt-get install -y "$tmpdir/$asset"
printf '\nrpay package installed. Inspect setup options with:\n  rpay-setup --help\n'
