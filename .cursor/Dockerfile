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

# Cursor가 쓰는 non-root 유저 (Flutter clone 전에 준비)
RUN id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu \
    && usermod -aG sudo ubuntu \
    && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
    && mkdir -p /home/ubuntu/.pub-cache \
    && chown -R ubuntu:ubuntu /home/ubuntu

# Flutter SDK (web) — root로 clone 후 ubuntu에 넘김
# install 단계에서 git "dubious ownership"으로 깨지지 않게 system safe.directory 등록
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 ${FLUTTER_HOME} \
    && git config --system --add safe.directory ${FLUTTER_HOME} \
    && chown -R ubuntu:ubuntu ${FLUTTER_HOME} \
    && ln -sf ${FLUTTER_HOME}/bin/flutter /usr/local/bin/flutter \
    && ln -sf ${FLUTTER_HOME}/bin/dart /usr/local/bin/dart \
    && sudo -u ubuntu flutter config --no-analytics \
    && sudo -u ubuntu flutter precache --web

# 임시 공개 URL용 (phone에서 볼 때)
RUN curl -fsSL -o /usr/local/bin/cloudflared \
    https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    && chmod +x /usr/local/bin/cloudflared
