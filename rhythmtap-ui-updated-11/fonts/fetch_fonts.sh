#!/usr/bin/env bash
# Drop OFL fonts into rhythmtap-ui-updated-11/fonts/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/fonts"
mkdir -p "$DEST"
fetch() {
  local out="$1" url="$2"
  echo "→ $out"
  curl -fL --retry 3 -o "$DEST/$out" "$url"
}
fetch "AtkinsonHyperlegible-Regular.ttf" "https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegible/AtkinsonHyperlegible-Regular.ttf"
fetch "AtkinsonHyperlegible-Bold.ttf" "https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegible/AtkinsonHyperlegible-Bold.ttf"
fetch "Cinzel-wght.ttf" "https://raw.githubusercontent.com/google/fonts/main/ofl/cinzel/Cinzel%5Bwght%5D.ttf"
fetch "Lora-wght.ttf" "https://raw.githubusercontent.com/google/fonts/main/ofl/lora/Lora%5Bwght%5D.ttf"
echo "Fonts in $DEST"
ls -la "$DEST"
