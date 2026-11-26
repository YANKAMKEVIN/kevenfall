#!/usr/bin/env bash
cd "$(dirname "$0")/prompts"
cat > tuile_pont.txt <<EOF
TUILE DE DÉCOR pour jeu à défilement horizontal, vue de profil strictement latérale : un tronçon du tablier d'un pont colossal fait de pierre pâle et d'os géants, avec dalles gravées de fines lignes or, une rangée d'arches osseuses en dessous et des bannières pourpres déchirées qui pendent. Le DESSUS du tablier est une ligne horizontale bien droite située à 20 % de la hauteur de l'image (c'est le sol où marchent les personnages). La tuile doit se RACCORDER parfaitement bord gauche / bord droit (motif répétable horizontalement, bords coupés net). Format PAYSAGE large. Tout ce qui est au-dessus du tablier et le ciel entre les arches : VRAIE TRANSPARENCE (canal alpha). Aucun personnage.
EOF
cat > camp.txt <<EOF
ÉLÉMENTS DE DÉCOR, vue de profil latérale, sur une même planche : à gauche un chariot-cage impérial (bois sombre, ferrures de cuivre, bâche pourpre, grandes roues) à l'arrêt, au centre un petit feu de camp avec quelques pierres et une marmite, à droite une pile de caisses impériales et un pilier-lanterne en pierre avec une flamme or. Les éléments sont posés sur une même ligne de sol horizontale, séparés par de l'espace vide. Format PAYSAGE large. Fond avec VRAIE TRANSPARENCE (canal alpha), aucun sol dessiné, aucune ombre portée, aucun personnage.
EOF
cat > chaines.txt <<EOF
ÉLÉMENT DE DÉCOR, vue de profil : le Golem de l'Empire ENDORMI, accroupi et immobile, enchaîné à de lourds anneaux de cuivre plantés dans le sol par de grosses chaînes tendues ; colosse de blocs de roche de carapace de tortue (plaques hexagonales brun-vert, mousse), harnais de cuivre, fissures turquoise faiblement lumineuses, yeux éteints. Tourné vers la GAUCHE. Format carré, l'élément seul, centré. Fond avec VRAIE TRANSPARENCE (canal alpha), aucun sol dessiné, aucune ombre portée.
EOF
