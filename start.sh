#!/bin/bash

echo "--- Starting dan-web via Modified Local install.sh ---"

# 1. 准备安装目录
INSTALL_DIR="/app/dan-runtime"
mkdir -p "$INSTALL_DIR"

# 2. 准备参数
CPA_URL="${CPA_BASE_URL:-https://gpt-up.icoa.pp.ua/}"
CPA_TOKEN_VAL="${CPA_TOKEN:-linuxdo}"
MAIL_URL="${MAIL_API_URL:-https://gpt-mail.icoa.pp.ua/}"
MAIL_KEY_VAL="${MAIL_API_KEY:-linuxdo}"
THREADS_VAL="${THREADS:-20}"

echo "[INFO] Running modified local install.sh with provided parameters..."

# 3. 执行本地修改后的安装脚本
# 注意：我们去掉了 --background，让程序在前台运行
./install.sh \
    --install-dir "$INSTALL_DIR" \
    --cpa-base-url "$CPA_URL" \
    --cpa-token "$CPA_TOKEN_VAL" \
    --mail-api-url "$MAIL_URL" \
    --mail-api-key "$MAIL_KEY_VAL" \
    --threads "$THREADS_VAL"

# 4. 如果脚本退出，打印状态
EXIT_CODE=$?
echo "[INFO] dan-web process exited with code $EXIT_CODE"
sleep 5
