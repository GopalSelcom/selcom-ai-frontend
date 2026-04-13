#!/usr/bin/env bash
# Downloads SVG for Figma node into ride SCR-10 loader asset.
# Usage (from repo root, token NOT in repo):
#   export FIGMA_TOKEN='your_new_pat'
#   ./scripts/fetch_figma_loader_svg.sh
set -euo pipefail

FILE_KEY="${FIGMA_FILE_KEY:-CS8pvocmH0F88nWv2IzPmh}"
NODE_ID="${FIGMA_NODE_ID:-207:24900}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/assets/images/figma/ride_scr10/ic_finding_loader_car.svg"

if [[ -z "${FIGMA_TOKEN:-}" ]]; then
  echo "ERROR: Set FIGMA_TOKEN to a valid Figma personal access token (do not commit it)." >&2
  exit 1
fi

ENC_NODE="${NODE_ID//:/%3A}"
RESP="$(curl -sS -H "X-Figma-Token: ${FIGMA_TOKEN}" \
  "https://api.figma.com/v1/images/${FILE_KEY}?ids=${ENC_NODE}&format=svg")"

URL="$(python3 -c "import json,sys; j=json.loads(sys.argv[1]); k=sys.argv[2]; m=j.get('images')or{}; v=m.get(k) or (list(m.values())[0] if m else ''); print(v or '')" "${RESP}" "${NODE_ID}")"

if [[ -z "${URL}" ]]; then
  echo "Could not resolve image URL. Response:" >&2
  echo "${RESP}" >&2
  exit 1
fi

mkdir -p "$(dirname "${OUT}")"
curl -sS -L -o "${OUT}" "${URL}"
echo "Wrote ${OUT}"
