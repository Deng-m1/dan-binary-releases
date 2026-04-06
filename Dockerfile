FROM ubuntu:22.04

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    bash \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制启动脚本
COPY start.sh .
RUN chmod +x start.sh

# 暴露程序端口 (Railway 会通过 PORT 环境变量覆盖)
EXPOSE 25666

# 启动程序
CMD ["/app/start.sh"]
