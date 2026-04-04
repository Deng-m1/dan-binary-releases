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
THREADS="68"
WEB_TOKEN="linuxdo"
CLIENT_API_TOKEN="linuxdo"
PORT="25666"

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
    MINGW*|MSYS*|CYGWIN*) printf 'windows' ;;
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

if [[ "$OS" == "windows" ]]; then
  echo "Use install.ps1 on Windows." >&2
  exit 1
fi

case "$COMPONENT" in
  dan|dan-web|dan-token-refresh) ;;
  *) echo "Unsupported component: $COMPONENT" >&2; exit 1 ;;
esac

ASSET_NAME="${COMPONENT}-${OS}-${ARCH}"
LOCAL_BINARY="$COMPONENT"
RELEASE_BASE="$(build_release_base)"
DOWNLOAD_URL="${RELEASE_BASE}/${ASSET_NAME}"
CHECKSUM_URL="${RELEASE_BASE}/SHA256SUMS.txt"

mkdir -p "$INSTALL_DIR/config"

echo "Downloading ${ASSET_NAME}..."
curl -fL "$DOWNLOAD_URL" -o "$INSTALL_DIR/$LOCAL_BINARY"
chmod +x "$INSTALL_DIR/$LOCAL_BINARY"

echo "Downloading SHA256SUMS.txt..."
curl -fL "$CHECKSUM_URL" -o "$INSTALL_DIR/SHA256SUMS.txt"

if command -v sha256sum >/dev/null 2>&1; then
  (
    cd "$INSTALL_DIR"
    grep " ${ASSET_NAME}\$" SHA256SUMS.txt | sed "s#  ${ASSET_NAME}\$#  ${LOCAL_BINARY}#" | sha256sum -c -
  )
elif command -v shasum >/dev/null 2>&1; then
  expected="$(grep " ${ASSET_NAME}\$" "$INSTALL_DIR/SHA256SUMS.txt" | awk '{print $1}')"
  actual="$(shasum -a 256 "$INSTALL_DIR/$LOCAL_BINARY" | awk '{print $1}')"
  [[ "$expected" == "$actual" ]] || { echo "Checksum verification failed." >&2; exit 1; }
else
  echo "No checksum tool found; skipped verification."
fi

cat > "$INSTALL_DIR/config.json" <<EOF
{
  "ak_file": "ak.txt",
  "rk_file": "rk.txt",
  "token_json_dir": "codex_tokens",
  "server_config_url": "",
  "server_api_token": "",
  "domain_report_url": "",
  "upload_api_url": "https://example.com/v0/management/auth-files",
  "upload_api_token": "replace-me",
  "oauth_issuer": "https://auth.openai.com",
  "oauth_client_id": "app_EMoamEEZ73f0CkXaXp7hrann",
  "oauth_redirect_uri": "http://localhost:1455/auth/callback",
  "enable_oauth": true,
  "oauth_required": true
}
EOF

cat > "$INSTALL_DIR/config/web_config.json" <<EOF
{
  "target_min_tokens": 15000,
  "auto_fill_start_gap": 1,
  "check_interval_minutes": 1,
  "manual_default_threads": ${THREADS},
  "manual_register_retries": 3,
  "web_token": "$(json_escape "$WEB_TOKEN")",
  "client_api_token": "$(json_escape "$CLIENT_API_TOKEN")",
  "client_notice": "",
  "minimum_client_version": "",
  "enabled_email_domains": [
    "*.icoa.qzz.io",
    "*.icoe.pp.ua",
    "*.icoa.pp.ua",
    "*.uoou.cc.cd",
    "*.icoa.us.ci",
    "*.ice.qq11.top",
    "*.myanglealtman.tech",
    "*.ice.lyzswx.eu.org",
    "*.ice.aoko.cc.cd",
    "*.ice.aoko.eu.cc",
    "*.ice.chaldea.eu.cc",
    "*.ice.mssk.eu.cc",
    "*.ice.mssk.qzz.io",
    "*.linux.archerguo.de5.net",
    "*.linux.airforceone.online",
    "*.ice.kitakamis.online",
    "*.ice.0987134.xyz",
    "*.ice.icecodex.us.ci",
    "*.ice.oo.oogoo.top",
    "*.ice.jiayou0328.us.ci",
    "*.icecream.707979.xyz",
    "*.ice.help.itbasee.top",
    "*.ice.863973.dpdns.org",
    "*.ice.tinytiger.top",
    "*.ice.yucici.qzz.io",
    "*.love.biaozi.de5.net",
    "*.love.dogge.de5.net",
    "*.love.mobil.dpdns.org",
    "*.love.vercel.dpdns.org",
    "*.love.google.nyc.mn"
  ],
  "mail_domain_options": [
    "*.icoa.qzz.io",
    "*.icoe.pp.ua",
    "*.icoa.pp.ua",
    "*.uoou.cc.cd",
    "*.icoa.ccwu.cc",
    "*.icoa.us.ci",
    "*.ice.qq11.top",
    "*.myanglealtman.tech",
    "*.ice.lyzswx.eu.org",
    "*.ice.aoko.cc.cd",
    "*.ice.aoko.eu.cc",
    "*.ice.chaldea.eu.cc",
    "*.ice.mssk.eu.cc",
    "*.ice.mssk.qzz.io",
    "*.linux.archerguo.de5.net",
    "*.linux.airforceone.online",
    "*.ice.kitakamis.online",
    "*.ice.0987134.xyz",
    "*.ice.icecodex.us.ci",
    "*.ice.icecodex.ccwu.cc",
    "*.ice.oo.oogoo.top",
    "*.ice.jiayou0328.ccwu.cc",
    "*.ice.jiayou0328.us.ci",
    "*.icecream.707979.xyz",
    "*.ice.help.itbasee.top",
    "*.ice.863973.dpdns.org",
    "*.ice.tinytiger.top",
    "*.ice.yucici.qzz.io",
    "*.love.biaozi.de5.net",
    "*.love.dogge.de5.net",
    "*.love.mobil.dpdns.org",
    "*.love.vercel.dpdns.org",
    "*.love.google.nyc.mn"
  ],
  "default_proxy": "http://127.0.0.1:7897",
  "use_registration_proxy": false,
  "cpa_base_url": "$(json_escape "$CPA_BASE_URL")",
  "cpa_token": "$(json_escape "$CPA_TOKEN")",
  "mail_api_url": "$(json_escape "$MAIL_API_URL")",
  "mail_api_key": "$(json_escape "$MAIL_API_KEY")",
  "port": ${PORT}
}
EOF

echo
echo "Installed to: $INSTALL_DIR"
echo "Binary: $INSTALL_DIR/$LOCAL_BINARY"
echo "Config: $INSTALL_DIR/config/web_config.json"
echo
echo "Start command:"
echo "  cd \"$INSTALL_DIR\" && ./${LOCAL_BINARY}"
