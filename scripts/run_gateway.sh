#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source .venv/bin/activate
pip install -r gateway/requirements.txt
python gateway/app.py
