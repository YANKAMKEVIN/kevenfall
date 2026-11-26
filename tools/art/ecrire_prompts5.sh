#!/usr/bin/env bash
cd "$(dirname "$0")/prompts"
SPRITE="Format VERTICAL (portrait). Le personnage SEUL, en pied, entièrement visible de la tête aux pieds avec une petite marge, centré. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée au sol."
FOND="La moitié BASSE est plus sombre et calme, aucun personnage."

cat > fond_reve.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. L'intérieur du RÊVE d'une tortue titanesque : un monde onirique calme et immense, une mer de brume lumineuse turquoise et or à perte de vue, des îles de pierre flottantes couvertes de forêts de corail-pierre et de mousse, des arches anciennes à motifs hexagonaux de carapace, des milliers de petites lucioles de rêve qui montent lentement, et très haut dans le ciel un ŒIL géant fermé, paisible, à demi caché dans les nuages (la tortue qui rêve). Lumière douce, sereine, mystique, un peu triste. $FOND
EOF

cat > tuile_reve.txt <<EOF
TUILE DE DÉCOR pour jeu à défilement horizontal, vue de profil strictement latérale : un chemin de rêve fait de dalles de pierre pâle translucide aux motifs hexagonaux de carapace qui luisent faiblement en cyan, de la mousse dorée, quelques racines lumineuses, et en dessous l'épaisseur de pierre qui se dissout en brume lumineuse. Le DESSUS du chemin est une ligne horizontale bien droite située à 20 % de la hauteur de l'image. La tuile doit se RACCORDER parfaitement bord gauche / bord droit (motif répétable horizontalement). Format PAYSAGE large. Tout ce qui est au-dessus du chemin : VRAIE TRANSPARENCE (canal alpha). Aucun personnage.
EOF

cat > props_reve.txt <<EOF
ÉLÉMENTS DE DÉCOR d'un monde de rêve, vue de profil latérale, sur une même planche, alignés sur une même ligne de sol horizontale et séparés par de l'espace vide : 1) une lanterne de pierre ancienne où brûle une flamme cyan de rêve ; 2) une arche de pierre brisée couverte de runes hexagonales lumineuses ; 3) un arbre de corail-pierre aux branches lumineuses turquoise et or ; 4) un petit amas de rochers moussus avec des cristaux. Format PAYSAGE large. Fond avec VRAIE TRANSPARENCE (canal alpha), aucun sol dessiné, aucune ombre portée, aucun personnage.
EOF

cat > sprite_gardien.txt <<EOF
SPRITE DE CRÉATURE (boss) : « le Gardien du Rêve », manifestation du rêve d'une tortue titanesque : un colosse ancien et serein, voûté, au corps de pierre moussue en partie translucide qui laisse voir une lumière cyan intérieure, une petite carapace-montagne sur le dos avec de minuscules ruines et arbres dessus, de longs bras terminés par de grandes mains de pierre, des yeux comme deux lanternes dorées, des cristaux de rêve qui poussent sur ses épaules, des volutes de brume autour. Impressionnant mais pas maléfique. De trois quarts, tourné vers la GAUCHE.
Format carré. La créature SEULE, entièrement visible avec une petite marge, centrée. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée.
EOF

cat > vision_oiseau.txt <<EOF
ILLUSTRATION CINÉMATIQUE plein écran, format PAYSAGE large 16:9 : une vision de rêve. Un gigantesque oiseau titanesque fait d'orage, de nuages sombres et d'éclairs dorés, ailes déployées sur tout le ciel nocturne, penche la tête vers un petit village de maisons de bois accroché à des falaises en forme de plumes. De son œil tombe une seule larme d'éclair dorée, et là où elle touche le sol, dans un halo de lumière or et cyan, se forme la petite silhouette d'un bébé emmailloté. Ambiance sacrée, bouleversante, mélancolique, contraste fort. Aucun texte.
EOF

cat > fond_effondrement.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. Une capitale impériale verticale creusée dans la carapace d'une tortue titanesque, EN TRAIN DE S'EFFONDRER : la paroi de carapace se fend de grandes fissures de lumière rouge-orangé, des quartiers suspendus et des passerelles basculent dans le vide, des incendies, de la poussière et des débris qui tombent, des tuyaux cyan éclatés qui crachent de la lumière, et au loin une foreuse colossale en forme de pointe plantée dans le sol de la carapace, entourée d'éclairs. Ambiance apocalyptique, rouge et indigo. $FOND
EOF

cat > sprite_noyau.txt <<EOF
SPRITE DE MACHINE (boss) : « le Noyau de la Grande Foreuse », cœur mécanique d'une foreuse impériale colossale : un énorme réacteur sphérique en laiton noirci et fer riveté, au centre un cristal géant où tourbillonnent des Kevrês volés en cyan et rouge, entouré de trois anneaux de forets rotatifs, deux bras-pistons terminés par des pointes de forage, des câbles et des tuyaux qui crachent de la vapeur, des runes impériales pourpres. Menaçant, colossal. De trois quarts, tourné vers la GAUCHE.
Format carré. La machine SEULE, entièrement visible avec une petite marge, centrée. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée.
EOF

cat > tortue_leve.txt <<EOF
ILLUSTRATION CINÉMATIQUE plein écran, format PAYSAGE large 16:9 : de nuit, sous l'orage, une tortue titanesque grande comme une montagne, qui porte sur sa carapace une capitale industrielle, se soulève à moitié d'une mer de nuages ; sa tête immense, ancienne, sort des nuées, les yeux mi-clos. Des pans entiers de la ville se détachent de la carapace et tombent dans l'abîme en traînées de feu. Au premier plan à droite, une flotte de vaisseaux volants impériaux pourpres s'éloigne vers l'horizon, où l'on devine dans une mer de brume la courbe d'un immense serpent endormi. Grandiose, tragique. Aucun texte.
EOF
ls
