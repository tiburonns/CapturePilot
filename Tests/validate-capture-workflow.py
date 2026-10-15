#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
checks = {
    "CapturePilot/Settings/AppSettings.swift": [
        "burstCaptureEnabled",
        '.burstCapture: "Ráfaga al mantener presionado"',
        '.burstCapture: "Burst while holding shutter"',
    ],
    "CapturePilot/Settings/SettingsView.swift": [
        "$settings.burstCaptureEnabled",
        "settings.text(.burstCaptureDetail)",
    ],
    "CapturePilot/ContentView.swift": [
        "LongPressGesture(minimumDuration: 0.35)",
        "beginBurstIfAllowed()",
        "captureCurrentPhoto()",
        "transaction.disablesAnimations = true",
    ],
    "CapturePilot/Camera/CameraService.swift": [
        "normalCaptureSequenceByID[settings.uniqueID] = self.nextCaptureSequence",
        "completedCapturesBySequence",
        "processNextPhotoSave()",
        "completeNormalCapture(uniqueID: uniqueID, data: data, sceneHint: sceneHint)",
    ],
    "CapturePilot/Ranking/RankingView.swift": [
        "presentLimitedLibraryPicker(from: presenter)",
        "case all, favorites, screenshots",
        "Select all visible",
        "allowsMultipleSelection: true",
        "Import from Files",
    ],
}
failures = []
for path, tokens in checks.items():
    text = (ROOT / path).read_text(encoding="utf-8")
    for token in tokens:
        if token not in text:
            failures.append(f"{path}: missing {token}")
if failures:
    print("Capture workflow validation FAILED:")
    for failure in failures:
        print(" -", failure)
    sys.exit(1)
print("Capture workflow validation OK: photo access, import filters, burst, ordered saves, fast return")
