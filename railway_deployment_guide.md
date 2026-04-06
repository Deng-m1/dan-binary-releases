# 在 Railway 上部署 `dan-web` 二进制程序的指南

本指南将详细介绍如何在 Railway 平台上部署 `dan-web` 二进制程序。由于 `dan-web` 是一个预编译的 Go 语言二进制文件，使用 Dockerfile 是最推荐和最灵活的部署方式。

## 1. 部署概述

Railway 是一个现代化的 PaaS (Platform as a Service) 平台，支持通过 Git 仓库自动部署。对于像 `dan-web` 这样的二进制程序，我们可以通过自定义 Dockerfile 来构建一个包含该程序的 Docker 镜像，然后 Railway 会自动拉取并运行这个镜像。

核心思路是：
1.  创建一个 GitHub 仓库，包含 `dan-web` 的 Dockerfile 和启动脚本。
2.  在 Dockerfile 中，下载 `dan-web` 二进制文件并设置运行环境。
3.  编写一个 `start.sh` 脚本，用于在容器启动时根据 Railway 的环境变量生成 `dan-web` 所需的配置文件，并启动程序。
4.  将该 GitHub 仓库连接到 Railway 项目，并配置必要的环境变量和持久化存储。

## 2. 准备工作

在开始部署之前，请确保您已完成以下准备：

*   **Railway 账户**：拥有一个活跃的 Railway 账户。
*   **GitHub 仓库**：创建一个新的 GitHub 仓库，用于存放 Dockerfile 和启动脚本。
*   **`dan-web` 二进制文件**：虽然 Dockerfile 会自动下载，但了解其来源（`uton88/dan-binary-releases`）是必要的。

## 3. Dockerfile 编写

在您的 GitHub 仓库根目录创建名为 `Dockerfile` 的文件，并添加以下内容：

```dockerfile
FROM ubuntu:22.04

# 安装必要的工具和依赖
# curl 用于下载二进制文件
# ca-certificates 用于 HTTPS 连接
# jq 用于可能的 JSON 处理（如果启动脚本需要）
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 下载 dan-web 二进制文件
# 这里直接从 GitHub Releases 下载最新的 Linux amd64 版本
RUN curl -fL https://github.com/uton88/dan-binary-releases/releases/latest/download/dan-web-linux-amd64 -o dan-web && \
    chmod +x dan-web

# 复制启动脚本到容器中
COPY start.sh .

# 暴露程序端口 (dan-web 默认使用 25666，但 Railway 会通过 PORT 环境变量覆盖)
EXPOSE 25666

# 定义容器启动时执行的命令
CMD ["/app/start.sh"]
```

**说明**：
*   我们使用 `ubuntu:22.04` 作为基础镜像，因为它包含了 `apt-get` 包管理器，方便安装 `curl` 和 `ca-certificates`。
*   `WORKDIR /app` 将容器的工作目录设置为 `/app`。
*   `curl` 命令直接从 `uton88/dan-binary-releases` 的最新发布中下载 `dan-web-linux-amd64` 二进制文件，并赋予执行权限。
*   `COPY start.sh .` 将您本地的 `start.sh` 脚本复制到容器的 `/app` 目录下。
*   `EXPOSE 25666` 声明了容器将监听 25666 端口，但实际运行时 Railway 会注入 `PORT` 环境变量，程序应监听该变量指定的端口。
*   `CMD ["/app/start.sh"]` 指定容器启动时执行 `start.sh` 脚本。

## 4. 启动脚本 `start.sh` 编写

在您的 GitHub 仓库根目录创建名为 `start.sh` 的文件，并添加以下内容：

```bash
#!/bin/bash
set -euo pipefail

INSTALL_DIR="/app"
LOCAL_BINARY="dan-web"

# 从环境变量获取配置，如果未设置则使用默认值
# Railway 会自动注入 PORT 环境变量，程序应监听此端口
CPA_BASE_URL="${CPA_BASE_URL:-https://gpt-up.icoa.pp.ua/}"
CPA_TOKEN="${CPA_TOKEN:-linuxdo}"
MAIL_API_URL="${MAIL_API_URL:-https://gpt-mail.icoa.pp.ua/}"
MAIL_API_KEY="${MAIL_API_KEY:-linuxdo}"
THREADS="${THREADS:-20}"
WEB_TOKEN="${WEB_TOKEN:-linuxdo}"
CLIENT_API_TOKEN="${CLIENT_API_TOKEN:-linuxdo}"
PORT="${PORT:-25666}" # 使用 Railway 注入的 PORT 环境变量
DEFAULT_PROXY="${DEFAULT_PROXY:-}"

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
  "enabled_email_domains": [], # 注意：这里硬编码为空数组，因为您的 CPA 不提供此接口
  "mail_domain_options": [],   # 注意：这里硬编码为空数组，因为您的 CPA 不提供此接口
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
```

