"""Tester chat: how different two screenshots are.

Usage: python -I screen_diff.py <ffmpeg bin dir> <a.png> <b.png>

Prints the mean grey-level difference (0 = the same, 255 = black against
white) of the two screens shrunk to 108 x 264, leaving out the top 5 %
where the status bar's clock changes.
"""
import subprocess
import sys

import numpy as np

W, H = 108, 264


def grey(ff: str, path: str) -> np.ndarray:
    raw = subprocess.run(
        [f'{ff}/ffmpeg.exe', '-loglevel', 'error', '-i', path,
         '-vf', f'scale={W}:{H},format=gray', '-f', 'rawvideo', '-'],
        capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.uint8).reshape(H, W).astype(float)


def main() -> None:
    ff, a, b = sys.argv[1:4]
    top = int(H * 0.05)
    print(f'{np.abs(grey(ff, a)[top:] - grey(ff, b)[top:]).mean():.1f}')


if __name__ == '__main__':
    main()
