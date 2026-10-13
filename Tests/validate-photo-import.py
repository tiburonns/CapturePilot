#!/usr/bin/env python3
from pathlib import Path
import plistlib
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

ranking = read("CapturePilot/Ranking/RankingView.swift")
store = read("CapturePilot/Ranking/PhotoRankingStore.swift")
analyzer = read("CapturePilot/Ranking/PostShotAnalyzer.swift")

require(bool(info.get("NSPhotoLibraryUsageDescription")),
        "Photo Library read/write permission description is missing.")
require("PHPhotoLibrary.authorizationStatus(for: .readWrite)" in ranking,
        "Import UI must reflect full versus limited Photo Library access.")
require("PHPhotoLibrary.requestAuthorization(for: .readWrite)" in ranking,
        "Import UI must request the official iOS Photo Library permission.")
require("PHAsset.fetchAssets(with: .image" in ranking,
        "Import UI must browse authorized assets in its own grid.")
require(".fileImporter(" in ranking and "allowsMultipleSelection: true" in ranking,
        "Files import must allow multiple image selections.")
require("PHCachingImageManager()" in ranking,
        "Photo-grid thumbnails must use PhotoKit's caching image manager.")
require("PhotosPicker(" not in ranking and "PhotosPickerItem" not in ranking,
        "The old Apple multi-select picker should not be the primary photo-selection UI.")
require("loadTransferable(type: Data.self)" not in ranking,
        "Thumbnail selection must not load full photo data merely to make previews.")
require("targetSize: CGSize(width: 2048, height: 2048)" in ranking,
        "Photo-library imports should request bounded 2048 px analysis images.")
require("kCGImageSourceThumbnailMaxPixelSize: 2048" in analyzer,
        "The analyzer must downsample large files before Vision analysis.")
require("Task.detached(priority: .utility)" in store,
        "Fingerprinting and imported-image analysis should run off the main actor at utility priority.")
require("source == .capture ? .userInitiated : .utility" in store,
        "Capture analysis should remain responsive while imported batches use utility priority.")
require("autoreleasepool" in store,
        "Heavy per-image processing should release autoreleased intermediates between images.")

if failures:
    print("Photo import performance validation FAILED:")
    for failure in failures:
        print(f" - {failure}")
    sys.exit(1)

print("Photo import performance validation OK")
