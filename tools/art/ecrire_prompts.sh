#!/usr/bin/env bash
cd "$(dirname "$0")/prompts"
SPRITE="Format VERTICAL (portrait). Le personnage SEUL, en pied, entièrement visible de la tête aux pieds avec une petite marge, centré. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée au sol."

cat > sprite_gamin.txt <<EOF
SPRITE DE PERSONNAGE : « le Gamin », héros principal, garçon de 13 ans porteur du Kevrê de la Foudre, né d'un rêve de l'Oiseau d'Orage. Peau mate brun clair, cheveux blanc argenté ébouriffés en pointes, quelques mèches or électrique, grands yeux ambre vifs et malicieux, sourire en coin. Longue écharpe or électrique qui flotte au vent derrière lui. Tunique courte bleu-gris tissée de motifs de plumes, ceinture de cuir, short sombre, bottes de cuir usées. À chaque poignet un bracelet d'entrave impérial en métal sombre gravé de runes cyan, avec un bout de chaîne cassée qui pend. Petites étincelles électriques dorées qui crépitent autour de sa main droite levée. Pose dynamique de combat, de trois quarts, tourné vers la DROITE.
$SPRITE
EOF

cat > sprite_soldate.txt <<EOF
SPRITE DE PERSONNAGE : « la Soldate », capitaine de l'Empire, 27 ans, porteuse du Kevrê de la Pierre. Femme grande et athlétique, peau brun foncé, cheveux noirs courts rasés sur un côté, petite cicatrice au sourcil, regard dur mais juste. Armure impériale gris ardoise ajustée avec liserés de cuivre, tabard pourpre sombre, courte cape pourpre. Son avant-bras droit est un énorme gantelet de pierre grise taillée, veinée de fissures ambre-or lumineuses (son pouvoir). Épée courte au fourreau à la hanche. Pose de garde solide, jambes écartées, gantelet en avant, de trois quarts, tournée vers la DROITE.
$SPRITE
EOF

cat > sprite_golem.txt <<EOF
SPRITE DE MONSTRE : « le Golem de l'Empire », colosse fait de blocs de roche arrachés à la carapace d'une tortue titanesque (plaques hexagonales brun-vert, mousse, lichens), maintenu par des harnais et des anneaux de cuivre impériaux rivetés, avec des chaînes brisées qui pendent de ses bras. Fissures qui laissent passer une lumière turquoise instable, et deux yeux rouges de fureur dans une tête massive sans bouche. Énormes poings, dos voûté, posture menaçante, de trois quarts, tourné vers la GAUCHE. Massif et imposant, presque carré.
Format carré. Le monstre SEUL, entièrement visible avec une petite marge, centré. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor, aucun sol, aucune ombre portée au sol.
EOF

cat > sprite_spectre.txt <<EOF
SPRITE DE MONSTRE : « le Spectre de brume », cauchemar né des rêves d'un titan. Silhouette flottante faite de brume violette et bleu pâle, semi-transparente, sans jambes : le bas du corps s'effiloche en une longue queue de vapeur ondulante. Un masque ovale blanc ivoire fêlé, sans bouche, avec deux fentes d'yeux qui brillent d'un cyan intense. Bras longs et minces terminés par des doigts effilés comme des griffes de brume. Lueur cyan intérieure au niveau du cœur. Inquiétant mais pas gore. Il flotte, penché en avant vers la GAUCHE.
$SPRITE
EOF

cat > sprite_brann.txt <<EOF
SPRITE DE PERSONNAGE : « Brann », vieux sergent de l'Empire, la cinquantaine, bon vivant fatigué. Grosse moustache grise, joues rouges, ventre rond sous une armure impériale gris ardoise cabossée avec liserés de cuivre et tabard pourpre délavé. Casque rond à bord large. Il tient une lanterne de cuivre allumée (lumière or chaude) dans la main gauche et une lance appuyée sur l'épaule. Pose détendue de sentinelle, de trois quarts, tourné vers la GAUCHE.
$SPRITE
EOF

cat > sprite_tess.txt <<EOF
SPRITE DE PERSONNAGE : « Tess », jeune ingénieure de l'Empire chargée du Golem, 20 ans. Peau claire avec taches de rousseur, cheveux roux en chignon désordonné, grosses lunettes de protection en laiton relevées sur le front, tablier de cuir couvert d'outils, manches retroussées, gants épais. Elle tient une grande clé de cuivre et un carnet. Air nerveux et passionné. De trois quarts, tournée vers la GAUCHE.
$SPRITE
EOF

