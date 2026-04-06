# 在 Railway 上部署 `dan-web` 二进制程序的指南

本指南将详细介绍如何在 Railway 平台上部署 `dan-web` 二进制程序。

## 1. 部署概述
Railway 是一个现代化的 PaaS 平台。对于 `dan-web` 这样的二进制程序，我们通过自定义 Dockerfile 来构建镜像并运行。

## 2. Railway 关键配置 (重要)

在 Railway 控制台部署后，请务必进行以下设置：

### 网络配置 (Networking)
1.  进入服务的 **"Settings"** -> **"Networking"**。
2.  在 **"Public Networking"** 部分，点击 **"Generate Service Domain"**。
3.  在 **"Target Port"** 输入框中，填入 **`25666`**。
    *   *说明：这是程序在容器内监听的默认端口。Railway 会自动将公网 80/443 端口的流量转发到此端口。*
4.  保存后，您将获得一个 `xxx.up.railway.app` 的访问地址。

### 环境变量 (Variables)
在 **"Variables"** 选项卡中，您可以根据需要添加以下变量：
*   `CPA_BASE_URL`: 您的 CPA 服务地址（默认为作者地址）。
*   `CPA_TOKEN`: 您的 CPA 密钥。
*   `WEB_TOKEN`: 访问 Web 界面的密码（默认为 `linuxdo`）。
*   `THREADS`: 并发线程数（默认为 `20`）。

## 3. 邮件系统配置 (Cloudflare Worker)
我已经为您在 Cloudflare 上部署了邮件解析 Worker。
*   **API 地址**: `https://mail-api.miaobixiezuo.com/v0/messages`
*   **手动步骤**: 请确保您已在 Cloudflare 控制台完成以下操作：
    1.  在 **"dan-mail-api"** Worker 的设置中，绑定自定义域名 `mail-api.miaobixiezuo.com`。
    2.  在 **"Email Routing"** 中，将 **"Catch-all"** 路由指向该 Worker。

## 4. 自定义域名 (可选)
如果您想使用 `dan.miaobixiezuo.com` 访问：
1.  在 Railway 服务设置中添加 **"Custom Domain"**。
2.  将 Cloudflare 中的 `dan` 子域名设置为 **CNAME**，指向 Railway 提供的目标地址。

按照以上步骤操作，您的自动化注册系统即可正式上线。
