#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="uton88"
REPO_NAME="dan-binary-releases"

COMPONENT="dan-web"
INSTALL_DIR="$PWD/dan-runtime"
VERSION="latest"
CPA_BASE_URL=""
CPA_TOKEN=""
MAIL_API_URL=""
MAIL_API_KEY=""
THREADS="20"
WEB_TOKEN="linuxdo"
CLIENT_API_TOKEN="linuxdo"
PORT="25666"
DEFAULT_PROXY=""

usage() {
  cat <<'EOF'
Usage:
  install.sh [options]

Options:
  --component dan-web|dan|dan-token-refresh
  --install-dir DIR
  --version latest|vX.Y.Z
  --cpa-base-url URL
  --cpa-token TOKEN
  --mail-api-url URL
  --mail-api-key KEY
  --threads N
  --web-token TOKEN
  --client-api-token TOKEN
  --port N
  --default-proxy URL
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --component) COMPONENT="${2:-}"; shift 2 ;;
    --install-dir) INSTALL_DIR="${2:-}"; shift 2 ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --cpa-base-url) CPA_BASE_URL="${2:-}"; shift 2 ;;
    --cpa-token) CPA_TOKEN="${2:-}"; shift 2 ;;
    --mail-api-url) MAIL_API_URL="${2:-}"; shift 2 ;;
    --mail-api-key) MAIL_API_KEY="${2:-}"; shift 2 ;;
    --threads) THREADS="${2:-}"; shift 2 ;;
    --web-token) WEB_TOKEN="${2:-}"; shift 2 ;;
    --client-api-token) CLIENT_API_TOKEN="${2:-}"; shift 2 ;;
    --port) PORT="${2:-}"; shift 2 ;;
    --default-proxy) DEFAULT_PROXY="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd curl

json_escape() {
  local value="${1-}"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

detect_os() {
  case "$(uname -s)" in
    Linux) printf 'linux' ;;
    Darwin) printf 'darwin' ;;
    *) echo "Unsupported operating system: $(uname -s)" >&2; exit 1 ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf 'amd64' ;;
    arm64|aarch64) printf 'arm64' ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
}

build_release_base() {
  if [[ "$VERSION" == "latest" ]]; then
    printf 'https://github.com/%s/%s/releases/latest/download' "$REPO_OWNER" "$REPO_NAME"
  else
    printf 'https://github.com/%s/%s/releases/download/%s' "$REPO_OWNER" "$REPO_NAME" "$VERSION"
  fi
}

OS="$(detect_os)"
ARCH="$(detect_arch)"
ASSET_NAME="${COMPONENT}-${OS}-${ARCH}"
LOCAL_BINARY="$COMPONENT"
RELEASE_BASE="$(build_release_base)"
DOWNLOAD_URL="${RELEASE_BASE}/${ASSET_NAME}"
CHECKSUM_URL="${RELEASE_BASE}/SHA256SUMS.txt"
TMP_BINARY="$INSTALL_DIR/.${LOCAL_BINARY}.download.$$"

mkdir -p "$INSTALL_DIR/config"

cleanup() {
  rm -f "$TMP_BINARY" "$INSTALL_DIR/SHA256SUMS.unix.txt"
}
trap cleanup EXIT

echo "Downloading ${ASSET_NAME}..."
curl -fL "$DOWNLOAD_URL" -o "$TMP_BINARY"
chmod +x "$TMP_BINARY"

echo "Downloading SHA256SUMS.txt..."
curl -fL "$CHECKSUM_URL" -o "$INSTALL_DIR/SHA256SUMS.txt"
tr -d '\r' < "$INSTALL_DIR/SHA256SUMS.txt" > "$INSTALL_DIR/SHA256SUMS.unix.txt"

mv -f "$TMP_BINARY" "$INSTALL_DIR/$LOCAL_BINARY"
chmod +x "$INSTALL_DIR/$LOCAL_BINARY"

# 硬编码域名逻辑
DOMAINS_JSON='["miaobixiezuo.com"]'

echo "Generating web_config.json..."
cat > "$INSTALL_DIR/config/web_config.json" <<EOF
{
  "target_min_tokens": 15000,
  "auto_fill_start_gap": 1,
  "check_interval_minutes": 1,
  "manual_default_threads": ${THREADS},
  "manual_register_retries": 3,
  "otp_retry_count": 12,
  "otp_retry_interval_seconds": 5,
  "web_token": "$(json_escape "$WEB_TOKEN")",
  "client_api_token": "$(json_escape "$CLIENT_API_TOKEN")",
  "client_notice": "",
  "minimum_client_version": "",
  "enabled_email_domains": ${DOMAINS_JSON},
  "mail_domain_options": ${DOMAINS_JSON},
  "default_proxy": "$(json_escape "$DEFAULT_PROXY")",
  "use_registration_proxy": $([[ -n "${DEFAULT_PROXY// }" ]] && printf 'true' || printf 'false'),
  "cpa_base_url": "$(json_escape "$CPA_BASE_URL")",
  "cpa_token": "$(json_escape "$CPA_TOKEN")",
  "mail_api_url": "$(json_escape "$MAIL_API_URL")",
  "mail_api_key": "$(json_escape "$MAIL_API_KEY")",
  "port": ${PORT}
}
EOF

echo "Starting $COMPONENT..."
cd "$INSTALL_DIR"
exec "./$LOCAL_BINARY"
