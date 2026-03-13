#!/usr/bin/env bash
set -euo pipefail

curl -sS -X POST 'http://127.0.0.1:8080/moderate' \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "测试标题",
    "text": "这是一条论坛测试内容",
    "images": ["https://aliyun.com/240308/test001.jpg"],
    "comments": []
  }'
