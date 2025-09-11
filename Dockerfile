# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# 设置环境变量以支持systemd
ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/etc/poetry/bin:$PATH"



# 安装systemd相关依赖
RUN apt-get update && apt-get install -y \
    lsb-core \
    tzdata \
    python3.10 \
    python3.10-dev \
    curl \
    gcc \
    g++ \
    make \
    libmagic1 \
    p7zip-full \
    git \
    tcpdump \
    sudo \
    libvirt-dev \
    pkg-config \
    libvirt-daemon-system \
    libvirt-clients \
    supervisor \
    vim

# Use update-alternatives to set python3.10 as the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# 创建supervisor配置目录
RUN mkdir -p /etc/supervisor/conf.d

# Set the working directory to /home/cuckoo
WORKDIR /home/installer

# Copy the requirements file into the container at /home/cape
COPY CAPEv2/installer/* /home/installer

# Install CAPEv2
RUN chmod a+x ./cape2-docker.sh \
    && sudo ./cape2-docker.sh base cape \
    && sudo ./cape2-docker.sh all cape

# Clean up
RUN rm -rf /home/installer

# Add the cape user to the sudo group
RUN usermod -aG sudo cape \
    && echo "cape ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/cape

# Set the password for the cape user
RUN echo "cape:cape" | chpasswd

USER cape

# Set the working directory to /opt/CAPEv2
WORKDIR /opt/CAPEv2

# 调试信息
RUN echo "Current user: $(whoami)"
RUN echo "Directory contents:" && ls -la
RUN echo "Poetry config:" && poetry config --list
RUN echo "Checking pyproject.toml:" && poetry check
RUN poetry cache clear pypi --all

# 安装依赖（详细模式）
RUN poetry install -vvv || (echo "=== Poetry Debug Info ===" && poetry show && echo "=== Environment ===" && env && exit 1)

USER root

COPY scripts/supervisord.conf /etc/supervisor/supervisord.conf

# 设置supervisor为入口点
ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisor/supervisord.conf"]
