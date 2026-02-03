#!/bin/bash
TARGET_DIRS=("/data/EdgeTX/Radios/Horus X10S/SDCARD/SCRIPTS/TOOLS/" \
"/data/EdgeTX/Radios/Radiomaster Zorro 4in1/SDCARD/SCRIPTS/TOOLS/" \
"/data/EdgeTX/Radios/Radiomaster Zorro ELRS/SDCARD/SCRIPTS/TOOLS/" \
"/data/EdgeTX/Radios/Radiomaster Boxer MAX/SDCARD/SCRIPTS/TOOLS/" \
"/data/EdgeTX/Radios/Radiomaster TX15 MAX/SDCARD/SCRIPTS/TOOLS/")


for TARGET in "${TARGET_DIRS[@]}"; do
    cp -v LogViz.lua "$TARGET"
    cp -v -R LogViz "$TARGET"
done