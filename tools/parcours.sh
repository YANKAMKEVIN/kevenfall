#!/usr/bin/env bash
# Parcours complet sans rendu : le robot (tools/AutoShots.gd) joue du titre jusqu'à une fin,
# en sautant l'attente du rendu (--headless, --fixed-fps 60 : le temps du jeu avance d'1/60 s
# par image, aussi vite que la machine le permet ; ~20 s pour les 11 chapitres).
# Échoue si le robot se bloque, saute un chapitre, ne relit pas une sauvegarde, n'atteint pas
# la fin visée, ou si une erreur ou un avertissement apparaît (hors fuites signalées à la sortie).
# Usage : GODOT=/chemin/godot tools/parcours.sh [--eveiller] [--fin=accord|sommeil|reveil] [--final]…
set -uo pipefail
GODOT="${GODOT:-godot}"
OUT="${OUT:-ci-out}"
LIMIT="${LIMIT:-600}"
cd "$(dirname "$0")/.."
mkdir -p "$OUT"
log="$OUT/parcours$(echo "$*" | tr -c 'a-z0-9=' '_').log"

echo "== Parcours : $*"
timeout "$LIMIT" "$GODOT" --headless --path . --fixed-fps 60 -- --parcours "$@" > "$log" 2>&1
code=$?
grep -E "^(CHAPITRE|FIN|ECHEC|RESULTAT)" "$log" || true
if [ $code -eq 124 ]; then echo "ÉCHEC : le robot n'a pas fini en ${LIMIT} s"; exit 1; fi
if grep -E "^(ERROR|WARNING|SCRIPT ERROR)|Parse Error" "$log" | grep -vE "leaked at exit|still in use at exit"; then
  echo "ÉCHEC : erreur ou avertissement pendant la partie"; exit 1
fi
if [ $code -ne 0 ]; then echo "ÉCHEC : le robot a signalé un échec (code $code)"; exit 1; fi
echo "Parcours réussi."
