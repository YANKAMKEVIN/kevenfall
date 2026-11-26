#!/usr/bin/env bash
cd "$(dirname "$0")/prompts"
SPRITE="Format VERTICAL (portrait). Le personnage SEUL, en pied, entièrement visible de la tête aux pieds avec une petite marge, centré. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée au sol."
FOND="La moitié BASSE est plus sombre et calme, aucun personnage."

cat > fond_capitale.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. L'intérieur de la carapace d'une tortue titanesque, creusée en une capitale impériale verticale : immenses parois de carapace aux plaques hexagonales, galeries de mines, usines fumantes en fer et cuivre, quartiers suspendus reliés par des passerelles et des câbles, grands tuyaux qui transportent une lumière cyan (les Kevrês extraits), bannières pourpres de l'Empire. Lumières or des fenêtres, fumée, poussière en suspension, ambiance industrielle oppressante mais majestueuse. $FOND
EOF

cat > tuile_metal.txt <<EOF
TUILE DE DÉCOR pour jeu à défilement horizontal, vue de profil strictement latérale : une passerelle industrielle impériale en métal sombre riveté avec liserés de cuivre, garde-corps bas, et en dessous une structure de poutres croisées, de tuyaux et de câbles où circule une faible lueur cyan. Le DESSUS de la passerelle est une ligne horizontale bien droite située à 20 % de la hauteur de l'image. La tuile doit se RACCORDER parfaitement bord gauche / bord droit (motif répétable horizontalement). Format PAYSAGE large. Tout ce qui est au-dessus de la passerelle et les vides entre les poutres : VRAIE TRANSPARENCE (canal alpha). Aucun personnage.
EOF

cat > props_centre.txt <<EOF
ÉLÉMENTS DE DÉCOR d'un centre d'extraction impérial, vue de profil latérale, sur une même planche, alignés sur une même ligne de sol horizontale et séparés par de l'espace vide : 1) une grande cuve d'extraction en verre et cuivre remplie d'un liquide cyan lumineux, avec des tuyaux ; 2) une console de rapports en laiton avec un écran de cristal et des rouleaux de papier ; 3) une cellule de confinement : cage de verre épais cerclée de fer, vide, éclairée de l'intérieur en cyan, avec des runes ; 4) une pile de caisses industrielles marquées de l'emblème de l'Empire (sans texte). Format PAYSAGE large. Fond avec VRAIE TRANSPARENCE (canal alpha), aucun sol dessiné, aucune ombre portée, aucun personnage.
EOF

cat > sprite_ilo.txt <<EOF
SPRITE DE PERSONNAGE : « Ilo, le Prêtre des Marées », porteur du Kevrê de la Brume, âge incertain (semble avoir trente ans mais ses yeux sont très vieux). Grand et mince, peau olive claire, longs cheveux gris-bleu attachés en queue basse, yeux gris pâle à demi-fermés, petit sourire ironique. Longue robe de prêtre bleu océan et gris perle aux motifs de vagues et d'écailles, châle effiloché, colliers de coquillages et d'écailles, pieds nus avec bandages. Il tient un long bâton de bois flotté au bout duquel pend une lanterne de verre remplie de brume violette. Une brume légère s'enroule autour de ses chevilles. Pose calme, de trois quarts, tourné vers la GAUCHE.
$SPRITE
EOF

cat > portrait_ilo.txt <<EOF
PORTRAIT DE DIALOGUE (buste, de la taille à la tête) d'« Ilo, le Prêtre des Marées » : homme grand et mince à l'âge incertain, peau olive claire, longs cheveux gris-bleu attachés, yeux gris pâle à demi-fermés, petit sourire ironique et mystérieux, robe bleu océan à motifs de vagues, colliers de coquillages et d'écailles, volutes de brume violette autour de lui. Regarde vers la GAUCHE. Format carré, cadré buste.
Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor.
EOF

