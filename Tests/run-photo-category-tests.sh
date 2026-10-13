#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

swiftc \
  "$ROOT_DIR/Tests/PhotoCategoryTests.swift" \
  "$ROOT_DIR/CapturePilot/Ranking/RankingModels.swift" \
  -o "$BUILD_DIR/CapturePilotPhotoCategoryTests"

"$BUILD_DIR/CapturePilotPhotoCategoryTests"
