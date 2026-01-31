#!/bin/bash

# 1. 增加 swap 到 3GB (AI agent 可能需要更多)
sudo swapoff -a
sudo rm -f /swapfile
sudo fallocate -l 3G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 2. 優化記憶體管理
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
# Memory management for AI workloads
vm.swappiness=5
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5

# Network optimization
net.core.somaxconn=1024
net.ipv4.tcp_max_syn_backlog=2048
net.ipv4.ip_local_port_range=1024 65535
EOF

sudo sysctl -p