#!/usr/bin/env python3
import sys

if len(sys.argv) < 3:
    print("Usage: update_cask.py <version> <sha256>")
    sys.exit(1)

version = sys.argv[1].lstrip('v')
sha256 = sys.argv[2]
cask_file = "Casks/portlessman.rb"

with open(cask_file, "r") as f:
    lines = f.readlines()

with open(cask_file, "w") as f:
    for line in lines:
        if line.strip().startswith("version "):
            f.write(f'  version "{version}"\n')
        elif line.strip().startswith("sha256 "):
            f.write(f'  sha256 "{sha256}"\n')
        else:
            f.write(line)

print(f"✅ Updated {cask_file} to version {version} (sha256: {sha256})")