**说明**：
*   这个脚本会读取 Railway 注入的环境变量（如 `PORT`）以及您在 Railway 项目中配置的其他环境变量。
*   它会根据这些环境变量动态生成 `config.json` 和 `config/web_config.json` 文件。
*   **重要提示**：由于您当前的 CPA 地址不提供 `/v0/management/domains` 接口，我在 `web_config.json` 中将 `enabled_email_domains` 和 `mail_domain_options` 硬编码为空数组 `[]`。这意味着 `dan-web` 在启动时不会尝试从 CPA 获取域名列表，从而避免了 404 错误。如果 `dan-web` 的核心功能依赖于这些域名列表，您可能需要手动填充它们或寻找一个提供该接口的 CPA 服务。
*   `exec "$INSTALL_DIR/$LOCAL_BINARY"` 会启动 `dan-web` 程序，并将其进程替换为当前 shell 进程，确保信号能够正确传递。

## 5. Railway 部署配置

1.  **创建新项目**：登录 Railway，创建一个新项目，并选择“Deploy from Git Repo”。
2.  **连接 GitHub 仓库**：选择您刚刚创建并上传了 `Dockerfile` 和 `start.sh` 的 GitHub 仓库。
3.  **服务设置**：
    *   **Build Command**：通常 Railway 会自动检测 Dockerfile，无需手动设置。如果需要，可以指定为 `docker build . -t my-dan-web`。
    *   **Start Command**：无需设置，因为 `CMD` 在 Dockerfile 中已定义。
    *   **Root Directory**：如果您的 Dockerfile 不在仓库根目录，请指定其路径。
4.  **环境变量**：在 Railway 项目的“Variables”选项卡中，添加以下环境变量。这些变量将覆盖 `start.sh` 脚本中的默认值：

    | 变量名             | 值                                     | 描述                                     |
    | :----------------- | :------------------------------------- | :--------------------------------------- |
    | `CPA_BASE_URL`     | `http://36.137.180.12:8317/`           | 您的 CPA 服务地址。                      |
    | `CPA_TOKEN`        | `977bdedaeaacbe5f591202a47e055a33`     | 您的 CPA 密钥。                          |
    | `MAIL_API_URL`     | `https://gpt-mail.icoa.pp.ua/`         | 邮件 API 地址。                          |
    | `MAIL_API_KEY`     | `linuxdo`                              | 邮件 API 密钥。                          |
    | `THREADS`          | `20`                                   | 运行线程数。                             |
    | `WEB_TOKEN`        | `linuxdo`                              | Web 界面令牌。                           |
    | `CLIENT_API_TOKEN` | `linuxdo`                              | 客户端 API 令牌。                        |
    | `DEFAULT_PROXY`    | `(可选，例如 socks5://user:pass@host:port)` | 如果需要，设置代理。                     |
    | `PORT`             | (由 Railway 自动注入，无需手动设置)   | 程序监听的端口。                         |

5.  **持久化存储 (Volumes)**：
    如果 `dan-web` 需要保存状态、日志或 Token 文件（如 `ak.txt`, `rk.txt`, `codex_tokens` 目录），您需要配置一个持久化存储卷。在 Railway 项目的“Volumes”选项卡中，创建一个新的 Volume，并将其挂载路径设置为 `/app` 或 `/app/dan-runtime`（取决于您希望持久化哪些数据）。
    *   **注意**：Railway 的免费计划通常对 Volumes 有限制，或者需要付费计划才能使用。

6.  **部署**：完成上述配置后，Railway 将自动开始构建和部署您的服务。您可以在部署日志中查看构建和运行状态。

## 6. 重要注意事项

*   **端口冲突**：确保 `dan-web` 实际监听的端口与 Railway 注入的 `PORT` 环境变量一致。`start.sh` 脚本已经处理了这一点。
*   **日志查看**：部署后，请务必查看 Railway 提供的服务日志，以确认 `dan-web` 是否正常启动并运行。
*   **资源限制**：Railway 对免费或低成本计划有 CPU、内存和带宽限制。如果 `dan-web` 消耗资源较多，可能会导致服务不稳定或被限流。
*   **风控与合规**：如前所述，`dan-web` 涉及自动化操作，可能违反某些服务提供商的使用条款。Railway 平台本身也可能有针对滥用行为的检测机制，请谨慎使用。

按照以上步骤操作，您应该能够在 Railway 上成功部署 `dan-web` 程序。如果在部署过程中遇到任何问题，请检查 Railway 的部署日志和您的环境变量配置。
