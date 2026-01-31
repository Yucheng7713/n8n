#!/bin/bash

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "5m",
    "max-file": "2"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": {
      "hard": 65536,
      "soft": 65536
    }
  }
}
EOF

sudo systemctl restart docker