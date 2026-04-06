#!/bin/bash
set -euo pipefail

INSTALL_DIR="/app"
LOCAL_BINARY="dan-web"

# 从环境变量获取配置，如果未设置则使用默认值
CPA_BASE_URL="${CPA_BASE_URL:-https://gpt-up.icoa.pp.ua/}"
CPA_TOKEN="${CPA_TOKEN:-linuxdo}"
MAIL_API_URL="${MAIL_API_URL:-https://gpt-mail.icoa.pp.ua/}"
MAIL_API_KEY="${MAIL_API_KEY:-linuxdo}"
THREADS="${THREADS:-20}"
WEB_TOKEN="${WEB_TOKEN:-linuxdo}"
CLIENT_API_TOKEN="${CLIENT_API_TOKEN:-linuxdo}"
# Railway 会注入 PORT 环境变量，使用它作为程序的监听端口
PORT="${PORT:-25666}"
DEFAULT_PROXY="${DEFAULT_PROXY:-}"

# 辅助函数：JSON 字符串转义
json_escape() {
  local value="${1-}"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$\'\\n\'/\\n}
  value=${value//$\'\\r\'/\\r}
  value=${value//$\'\\t\'/\\t}
  printf '%s' "$value"
}

# 生成 config.json
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

# 生成 config/web_config.json
mkdir -p "$INSTALL_DIR/config"
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
  "enabled_email_domains": [],
  "mail_domain_options": [],
  "default_proxy": "$(json_escape "$DEFAULT_PROXY")",
  "use_registration_proxy": $([[ -n "${DEFAULT_PROXY// }" ]] && printf 'true' || printf 'false'),
  "cpa_base_url": "$(json_escape "$CPA_BASE_URL")",
  "cpa_token": "$(json_escape "$CPA_TOKEN")",
  "mail_api_url": "$(json_escape "$MAIL_API_URL")",
  "mail_api_key": "$(json_escape "$MAIL_API_KEY")",
  "port": ${PORT}
}
EOF

# 启动 dan-web 程序
exec "$INSTALL_DIR/$LOCAL_BINARY"
