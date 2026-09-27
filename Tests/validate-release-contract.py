#!/usr/bin/env python3
from pathlib import Path
import plistlib
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
failures = []

def require(condition, message):
    if not condition:
        failures.append(message)

def read(path):
    return (ROOT / path).read_text(encoding="utf-8")

with (ROOT / "CapturePilot/Info.plist").open("rb") as f:
    info = plistlib.load(f)
with (ROOT / "CapturePilot/PrivacyInfo.xcprivacy").open("rb") as f:
    privacy = plistlib.load(f)
with (ROOT / "CapturePilot/CapturePilot.entitlements").open("rb") as f:
    entitlements = plistlib.load(f)

project = read("CapturePilot.xcodeproj/project.pbxproj")
readme = read("README.md")
testflight = read("docs/TESTFLIGHT.md")

versions = set(re.findall(r"MARKETING_VERSION = ([^;]+);", project))
builds = set(re.findall(r"CURRENT_PROJECT_VERSION = ([^;]+);", project))
require(versions == {"0.9.0"}, f"Expected one marketing version 0.9.0, found {sorted(versions)}")
require(builds == {"9"}, f"Expected one build number 9, found {sorted(builds)}")

require(info.get("ITSAppUsesNonExemptEncryption") is False,
        "ITSAppUsesNonExemptEncryption must remain false unless encryption behavior changes.")
require(bool(info.get("NSCameraUsageDescription")), "Missing NSCameraUsageDescription.")
require(bool(info.get("NSPhotoLibraryAddUsageDescription")), "Missing NSPhotoLibraryAddUsageDescription.")

icloud = entitlements.get("com.apple.developer.icloud-container-identifiers", [])
require("iCloud.com.tiburonns.CapturePilot" in icloud,
        "CapturePilot CloudKit container entitlement is missing.")
require("CloudKit" in entitlements.get("com.apple.developer.icloud-services", []),
        "CloudKit service entitlement is missing.")

require(privacy.get("NSPrivacyTracking") is False, "Privacy manifest must declare tracking=false.")
collected = {
    item.get("NSPrivacyCollectedDataType")
    for item in privacy.get("NSPrivacyCollectedDataTypes", [])
}
require("NSPrivacyCollectedDataTypeUserID" in collected,
        "Privacy manifest must disclose the pseudonymous social user ID.")
require("NSPrivacyCollectedDataTypeOtherUserContent" in collected,
        "Privacy manifest must disclose synchronized score/user-content metadata.")

for token in ("0.9.0 (9)", "English", "Español"):
    require(token in readme, f"README missing release/localization token: {token}")
for token in ("0.9.0 build 9", "## English", "## Español"):
    require(token in testflight, f"TestFlight guide missing token: {token}")

require((ROOT / "LICENSE").exists(), "LICENSE is required for the public repository.")
require((ROOT / "Tests/run-lut-recommendation-tests.sh").exists(),
        "Deterministic LUT recommendation test runner is missing.")
require("Run LUT recommendation tests" in read(".github/workflows/ios-build.yml"),
        "CI must execute deterministic LUT recommendation tests.")

if failures:
    print("CapturePilot release contract FAILED:")
    for failure in failures:
        print(f" - {failure}")
    sys.exit(1)

print("CapturePilot release contract OK: 0.9.0 (9)")
