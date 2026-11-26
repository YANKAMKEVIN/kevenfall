#!/usr/bin/env bash
cd "$(dirname "$0")/prompts"
FOND="La moitié BASSE est plus sombre et calme, aucun personnage."
TUILE="Le DESSUS du sol est une ligne horizontale bien droite située à 20 % de la hauteur de l'image. La tuile doit se RACCORDER parfaitement bord gauche / bord droit (motif répétable horizontalement). Format PAYSAGE large. Tout ce qui est au-dessus du sol : VRAIE TRANSPARENCE (canal alpha). Aucun personnage."
CINE="ILLUSTRATION CINÉMATIQUE plein écran, format PAYSAGE large 16:9."
BOSS="Format carré. Le personnage SEUL, entièrement visible de la tête aux pieds avec une petite marge, centré. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée."

cat > fond_brume.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. Une mer de brume violette et argentée à perte de vue, sous la lune, d'où émergent des îles qui sont en réalité d'immenses écailles de serpent titanesque, couvertes de temples anciens en ruine, de colonnes et de lanternes éteintes. Au loin, les anneaux colossaux d'un serpent endormi ondulent sous la brume. Des silhouettes fantomatiques de spectres flottent au loin. Mystérieux, mélancolique. $FOND
EOF
cat > tuile_ecaille.txt <<EOF
TUILE DE DÉCOR pour jeu à défilement horizontal, vue de profil strictement latérale : le sol d'une île faite d'une écaille géante de serpent, surface d'écailles nacrées bleu-gris et violettes qui se chevauchent, quelques algues et coquillages, et en dessous l'épaisseur de l'écaille qui se perd dans la brume. $TUILE
EOF
cat > bateau.txt <<EOF
ÉLÉMENT DE DÉCOR : un vieux bateau du culte des Marées, vu de profil latéral : coque de bois flotté sombre, proue sculptée en tête de serpent, une voile rapiécée bleu océan aux motifs de vagues, des lanternes de verre remplies de brume violette accrochées aux mâts, cordages et coquillages. Usé mais beau. Format PAYSAGE large. L'élément SEUL, centré. Fond avec VRAIE TRANSPARENCE (canal alpha), aucune eau, aucune ombre.
EOF
cat > fond_temple.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. L'intérieur du dernier temple du culte des Marées, à moitié inondé : immenses salles de pierre blanche et nacre, colonnes en forme d'anneaux de serpent, bassins d'eau qui reflètent la lune par des ouvertures du plafond, coraux et coquillages qui ont envahi les murs, et de grandes fresques anciennes représentant trois titans (un oiseau d'orage, une tortue-montagne, un serpent de brume) qui se parlent. Lumière lunaire bleue et lueurs violettes. Sacré, silencieux. $FOND
EOF
cat > tuile_temple.txt <<EOF
TUILE DE DÉCOR pour jeu à défilement horizontal, vue de profil strictement latérale : un sol de temple ancien en dalles de pierre blanche et nacre usées, gravées de motifs de vagues, avec une rigole d'eau claire, quelques coquillages et coraux, et en dessous des fondations de pierre immergées dans une eau sombre. $TUILE
EOF
cat > props_temple.txt <<EOF
ÉLÉMENTS DE DÉCOR d'un temple du culte des Marées, vue de profil latérale, sur une même planche, alignés sur une même ligne de sol horizontale et séparés par de l'espace vide : 1) une stèle de pierre gravée d'une fresque de titans (sans lettres) ; 2) un autel avec une grande cloche faite d'un coquillage nacré ; 3) un brasero de bronze où brûle une flamme violette de brume ; 4) une statue brisée d'un prêtre en robe tenant une lanterne. Format PAYSAGE large. Fond avec VRAIE TRANSPARENCE (canal alpha), aucun sol dessiné, aucune ombre portée, aucun personnage vivant.
EOF
cat > serpent_communion.txt <<EOF
$CINE Dans une mer de brume violette et argentée sous la lune, l'œil immense d'un serpent titanesque s'ouvre lentement, une pupille verticale lumineuse turquoise et or, entouré d'écailles nacrées grandes comme des maisons. Devant l'œil, minuscules, trois silhouettes se tiennent sur un rocher (un enfant, une guerrière, un prêtre avec une lanterne), vues de dos. Sacré, vertigineux, onirique. Aucun texte.
EOF
cat > fond_flotte.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. Sous un ciel d'orage, la flotte de vaisseaux volants pourpres et cuivrés de l'Empire est accrochée au dos d'un serpent titanesque qui émerge d'une mer de brume : des chaînes énormes, des harpons et des foreuses plantés dans ses écailles, des tuyaux qui aspirent une lumière cyan, des éclairs. Vaisseaux amiraux immenses aux voiles de métal, projecteurs. Épique, oppressant. $FOND
EOF
cat > tuile_navire.txt <<EOF
TUILE DE DÉCOR pour jeu à défilement horizontal, vue de profil strictement latérale : le pont d'un vaisseau volant impérial, planches de bois sombre cerclées de cuivre et de fer riveté, un bastingage bas en laiton, et en dessous la coque du navire avec des hublots éclairés et des tuyaux. $TUILE
EOF
cat > sprite_orsane_boss.txt <<EOF
SPRITE DE BOSS : « la Chancelière Orsane » en tenue de combat : femme d'une cinquantaine d'années, cheveux argentés courts, fines lunettes cerclées d'or, armure de cérémonie pourpre et noire aux plaques de cuivre, long manteau qui flotte. Son bras gauche porte un gantelet massif où sont sertis trois cristaux volés qui brillent violemment : un or électrique (la Foudre), un rose-ambre minéral (la Pierre), un violet brumeux (la Brume). Des éclairs dorés, des éclats de roche et des volutes de brume tournent autour d'elle. Pose dominante, de trois quarts, tournée vers la GAUCHE.
$BOSS
EOF
cat > fond_reve_commun.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. Le Rêve Commun, où les rêves de trois titans se mêlent : un ciel immense partagé entre des plumes d'orage traversées d'éclairs dorés à gauche, des plaques hexagonales de carapace et de forêts de corail au centre, et une mer de brume violette avec des écailles nacrées à droite. Des îles flottantes et des escaliers de lumière relient le tout. Très haut, les silhouettes géantes et paisibles d'un oiseau, d'une tortue et d'un serpent se devinent dans les nuages. Grandiose, onirique, final. $FOND
EOF
cat > sprite_cauchemar.txt <<EOF
SPRITE DE BOSS FINAL : « le Cauchemar Commun », cauchemar né de toutes les extractions de rêves : une immense créature informe de fumée noire et violette, hérissée d'éclats de foreuses brisées, de chaînes et de cristaux de rêve fêlés, avec de nombreux yeux rouges, une gueule pleine de lumière cyan volée, et trois longs bras qui rappellent une aile, une patte de tortue et une queue de serpent. Terrifiant mais beau. De trois quarts, tourné vers la GAUCHE.
Format carré. La créature SEULE, entièrement visible avec une petite marge, centrée. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée.
EOF
cat > fin_sommeil.txt <<EOF
$CINE Le Long Sommeil : à l'aube, un paysage paisible où trois titans (un oiseau, une tortue-montagne, un serpent) dorment profondément, couverts de forêts et de brume, les yeux clos. Au premier plan sur une colline herbeuse, de dos, un jeune garçon à l'écharpe dorée (sans lumière autour de lui), une guerrière en armure rose et un prêtre à la lanterne regardent le soleil se lever. Les dernières lueurs de rêve s'éteignent dans l'air comme des lucioles. Doux, apaisé, un peu nostalgique. Aucun texte.
EOF
cat > fin_reveil.txt <<EOF
$CINE Le Réveil : les trois titans (un oiseau d'orage, une tortue-montagne, un serpent de brume) sont debout et immenses, le monde change de forme autour d'eux, des continents se soulèvent, des cascades montent vers le ciel. Dans le ciel, une silhouette d'enfant faite d'éclairs dorés se fond dans l'Oiseau. Au premier plan, une guerrière en armure rose dresse un bouclier de pierre lumineuse devant un groupe de survivants. Grandiose, tragique et plein d'espoir. Aucun texte.
EOF
cat > fin_accord.txt <<EOF
$CINE L'Accord : au lever du soleil doré, les trois titans (un oiseau d'orage, une tortue-montagne, un serpent de brume) descendent lentement et posent le monde au sol avec douceur, des villes intactes sur leur dos. Des fils de lumière cyan et or relient les titans aux humains. Au premier plan, de dos, un jeune garçon à l'écharpe dorée, à moitié fait de lumière d'éclair, tient la main d'une guerrière en armure rose ; un prêtre à la lanterne sourit à côté. Lumineux, émouvant, heureux. Aucun texte.
EOF
ls | wc -l
