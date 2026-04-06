#!/bin/bash
set -euo pipefail

INSTALL_DIR="/app"
LOCAL_BINARY="dan-web"

# 从环境变量获取配置，如果未设置则使用默认值
CPA_BASE_URL="${CPA_BASE_URL:-https://gpt-up.icoa.pp.ua/}"
CPA_TOKEN="${CPA_TOKEN:-linuxdo}"
# 自动填入您刚配置好的 Cloudflare Worker 地址
MAIL_API_URL="${MAIL_API_URL:-https://mail-api.miaobixiezuo.com/v0/messages}"
MAIL_API_KEY="${MAIL_API_KEY:-linuxdo}"
THREADS="${THREADS:-20}"
WEB_TOKEN="${WEB_TOKEN:-linuxdo}"
CLIENT_API_TOKEN="${CLIENT_API_TOKEN:-linuxdo}"
PORT="${PORT:-25666}"
DEFAULT_PROXY="${DEFAULT_PROXY:-}"
DEFAULT_DOMAINS_API_URL="https://gpt-up.icoa.pp.ua/v0/management/domains"

# 辅助函数：JSON 字符串转义
json_escape() {
  local value="${1-}"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

trim() {
  printf '%s' "${1-}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

resolve_domains_api_url() {
  local base
  base="$(trim "${CPA_BASE_URL:-}")"
  if [[ -z "$base" ]]; then
    printf '%s' "$DEFAULT_DOMAINS_API_URL"
    return
  fi
  base="${base%/}"
  if [[ "$base" == */v0/management/domains ]]; then
    printf '%s' "$base"
  elif [[ "$base" == */v0/management ]]; then
    printf '%s/domains' "$base"
  else
    printf '%s/v0/management/domains' "$base"
  fi
}

fetch_domains_json() {
  local url raw compact domains
  url="$1"
  raw="$(curl -fsSL "$url")" || {
    echo "Failed to fetch domains from ${url}" >&2
    exit 1
  }
  compact="$(printf '%s' "$raw" | tr -d '\r\n')"
  domains="$(printf '%s' "$compact" | sed -n 's/.*"domains"[[:space:]]*:[[:space:]]*\(\[[^]]*]\).*/\1/p')"
  if [[ -z "$domains" ]]; then
    echo "Domains API returned an invalid payload: $raw" >&2
    exit 1
  fi
  printf '%s' "$domains"
}

# 获取域名列表
DOMAINS_API_URL="$(resolve_domains_api_url)"
echo "Fetching domains from ${DOMAINS_API_URL}..."
DOMAINS_JSON="$(fetch_domains_json "$DOMAINS_API_URL")"

# 生成 config.json
cat > "$INSTALL_DIR/config.json" <<EOC
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
EOC

# 生成 config/web_config.json
mkdir -p "$INSTALL_DIR/config"
cat > "$INSTALL_DIR/config/web_config.json" <<EOW
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
EOW

# 启动 dan-web 程序
exec "$INSTALL_DIR/$LOCAL_BINARY"