cat > sprite_orsane.txt <<EOF
SPRITE DE PERSONNAGE : « la Chancelière Orsane », dirigeante de l'Empire, la cinquantaine, antagoniste digne et glaçante qui croit sauver l'humanité. Grande, très droite, peau pâle, cheveux argentés coupés court et impeccables, visage anguleux, regard calculateur derrière de fines lunettes cerclées d'or. Longue tenue de cérémonie pourpre profond et noir, col haut rigide brodé d'or, épaulettes de cuivre, manteau qui traîne au sol. À sa main gauche un gant de métal où sont sertis trois petits cristaux vides (pour les Kevrês). Les mains jointes dans le dos. De trois quarts, tournée vers la GAUCHE.
$SPRITE
EOF

cat > portrait_orsane.txt <<EOF
PORTRAIT DE DIALOGUE (buste, de la taille à la tête) de « la Chancelière Orsane » : femme d'une cinquantaine d'années, peau pâle, cheveux argentés coupés court, visage anguleux, fines lunettes cerclées d'or, regard calculateur et fatigué, col haut rigide pourpre brodé d'or, épaulettes de cuivre. Expression calme, presque bienveillante, terriblement sûre d'elle. Regarde vers la GAUCHE. Format carré, cadré buste.
Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor.
EOF

cat > sprite_extracteur.txt <<EOF
SPRITE DE MONSTRE MÉCANIQUE : « l'Extracteur », automate de garde du centre d'extraction impérial : grand corps de fer sombre et de cuivre sur quatre pattes articulées d'araignée, une cuve de verre au centre remplie de Kevrês volés qui brillent en cyan et or, deux bras terminés par des aiguilles d'extraction et une pince, un œil unique rond rouge, tuyaux et vapeur. Menaçant, imposant. De trois quarts, tourné vers la GAUCHE.
Format carré. Le monstre SEUL, entièrement visible avec une petite marge, centré. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée.
EOF

cat > fond_mines.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. Les mines profondes sous la capitale, à l'intérieur de la chair rocheuse d'une tortue titanesque : une immense caverne sombre, des galeries étayées de vieux bois abandonnées, des rails rouillés, des veines de cristal cyan qui pulsent faiblement dans la roche comme un cœur, des racines-veines géantes, un lac souterrain recouvert d'une brume violette au loin. Très sombre, mystérieux, quelques lueurs cyan et violettes seulement. $FOND
EOF

cat > tuile_roche.txt <<EOF
TUILE DE DÉCOR pour jeu à défilement horizontal, vue de profil strictement latérale : un sol de mine dans la roche sombre (roche brun-gris aux plaques vaguement hexagonales), avec de vieux rails de bois et de fer posés dessus, quelques petits cristaux cyan qui affleurent, et l'épaisseur de roche dessous qui se perd dans l'obscurité. Le DESSUS du sol est une ligne horizontale bien droite située à 20 % de la hauteur de l'image. La tuile doit se RACCORDER parfaitement bord gauche / bord droit (motif répétable horizontalement). Format PAYSAGE large. Tout ce qui est au-dessus du sol : VRAIE TRANSPARENCE (canal alpha). Aucun personnage.
EOF

cat > cristal.txt <<EOF
ÉLÉMENT DE DÉCOR : un amas de grands cristaux de rêve qui sort du sol rocheux, vue de profil, cristaux translucides bleu-gris ÉTEINTS (presque sans lumière), base de roche sombre. Format VERTICAL. L'élément SEUL, centré. Fond avec VRAIE TRANSPARENCE (canal alpha), aucun sol autour, aucune ombre.
EOF

cat > sprite_rongeroc.txt <<EOF
SPRITE DE MONSTRE : « Rongeroc », créature des mines née des cauchemars de la tortue titanesque : sorte de gros cloporte-taupe de la taille d'un chien, carapace segmentée de roche grise aux plaques hexagonales, petits yeux aveugles laiteux, grandes griffes de pierre pour creuser, mâchoires qui grignotent des cristaux, des éclats de cristal cyan incrustés sur le dos. De trois quarts, tourné vers la GAUCHE.
Format carré. La créature SEULE, centrée. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucune ombre.
EOF
ls
