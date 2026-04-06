#!/bin/sh

echo "--- Starting dan-web Startup Script ---"

# 1. 基础配置
INSTALL_DIR="${INSTALL_DIR:-$HOME/dan-runtime}"
mkdir -p "$INSTALL_DIR/config"
cd "$INSTALL_DIR"

# 2. 准备配置文件
if [ ! -f "web_config.json" ]; then
    echo "[INFO] Creating web_config.json..."
    cat > web_config.json <<EOC
{
  "port": ${PORT:-25666},
  "threads": ${THREADS:-20},
  "cpa_base_url": "${CPA_BASE_URL:-https://gpt-up.icoa.pp.ua/}",
  "cpa_token": "${CPA_TOKEN:-linuxdo}",
  "mail_api_url": "${MAIL_API_URL:-https://gpt-mail.icoa.pp.ua/}",
  "mail_api_key": "${MAIL_API_KEY:-linuxdo}",
  "enabled_email_domains": [],
  "mail_domain_options": []
}
EOC
else
    echo "[INFO] web_config.json already exists. Updating with environment variables..."
    # 使用 python 脚本来安全地更新 JSON，避免 sed 转义问题
    python3 -c "
import json, os
with open('web_config.json', 'r') as f:
    data = json.load(f)
data['port'] = int(os.getenv('PORT', data.get('port', 25666)))
data['threads'] = int(os.getenv('THREADS', data.get('threads', 20)))
data['cpa_base_url'] = os.getenv('CPA_BASE_URL', data.get('cpa_base_url', 'https://gpt-up.icoa.pp.ua/'))
data['cpa_token'] = os.getenv('CPA_TOKEN', data.get('cpa_token', 'linuxdo'))
data['mail_api_url'] = os.getenv('MAIL_API_URL', data.get('mail_api_url', 'https://gpt-mail.icoa.pp.ua/'))
data['mail_api_key'] = os.getenv('MAIL_API_KEY', data.get('mail_api_key', 'linuxdo'))
with open('web_config.json', 'w') as f:
    json.dump(data, f, indent=2)
"
fi

# 3. 动态获取域名列表（如果 CPA 地址有效）
echo "[INFO] Fetching domains from ${CPA_BASE_URL}v0/management/domains..."
DOMAINS_JSON=$(curl -s -f -H "Authorization: Bearer ${CPA_TOKEN}" "${CPA_BASE_URL}v0/management/domains")
if [ $? -eq 0 ] && [ -n "$DOMAINS_JSON" ]; then
    echo "[INFO] Successfully fetched domains. Updating config..."
    python3 -c "
import json, sys
domains = json.loads(sys.argv[1]).get('domains', [])
with open('web_config.json', 'r') as f:
    data = json.load(f)
data['enabled_email_domains'] = domains
data['mail_domain_options'] = domains
with open('web_config.json', 'w') as f:
    json.dump(data, f, indent=2)
" "$DOMAINS_JSON"
else
    echo "[WARN] Failed to fetch domains from CPA. Using existing or empty list."
fi

# 4. 启动程序
echo "[INFO] Launching dan-web binary on port ${PORT:-25666}..."
exec ./dan-web
