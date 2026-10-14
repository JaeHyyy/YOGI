# Cursor Cloud Agent용 — Flutter 웹 + cloudflared
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:/usr/local/bin:${PATH}"
ENV PUB_CACHE=/home/ubuntu/.pub-cache

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    ca-certificates \
    sudo \
    libglu1-mesa \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Flutter SDK (web)
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 ${FLUTTER_HOME} \
    && flutter config --no-analytics \
    && flutter precache --web

# 임시 공개 URL용 (phone에서 볼 때)
RUN curl -fsSL -o /usr/local/bin/cloudflared \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    && chmod +x /usr/local/bin/cloudflared

# Cursor가 쓰는 non-root 유저
RUN id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu \
    && usermod -aG sudo ubuntu \
    && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
    && mkdir -p /home/ubuntu/.pub-cache \
    && chown -R ubuntu:ubuntu /home/ubuntu ${FLUTTER_HOME}
