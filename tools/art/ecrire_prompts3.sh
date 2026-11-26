#!/usr/bin/env bash
cd "$(dirname "$0")/prompts"
SPRITE="Format VERTICAL (portrait). Le personnage SEUL, en pied, entièrement visible de la tête aux pieds avec une petite marge, centré. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée au sol."

cat > fond_village.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. Fin de journée orageuse sur les ailes d'un oiseau titanesque endormi : d'immenses plumes grandes comme des falaises s'étagent vers l'horizon ; sur leurs tiges et leurs barbes sont accrochés des hameaux de maisons rondes en bois et plumes, des passerelles de corde, des lanternes or qui s'allument. Ciel crépusculaire prune et indigo, gros nuages d'orage, premiers éclairs or au loin, mer de nuages tout en bas. La moitié BASSE est plus calme et sombre (brume, nuages), aucun personnage.
EOF

cat > tuile_plume.txt <<EOF
TUILE DE DÉCOR pour jeu à défilement horizontal, vue de profil strictement latérale : le dessus d'une plume géante qui sert de sol de village, avec par-dessus un chemin de planches de bois clouées, quelques touffes de duvet lumineux cyan, et en dessous l'épaisseur de la plume (barbes gris-bleu nacré, fibres, reflets violets) qui se perd vers le bas. Le DESSUS du chemin est une ligne horizontale bien droite située à 25 % de la hauteur de l'image. La tuile doit se RACCORDER parfaitement bord gauche / bord droit (motif répétable horizontalement). Format PAYSAGE large. Tout ce qui est au-dessus du chemin : VRAIE TRANSPARENCE (canal alpha). Aucun personnage.
EOF

cat > props_village.txt <<EOF
ÉLÉMENTS DE DÉCOR de village, vue de profil latérale, sur une même planche, alignés sur une même ligne de sol horizontale et séparés par de l'espace vide : 1) une maison-nid ronde en bois tressé et en plumes avec une porte ronde éclairée et une petite cheminée qui fume ; 2) un étendoir à linge avec des tissus colorés qui flottent ; 3) un puits-paratonnerre en bois et cuivre surmonté d'une tige en spirale ; 4) un grand poteau à lanternes en papier or. Format PAYSAGE large. Fond avec VRAIE TRANSPARENCE (canal alpha), aucun sol dessiné, aucune ombre portée, aucun personnage.
EOF

cat > sprite_ancienne.txt <<EOF
SPRITE DE PERSONNAGE : « Mamé Sauge », l'ancienne du village perché sur les ailes de l'Oiseau d'Orage, qui a élevé le Gamin. Vieille femme petite et vive, peau mate ridée, longs cheveux blancs tressés ornés de petites plumes, yeux rieurs, châle tissé bleu nuit à motifs d'éclairs or, bâton de marche en bois flotté surmonté d'une plume cyan lumineuse. Pose bienveillante, une main tendue, de trois quarts, tournée vers la GAUCHE.
$SPRITE
EOF

cat > sprite_cauchemerle.txt <<EOF
SPRITE DE PETITE CRÉATURE HOSTILE : « Cauchemerle », petit cauchemar né des mauvais rêves de l'Oiseau d'Orage : boule de plumes noires ébouriffées de la taille d'un chat, deux grands yeux blancs lumineux en forme de croissant, bec court crochu, petites ailes hérissées d'où crépitent des étincelles violettes, deux pattes fines. Agressif mais un peu comique. Vue de trois quarts tournée vers la GAUCHE. Format carré. La créature SEULE, centrée. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor.
EOF

cat > foreuse.txt <<EOF
ÉLÉMENT DE DÉCOR : « la Foreuse impériale », énorme engin volant de l'Empire, vu de profil, tourné vers la GAUCHE : coque massive en fer sombre rivetée et cuivre, ballon dirigeable gris ardoise au-dessus avec des bannières pourpres, et dessous une gigantesque mèche de forage en spirale qui brille d'une lumière cyan inquiétante (elle aspire les Kevrês). Projecteurs or, fumée, hélices. Menaçant et impressionnant. Format PAYSAGE. L'engin SEUL, entièrement visible, centré. Fond avec VRAIE TRANSPARENCE (canal alpha), aucun décor, aucune ombre.
EOF

cat > sprite_garde.txt <<EOF
SPRITE DE PERSONNAGE : « Garde impérial », soldat de base de l'Empire, sans visage visible : casque fermé à visière étroite, armure gris ardoise avec liserés de cuivre, tabard pourpre, cape courte, lance dans la main droite et grosse lanterne de cuivre allumée (lumière or) dans la main gauche, tendue devant lui comme s'il fouillait l'obscurité. De profil / trois quarts, tourné vers la GAUCHE, en train de marcher.
$SPRITE
EOF

cat > fond_convoi.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. Pleine nuit sur le dos d'un oiseau titanesque endormi : une vaste crête de plumes sombres en forme de vagues figées, éclairée par la lune derrière des nuages d'orage, avec très loin de petits feux de camp et la silhouette d'une route impériale balisée de lanternes or. Ciel nuit bleu profond, étoiles, éclairs cyan lointains. Atmosphère d'infiltration, silencieuse et tendue. La moitié BASSE est sombre et calme, aucun personnage.
EOF
ls
