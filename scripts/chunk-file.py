#!/usr/bin/env python3
"""
File Chunker - Split large files into overlapping chunks with metadata headers
"""

import os
import sys
from pathlib import Path
from datetime import datetime

def chunk_file(input_file, output_dir, chunk_size=500, overlap_percent=5):
    """
    Split a file into chunks with overlap and metadata headers.

    Args:
        input_file: Path to input file
        output_dir: Directory to save chunks
        chunk_size: Lines per chunk
        overlap_percent: Percentage of overlap between chunks (0-100)
    """

    # Read input file
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    total_lines = len(lines)
    overlap_lines = max(1, int(chunk_size * overlap_percent / 100))
    step = chunk_size - overlap_lines

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    # Calculate chunks
    chunks = []
    start_idx = 0
    chunk_num = 1

    while start_idx < total_lines:
        end_idx = min(start_idx + chunk_size, total_lines)

        # Calculate actual overlap info
        if chunk_num > 1:
            actual_start = start_idx
            actual_overlap = overlap_lines
        else:
            actual_start = 0
            actual_overlap = 0

        chunks.append({
            'number': chunk_num,
            'start_line': actual_start + 1,  # 1-indexed for humans
            'end_line': end_idx,
            'lines': lines[start_idx:end_idx],
            'overlap_lines': actual_overlap,
            'total_lines': end_idx - start_idx
        })

        if end_idx >= total_lines:
            break

        start_idx += step
        chunk_num += 1

    # Write chunks
    for chunk in chunks:
        chunk_num = chunk['number']
        filename = f"chunk-{chunk_num:03d}.txt"
        filepath = os.path.join(output_dir, filename)

        # Create metadata header
        metadata = f"""================================================================================
CHUNK METADATA
================================================================================
Filename: {os.path.basename(input_file)}
Chunk Number: {chunk_num} of {len(chunks)}
Source Lines: {chunk['start_line']}-{chunk['end_line']} (total file: {total_lines} lines)
Chunk Lines: {chunk['total_lines']}
Overlap with Previous: {chunk['overlap_lines']} lines ({overlap_percent}%)
Created: {datetime.now().isoformat()}
================================================================================

"""

        # Write chunk file
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(metadata)
            f.writelines(chunk['lines'])

        print(f"✓ {filename}: lines {chunk['start_line']}-{chunk['end_line']} ({chunk['total_lines']} lines)")

    # Create index file
    index_file = os.path.join(output_dir, "INDEX.txt")
    with open(index_file, 'w', encoding='utf-8') as f:
        f.write("FILE CHUNKING INDEX\n")
        f.write("=" * 80 + "\n\n")
        f.write(f"Original File: {input_file}\n")
        f.write(f"Total Lines: {total_lines}\n")
        f.write(f"Chunk Size: {chunk_size} lines\n")
        f.write(f"Overlap: {overlap_percent}% ({overlap_lines} lines)\n")
        f.write(f"Total Chunks: {len(chunks)}\n")
        f.write(f"Created: {datetime.now().isoformat()}\n\n")
        f.write("=" * 80 + "\n\n")

        for chunk in chunks:
            f.write(f"Chunk {chunk['number']:3d}: Lines {chunk['start_line']:5d}-{chunk['end_line']:5d} ({chunk['total_lines']:3d} lines)")
            if chunk['overlap_lines'] > 0:
                f.write(f" [Overlap: {chunk['overlap_lines']} lines from previous]")
            f.write("\n")

    print(f"\n✓ Index created: {index_file}")
    print(f"\nSummary:")
    print(f"  Total lines: {total_lines}")
    print(f"  Total chunks: {len(chunks)}")
    print(f"  Chunk size: {chunk_size} lines")
    print(f"  Overlap: {overlap_percent}% ({overlap_lines} lines)")

if __name__ == "__main__":
    # Parse arguments
    if len(sys.argv) < 2:
        print("Usage: python chunk-file.py <input_file> [output_dir] [chunk_size] [overlap_percent]")
        print("Default: chunk_size=500, overlap=5%")
        sys.exit(1)

    input_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "CHUNKS"
    chunk_size = int(sys.argv[3]) if len(sys.argv) > 3 else 500
    overlap_percent = int(sys.argv[4]) if len(sys.argv) > 4 else 5

    if not os.path.exists(input_file):
        print(f"Error: File not found: {input_file}")
        sys.exit(1)

    chunk_file(input_file, output_dir, chunk_size, overlap_percent)
