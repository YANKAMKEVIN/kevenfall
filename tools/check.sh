#!/usr/bin/env bash
# Vérifications rapides (CI et local) : taille des fichiers, import du projet sans erreur,
# chargement de tous les scripts (avertissements bloquants : project.godot, [debug]), tests unitaires.
# Usage : GODOT=/chemin/godot tools/check.sh [motifs de tests, ex. save,story]
set -uo pipefail
GODOT="${GODOT:-godot}"
OUT="${OUT:-ci-out}"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"

echo "== Taille des fichiers"
tools/check_sizes.sh || { echo "ÉCHEC : fichier trop long"; exit 1; }

echo "== Import du projet"
"$GODOT" --headless --path . --import > "$OUT/import1.log" 2>&1 || true   # 1er import : polices pas encore prêtes, erreurs normales
"$GODOT" --headless --path . --import > "$OUT/import.log" 2>&1 || true
if grep -E "SCRIPT ERROR|Parse Error|Failed to load script|^ERROR:|^WARNING:" "$OUT/import.log"; then
  echo "ÉCHEC : erreurs ou avertissements à l'import"; exit 1
fi

echo "== Tests unitaires"
filter=""
[ $# -gt 0 ] && filter="=$1"
timeout 300 "$GODOT" --headless --path . -- "--unit$filter" > "$OUT/tests.log" 2>&1
code=$?
grep -E "^(ECHEC|RESULTAT|  - )" "$OUT/tests.log" || true
if grep -E "SCRIPT ERROR|Parse Error|Failed to load script" "$OUT/tests.log"; then
  echo "ÉCHEC : erreur de script pendant les tests"; exit 1
fi
if [ $code -ne 0 ]; then echo "ÉCHEC : tests unitaires (code $code)"; exit 1; fi
echo "Vérifications réussies."
