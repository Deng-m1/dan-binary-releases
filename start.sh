#!/bin/bash

echo "--- Starting dan-web via Official install.sh ---"

# 1. 准备安装目录
INSTALL_DIR="/app/dan-runtime"
mkdir -p "$INSTALL_DIR"

# 2. 准备参数
# 我们将 Railway 的环境变量映射到 install.sh 的参数上
# 注意：我们去掉了 --background 参数，让程序在前台运行，这样 Railway 才能捕获日志
CPA_URL="${CPA_BASE_URL:-https://gpt-up.icoa.pp.ua/}"
CPA_TOKEN_VAL="${CPA_TOKEN:-linuxdo}"
MAIL_URL="${MAIL_API_URL:-https://gpt-mail.icoa.pp.ua/}"
MAIL_KEY_VAL="${MAIL_API_KEY:-linuxdo}"
THREADS_VAL="${THREADS:-20}"

echo "[INFO] Running official install.sh with provided parameters..."

# 3. 执行官方安装脚本
# 我们直接从 GitHub 获取最新的 install.sh 并执行
# 注意：我们不使用 --background，这样程序会直接在前台运行并输出日志
curl -fsSL https://raw.githubusercontent.com/uton88/dan-binary-releases/main/install.sh | bash -s -- \
    --install-dir "$INSTALL_DIR" \
    --cpa-base-url "$CPA_URL" \
    --cpa-token "$CPA_TOKEN_VAL" \
    --mail-api-url "$MAIL_URL" \
    --mail-api-key "$MAIL_KEY_VAL" \
    --threads "$THREADS_VAL"

# 4. 如果 install.sh 退出（正常情况下它会一直运行 dan-web），打印状态
EXIT_CODE=$?
echo "[INFO] dan-web process exited with code $EXIT_CODE"
sleep 5
