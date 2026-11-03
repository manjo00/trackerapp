"""Tester chat: what each frame of a screen recording shows, with its time.

Usage: python -I frame_times.py <recording.mp4> <ffmpeg bin dir>

Prints one line per frame: its time and how bright and how even three bands
of the screen are (top, middle, bottom; 0 = black, 255 = white). Uplan's own
screens are bright and even at the top; the quick-add sheet's dimmed scrim
makes the top dark; the launcher's wallpaper sits in between and is uneven.
"""
import subprocess
import sys

import numpy as np

W, H = 54, 132  # frames are shrunk to this before measuring


def main() -> None:
    video, ff = sys.argv[1], sys.argv[2]
    times = subprocess.run(
        [f'{ff}/ffprobe.exe', '-v', 'error', '-select_streams', 'v:0',
         '-show_entries', 'frame=pts_time', '-of', 'csv=p=0', video],
        capture_output=True, text=True, check=True).stdout.split()
    raw = subprocess.run(
        [f'{ff}/ffmpeg.exe', '-loglevel', 'error', '-i', video,
         '-fps_mode', 'passthrough', '-vf', f'scale={W}:{H},format=gray',
         '-f', 'rawvideo', '-'],
        capture_output=True, check=True).stdout
    frames = np.frombuffer(raw, dtype=np.uint8).reshape(-1, H, W)
    bands = {'top': (0.08, 0.35), 'middle': (0.35, 0.65), 'bottom': (0.65, 0.95)}
    print('time    ' + '  '.join(f'{b:>13}' for b in bands))
    for t, f in zip(times, frames):
        cells = []
        for lo, hi in bands.values():
            part = f[int(lo * H):int(hi * H)].astype(float)
            cells.append(f'{part.mean():6.0f}±{part.std():<6.0f}')
        print(f'{float(t):6.3f}  ' + '  '.join(cells))


if __name__ == '__main__':
    main()
