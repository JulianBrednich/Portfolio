#!/bin/zsh
# Encodes a video or an image sequence for the portfolio (GitHub Pages).
#
#   H.264 High profile, yuv420p, MP4 with faststart, no audio
#   -> plays inline in every browser (autoplay + muted + loop)
#
# Usage:
#   tools/encode-video.sh <input> <name> [crf] [fps]
#
#   <input>  a video file (.mov/.mp4) or an image sequence pattern,
#            e.g. "/path/MovieRenders/Sequence.Deferred.%04d.png"
#   <name>   output name, e.g. rice-terraces-beauty
#   [crf]    quality, lower = better/larger (default 22; 20 for beauty, 24 for screen capture)
#   [fps]    frame rate of an image sequence (default 24)
#
# Writes assets/video/<name>.mp4 and assets/img/<name>.jpg (poster).

set -e
if [[ $# -lt 2 ]]; then
  sed -n '2,17p' "$0"; exit 1
fi

INPUT="$1"; NAME="$2"; CRF="${3:-22}"; FPS="${4:-24}"
ROOT="${0:A:h:h}"
OUT="$ROOT/assets/video/$NAME.mp4"
POSTER="$ROOT/assets/img/$NAME.jpg"
mkdir -p "$ROOT/assets/video" "$ROOT/assets/img"

if [[ "$INPUT" == *%* ]]; then
  IN_ARGS=(-framerate "$FPS" -i "$INPUT")
else
  IN_ARGS=(-i "$INPUT")
fi

ffmpeg -y "${IN_ARGS[@]}" \
  -vf "scale='min(1920,iw)':-2:flags=lanczos,format=yuv420p" \
  -c:v libx264 -preset slow -crf "$CRF" -profile:v high \
  -movflags +faststart -an \
  "$OUT"

ffmpeg -y -ss 1 -i "$OUT" -frames:v 1 -q:v 3 "$POSTER"

SIZE_MB=$(( $(stat -f%z "$OUT") / 1024 / 1024 ))
echo "Wrote $OUT (${SIZE_MB} MB) and $POSTER"
if (( SIZE_MB > 50 )); then
  echo "Warning: larger than 50 MB. GitHub warns above 50 MB and rejects files above 100 MB."
  echo "Re-run with a higher crf (e.g. 26) or shorten the clip."
fi
