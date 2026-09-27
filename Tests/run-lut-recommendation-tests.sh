#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

swiftc \
  "$ROOT_DIR/Tests/LUTRecommendationTests.swift" \
  "$ROOT_DIR/CapturePilot/Coach/LUTRecommendationEngine.swift" \
  -o "$BUILD_DIR/CapturePilotLUTRecommendationTests"

"$BUILD_DIR/CapturePilotLUTRecommendationTests"
