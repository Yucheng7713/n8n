#!/bin/bash

docker system prune -af --filter "until=24h" > /dev/null 2>&1
find ~/n8n-data/.n8n/executions -type f -mtime +1 -delete > /dev/null 2>&1
journalctl --vacuum-time=2d > /dev/null 2>&1