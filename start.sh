#!/bin/sh

# 强制实时输出日志，禁用缓冲
export PYTHONUNBUFFERED=1

echo "--- Starting dan-web Startup Script ---"

# 1. 基础配置
INSTALL_DIR="${INSTALL_DIR:-$HOME/dan-runtime}"
mkdir -p "$INSTALL_DIR/config"
cd "$INSTALL_DIR"

# 2. 准备配置文件
TARGET_PORT=25666

if [ ! -f "web_config.json" ]; then
    echo "[INFO] Creating web_config.json..."
    cat > web_config.json <<EOC
{
  "port": $TARGET_PORT,
  "threads": ${THREADS:-20},
  "cpa_base_url": "${CPA_BASE_URL:-https://gpt-up.icoa.pp.ua/}",
  "cpa_token": "${CPA_TOKEN:-linuxdo}",
  "mail_api_url": "${MAIL_API_URL:-https://gpt-mail.icoa.pp.ua/}",
  "mail_api_key": "${MAIL_API_KEY:-linuxdo}",
  "enabled_email_domains": ["miaobixiezuo.com"],
  "mail_domain_options": ["miaobixiezuo.com"]
}
EOC
else
    echo "[INFO] web_config.json already exists. Updating with environment variables..."
    python3 -c "\
import json, os\
with open('web_config.json', 'r') as f:\
    data = json.load(f)\
data['port'] = $TARGET_PORT\
data['threads'] = int(os.getenv('THREADS', data.get('threads', 20)))\
data['cpa_base_url'] = os.getenv('CPA_BASE_URL', data.get('cpa_base_url', 'https://gpt-up.icoa.pp.ua/'))\
data['cpa_token'] = os.getenv('CPA_TOKEN', data.get('cpa_token', 'linuxdo'))\
data['mail_api_url'] = os.getenv('MAIL_API_URL', data.get('mail_api_url', 'https://gpt-mail.icoa.pp.ua/'))\
data['mail_api_key'] = os.getenv('MAIL_API_KEY', data.get('mail_api_key', 'linuxdo'))\
# 强制设置域名，不再从 CPA 获取\
data['enabled_email_domains'] = ['miaobixiezuo.com']\
data['mail_domain_options'] = ['miaobixiezuo.com']\
with open('web_config.json', 'w') as f:\
    json.dump(data, f, indent=2)\
"
fi

# 3. 打印配置以供调试
echo "[DEBUG] Current web_config.json content:"
cat web_config.json

# 4. 连通性预检 (Connectivity Check)
echo "[INFO] Pre-launch connectivity check..."
echo "Checking CPA_BASE_URL: ${CPA_BASE_URL:-https://gpt-up.icoa.pp.ua/}"
curl -Is "${CPA_BASE_URL:-https://gpt-up.icoa.pp.ua/}" | head -n 1 || echo "[WARN] CPA_BASE_URL check failed."

echo "Checking MAIL_API_URL: ${MAIL_API_URL:-https://mail-api.miaobixiezuo.com/v0/messages}"
curl -Is "${MAIL_API_URL:-https://mail-api.miaobixiezuo.com/v0/messages}" | head -n 1 || echo "[WARN] MAIL_API_URL check failed."

# 5. 启动程序
echo "[INFO] Launching dan-web binary on port $TARGET_PORT..."
echo "[DEBUG] Executing command: /app/dan-web"

# 启动 dan-web 并捕获所有输出
# 我们不再使用 exec，而是直接运行，这样可以在程序退出后打印额外信息
/app/dan-web 2>&1 | stdbuf -oL -eL cat

# 如果程序意外退出，打印退出状态
EXIT_CODE=$?
echo "[ERROR] dan-web process exited with code $EXIT_CODE"
if [ $EXIT_CODE -ne 0 ]; then
    echo "[DEBUG] Checking if binary exists and is executable..."
    ls -l /app/dan-web
    ldd /app/dan-web || echo "[WARN] Could not run ldd on binary."
fi

# 保持容器运行一段时间，以便查看错误日志
sleep 10
