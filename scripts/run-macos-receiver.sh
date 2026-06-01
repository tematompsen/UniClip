#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../apps/macos"
swift run uniclip-mac
