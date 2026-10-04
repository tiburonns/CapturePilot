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
require(versions == {"0.9.2"}, f"Expected one marketing version 0.9.2, found {sorted(versions)}")
require(builds == {"11"}, f"Expected one build number 11, found {sorted(builds)}")

require(info.get("ITSAppUsesNonExemptEncryption") is False,
        "ITSAppUsesNonExemptEncryption must remain false unless encryption behavior changes.")
require(bool(info.get("NSCameraUsageDescription")), "Missing NSCameraUsageDescription.")
require(bool(info.get("NSPhotoLibraryAddUsageDescription")), "Missing NSPhotoLibraryAddUsageDescription.")
require(info.get("UIRequiresFullScreen") is True, "CapturePilot must remain full-screen on iPhone.")
require(info.get("UIStatusBarHidden") is True, "CapturePilot camera UI expects the status bar hidden.")
require(info.get("LSRequiresIPhoneOS") is True, "CapturePilot must require iPhoneOS.")
require(info.get("CFBundleDisplayName") == "CapturePilot", "Unexpected CFBundleDisplayName.")

expected_orientations = {
    "UIInterfaceOrientationPortrait",
    "UIInterfaceOrientationPortraitUpsideDown",
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
}
require(
    set(info.get("UISupportedInterfaceOrientations", [])) == expected_orientations,
    "Info.plist must expose all four CapturePilot orientations; in-app policy may disable optional ones."
)

icloud = entitlements.get("com.apple.developer.icloud-container-identifiers", [])
require("iCloud.com.tiburonns.CapturePilot" in icloud,
        "CapturePilot CloudKit container entitlement is missing.")
require("CloudKit" in entitlements.get("com.apple.developer.icloud-services", []),
        "CloudKit service entitlement is missing.")

require(
    "PRODUCT_BUNDLE_IDENTIFIER = com.tiburonns.CapturePilot;" in project,
    "Unexpected product bundle identifier."
)
require(
    "TARGETED_DEVICE_FAMILY = 1;" in project,
    "CapturePilot release target must remain iPhone-only."
)
require(
    "IPHONEOS_DEPLOYMENT_TARGET = 17.0;" in project,
    "Expected iOS 17.0 minimum deployment target."
)
require(
    "CODE_SIGN_ENTITLEMENTS = CapturePilot/CapturePilot.entitlements;" not in project,
    "Default 0.9.2 target must not attach CloudKit entitlements."
)
require(
    "CAPTUREPILOT_CLOUDKIT" not in project,
    "Default 0.9.2 target must not compile the CloudKit social feature."
)
require(
    "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;" in project,
    "Release target must use the AppIcon asset catalog."
)
require(
    (ROOT / "CapturePilot/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png").exists(),
    "1024x1024 App Store icon source is missing."
)

require(privacy.get("NSPrivacyTracking") is False, "Privacy manifest must declare tracking=false.")
collected = {
    item.get("NSPrivacyCollectedDataType")
    for item in privacy.get("NSPrivacyCollectedDataTypes", [])
}
require("NSPrivacyCollectedDataTypeUserID" in collected,
        "Privacy manifest must disclose the pseudonymous social user ID.")
require("NSPrivacyCollectedDataTypeOtherUserContent" in collected,
        "Privacy manifest must disclose synchronized score/user-content metadata.")

accessed = {
    item.get("NSPrivacyAccessedAPIType"): set(item.get("NSPrivacyAccessedAPITypeReasons", []))
    for item in privacy.get("NSPrivacyAccessedAPITypes", [])
}
require(
    "CA92.1" in accessed.get("NSPrivacyAccessedAPICategoryUserDefaults", set()),
    "Privacy manifest must declare UserDefaults reason CA92.1."
)

for token in ("0.9.2 (11)", "English", "Español"):
    require(token in readme, f"README missing release/localization token: {token}")
for token in ("0.9.2 build 11", "## English", "## Español"):
    require(token in testflight, f"TestFlight guide missing token: {token}")

require((ROOT / "LICENSE").exists(), "LICENSE is required for the public repository.")
require((ROOT / "Tests/run-lut-recommendation-tests.sh").exists(),
        "Deterministic LUT recommendation test runner is missing.")
workflow = read(".github/workflows/ios-build.yml")
require("Run LUT recommendation tests" in workflow,
        "CI must execute deterministic LUT recommendation tests.")
require("Validate App Store Connect toolchain" in workflow,
        "CI must validate the current App Store Connect Xcode/SDK floor.")
require((ROOT / "docs/CREATIVE_SPARK.md").exists(),
        "Creative Spark documentation is missing.")
require((ROOT / "docs/RANKINGS.md").exists(),
        "Rankings documentation is missing.")
require((ROOT / "docs/SOCIAL_COMPETITION.md").exists(),
        "Social/CloudKit documentation is missing.")
require((ROOT / "docs/RELEASE_READINESS.md").exists(),
        "Release-readiness matrix is missing.")
require((ROOT / "docs/CLOUDKIT_OPTIONAL.md").exists(),
        "Optional CloudKit build documentation is missing.")
require("J10000000000000000000001 /* CreativeSparkModels.swift in Sources */" in project,
        "Creative Spark sources are not attached to the target.")

if failures:
    print("CapturePilot release contract FAILED:")
    for failure in failures:
        print(f" - {failure}")
    sys.exit(1)

print("CapturePilot release contract OK: 0.9.2 (11), CloudKit optional")
