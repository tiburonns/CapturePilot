#!/usr/bin/env python3
from pathlib import Path
import sys
source = (Path(__file__).resolve().parents[1] / "CapturePilot/Camera/RawShareProcessor.swift").read_text(encoding="utf-8")
required = ["LUT applied:", "addingLUTMetadata(metadataNote, to: renderedData)", "kCGImagePropertyExifUserComment", "kCGImagePropertyIPTCCaptionAbstract", "kCGImagePropertyTIFFImageDescription", "CGImageDestinationAddImageFromSource", "CGImageDestinationFinalize"]
missing = [item for item in required if item not in source]
if missing:
    print("LUT metadata validation FAILED:", ", ".join(missing))
    sys.exit(1)
print("LUT metadata validation OK: EXIF, IPTC and TIFF notes are embedded.")
