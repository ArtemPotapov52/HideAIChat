#!/bin/bash
cd ~/notion2api || { echo "notion2api not found at ~/notion2api"; exit 1; }
source .venv/bin/activate
exec python3 -m uvicorn app.server:app --host 0.0.0.0 --port 8000
