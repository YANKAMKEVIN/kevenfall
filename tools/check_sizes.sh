#!/usr/bin/env bash
# Garde-fou : aucun script GDScript du jeu, des outils ou des tests ne dépasse MAX lignes
# (pas de fichier-dieu : on découpe en modules, voir scripts/battle/ et scripts/exploration/).
set -euo pipefail
MAX="${MAX:-400}"
cd "$(dirname "$0")/.."
bad=0
while IFS= read -r f; do
  n=$(wc -l < "$f")
  if [ "$n" -gt "$MAX" ]; then echo "TROP LONG : $f ($n lignes, max $MAX)"; bad=1; fi
done < <(find scripts tools tests -name '*.gd' | sort)
biggest=$(find scripts tools tests -name '*.gd' -exec wc -l {} + | grep -v ' total$' | sort -rn | head -1)
echo "Plus gros fichier : $biggest"
exit $bad
