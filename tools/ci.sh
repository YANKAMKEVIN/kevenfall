#!/usr/bin/env bash
# CI Godot : import sans erreur, puis le robot joue le jeu (arguments passés au robot).
# --fixed-fps 60 : le temps du jeu avance d'1/60 s par image quelle que soit la vitesse de la machine,
# le robot joue donc la même partie sur un Mac rapide et sur un serveur de CI lent.
# Échoue si le robot signale un échec, si une erreur de script apparaît, ou s'il dépasse le temps.
# Usage local : GODOT=/chemin/godot tools/ci.sh [arguments du robot]
set -uo pipefail
GODOT="${GODOT:-godot}"
OUT="${OUT:-ci-out}"
LIMIT="${LIMIT:-1500}"
mkdir -p "$OUT"

echo "== Import du projet"
"$GODOT" --headless --path . --import > "$OUT/import1.log" 2>&1 || true   # 1er import : polices pas encore prêtes, erreurs normales
"$GODOT" --headless --path . --import > "$OUT/import.log" 2>&1 || true
if grep -E "SCRIPT ERROR|Parse Error|Failed to load script" "$OUT/import.log"; then
  echo "ÉCHEC : erreurs à l'import"; exit 1
fi

echo "== Partie jouée par le robot : $*"
timeout "$LIMIT" xvfb-run -a -s "-screen 0 1280x720x24" \
  "$GODOT" --path . --rendering-driver opengl3 --fixed-fps 60 -- --shots="$(cd "$OUT" && pwd)/captures" "$@" > "$OUT/partie.log" 2>&1
code=$?
grep -E "^(OK|ECHEC|RESULTAT|SHOT|TIMEOUT)" "$OUT/partie.log" || true
if [ $code -eq 124 ]; then echo "ÉCHEC : le robot n'a pas fini en ${LIMIT} s"; exit 1; fi
if grep -E "SCRIPT ERROR|Parse Error" "$OUT/partie.log"; then echo "ÉCHEC : erreur de script pendant la partie"; exit 1; fi
if [ $code -ne 0 ]; then echo "ÉCHEC : le robot a signalé un échec (code $code)"; exit 1; fi
echo "Partie réussie."
