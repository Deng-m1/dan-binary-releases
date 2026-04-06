FROM ubuntu:22.04

# 安装必要的工具和依赖
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    jq \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 创建一个虚拟环境并安装必要的 Python 包
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir Jinja2

# 下载 dan-web 二进制文件
RUN curl -fL https://github.com/uton88/dan-binary-releases/releases/latest/download/dan-web-linux-amd64 -o dan-web && \
    chmod +x dan-web

# 复制启动脚本并赋予执行权限
COPY start.sh .
RUN chmod +x start.sh

# 暴露程序端口 (Railway 会通过 PORT 环境变量覆盖)
EXPOSE 25666

# 启动程序
CMD ["/app/start.sh"]
