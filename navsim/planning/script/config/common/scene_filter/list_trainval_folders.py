#!/usr/bin/env python3
"""
Script to list all folders one level down in the trainval sensor_blobs directory.
"""
import os
from pathlib import Path


def main():
    base_dir = Path("/fs/nexus-projects/sim2real/aliu/navsim/dataset/sensor_blobs/trainval")

    if not base_dir.exists():
        print(f"Error: Directory {base_dir} does not exist")
        return

    if not base_dir.is_dir():
        print(f"Error: {base_dir} is not a directory")
        return

    # Get all items in the directory
    folders = []
    for item in base_dir.iterdir():
        if item.is_dir():
            folders.append(item.name)

    # Sort for consistent output
    folders.sort()

    print(f"Found {len(folders)} folders in {base_dir}:\n")
    for folder in folders:
        print(f"  - '{folder}'")


if __name__ == "__main__":
    main()
