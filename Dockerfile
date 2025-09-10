# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# 设置环境变量以支持systemd
ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/etc/poetry/bin:$PATH"



# 安装systemd相关依赖
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    libpam-systemd \
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
    libvirt-clients

# Use update-alternatives to set python3.10 as the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# 禁用不需要的服务
RUN systemctl set-default multi-user.target

# Set the working directory to /home/cuckoo
WORKDIR /home/installer

# Copy the requirements file into the container at /home/cape
COPY CAPEv2/installer/* /home/installer

# Install CAPEv2
RUN chmod a+x ./cape2.sh \
    && sudo ./cape2.sh base cape \
    && sudo ./cape2.sh all cape

# Install VirtualBox
COPY bin/vbox-client /usr/bin/VBoxManage

# Clean up
RUN rm -rf /home/installer

# Add the cape user to the sudo group
RUN usermod -aG sudo cape \
    && echo "cape ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/cape

# Set the password for the cape user
RUN echo "cape:cape" | chpasswd

# Copy the entrypoint script into the container at /home/cape
COPY scripts/entrypoint.sh /home/cape/entrypoint.sh
COPY scripts/cape-entry.service /etc/systemd/system/cape-entry.service

# enable the service
RUN systemctl enable cape-entry.service

USER cape

# Set the working directory to /opt/CAPEv2
WORKDIR /opt/CAPEv2

# Install dependencies
RUN poetry install

USER root

# 设置systemd入口点
ENTRYPOINT ["/sbin/init"]