cat > portrait_gamin.txt <<EOF
PORTRAIT DE DIALOGUE (buste, de la taille à la tête) du « Gamin » : garçon de 13 ans, peau mate brun clair, cheveux blanc argenté ébouriffés en pointes avec quelques mèches or électrique, grands yeux ambre vifs, écharpe or électrique autour du cou, tunique bleu-gris à motifs de plumes, bracelet d'entrave impérial en métal sombre à runes cyan visible au poignet. Expression curieuse et insolente, petit sourire. Regarde vers la DROITE. Format carré, cadré buste.
Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor.
EOF

cat > portrait_soldate.txt <<EOF
PORTRAIT DE DIALOGUE (buste, de la taille à la tête) de « la Soldate » : capitaine de l'Empire, 27 ans, peau brun foncé, cheveux noirs courts rasés sur un côté, petite cicatrice au sourcil, armure ardoise à liserés de cuivre, tabard et cape pourpres, gantelet de pierre grise veinée d'ambre lumineux visible. Expression sévère, un sourcil levé, mais une pointe de fatigue et d'humanité dans le regard. Regarde vers la GAUCHE. Format carré, cadré buste.
Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor.
EOF

cat > fond_lointain.txt <<EOF
DÉCOR DE FOND LOINTAIN (plan le plus éloigné d'un jeu à défilement horizontal), format PAYSAGE large. Nuit d'orage au-dessus d'une mer de nuages infinie. À GAUCHE, immense et lointaine, l'aile d'un oiseau titanesque endormi dont les plumes forment des falaises géantes, avec quelques lumières de village accrochées dessus. À DROITE, très loin à l'horizon, la silhouette d'une tortue colossale grosse comme une montagne, dont la carapace est creusée d'une ville impériale illuminée de points or (une capitale). Ciel indigo et violet, nuages d'orage lourds, éclairs lointains or et cyan, quelques étoiles dans les trouées. La moitié BASSE de l'image est occupée par la mer de nuages sombre et calme, sans aucun élément au premier plan, sans personnage.
EOF

cat > fond_combat.txt <<EOF
DÉCOR DE COMBAT, format PAYSAGE large, vue latérale légèrement plongeante. Sur un pont colossal fait d'os et de pierre, qui relie l'aile d'un oiseau titanesque à la carapace d'une tortue-montagne, au-dessus d'une mer de nuages, en pleine nuit d'orage. Le tablier du pont occupe le TIERS INFÉRIEUR de l'image comme une scène plate et dégagée (les combattants y seront placés). Au fond à gauche, un chariot-cage impérial renversé et une lanterne tombée ; à droite, une brume violette épaisse qui monte de l'abîme, traversée de lueurs cyan. Ciel indigo, éclair or qui déchire les nuages. Aucun personnage, aucune créature.
EOF

cat > titre.txt <<EOF
ILLUSTRATION D'ÉCRAN TITRE, format PAYSAGE large, très épique. Vue de dos et de loin : un garçon à l'écharpe or électrique flottant au vent et une femme soldat en armure avec un gantelet de pierre se tiennent côte à côte au bord d'un pont colossal, face à un horizon nocturne d'orage. Devant eux, au-dessus d'une mer de nuages, l'aile immense d'un oiseau titanesque endormi et, au loin, une tortue grande comme une montagne portant une ville illuminée. Un éclair or illumine la scène. Laisser l'espace du TIERS SUPÉRIEUR CENTRAL relativement calme (ciel) pour y poser le titre du jeu plus tard. Aucun texte.
EOF

cat > revelin.txt <<EOF
SPRITE DE PETITE CRÉATURE : « Rêvelin », petite créature inoffensive née des rêves de l'Oiseau d'Orage : sorte de papillon-plume lumineux de la taille d'une main, corps rond duveteux blanc, deux ailes en forme de plumes translucides cyan avec des reflets or, petits yeux noirs brillants, une traînée de poussière lumineuse. Mignon, onirique. Vue de profil tournée vers la DROITE. Format carré. La créature SEULE, centrée. Fond avec une VRAIE TRANSPARENCE (canal alpha), aucun décor.
EOF
ls
