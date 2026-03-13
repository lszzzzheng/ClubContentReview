#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/release"
PKG_NAME="club-content-review-handoff-$(date +%Y%m%d-%H%M%S).tar.gz"

mkdir -p "$OUT_DIR"
cd "$ROOT_DIR"

tar -czf "$OUT_DIR/$PKG_NAME" \
  deliverables/moderation-gateway \
  deliverables/discourse-aliyun-moderation \
  deliverables/README_HANDOFF.md \
  docs/deploy/DEPLOYMENT_GUIDE.md

echo "$OUT_DIR/$PKG_NAME"
