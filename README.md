# Kevenfall · v0.5 · Le jeu complet

Les trois actes et les trois fins (environ une heure et demie, 11 chapitres) du jeu original **Kevenfall**, fait avec **Godot 4.3**.
L'écran titre propose « Nouvelle partie » et « Chapitres » pour reprendre directement au chapitre voulu.

## Lancer le jeu
1. Ouvre Godot 4.3 (ou plus récent en 4.x).
2. « Importer » → choisis le fichier `project.godot` de ce dossier.
3. Appuie sur **F5** (ou le bouton ▶ en haut à droite).

Sur Mac, en ligne de commande : `godot --path <ce dossier>`

## Commandes
| Action | Clavier | Manette |
|---|---|---|
| Marcher | ← → ou A / D | croix / stick |
| Sauter (maintenir pour sauter plus haut) | Espace, W ou ↑ | A |
| Parler / valider | E ou Entrée | X |
| Foudre (quand le Gamin la possède) | X ou J | B |
| Se cacher derrière une caisse (chapitre 2) | ↓ ou S | croix bas |
| Choisir dans les menus | ↑ ↓ (← → pour la cible) | croix |
| Annuler la cible | Échap | |
| Pause (exploration) | Échap | Start (B pour revenir au titre) |

## Les chapitres
### Acte I · L'Oiseau d'Orage
1. **Le village des Plumes** : le soir de la fête de l'Orage, le Gamin allume les trois paratonnerres du village avec sa Foudre, affronte des Cauchemerles (premier combat, en solo), puis la Foreuse de l'Empire descend des nuages et la Soldate l'emmène.
2. **Le convoi** : de nuit, le Gamin s'échappe de sa cage. Infiltration : éviter la lumière des lanternes des gardes, se cacher derrière les caisses. Chaque fois qu'il est pris, la Soldate le rattrape... et lui parle un peu plus. Au bout du chemin, elle l'attend près du feu.
3. **Le Pont de l'Oiseau** : la halte sur le pont, le Golem enchaîné, le Spectre, et le grand combat à deux héros (Éclair, Garde, attaque combinée Onde de choc). Puis la fin de l'acte.

### Acte II · La Tortue-Montagne
4. **Le centre d'extraction** : on joue la Soldate, dans la capitale creusée dans la carapace de la Tortue. Elle lit trois rapports d'extraction (les secousses augmentent à chaque fois), croise la Chancelière Orsane, choisit son camp et libère le Gamin. Combat contre l'Extracteur et deux gardes : l'Éclair chaîné (Foudre niveau 2) touche tous les ennemis, et l'Extracteur craint la Foudre mais vole le Rêve.
5. **Les mines profondes** : en fuite, le Gamin éclaire les mines avec sa Foudre en allumant cinq cristaux, la Soldate le suit. Au bord du lac de brume, rencontre avec Ilo, Prêtre des Marées. Premier combat à trois héros contre les Rongerocs cuirassés, avec le Voile de brume d'Ilo et deux nouvelles attaques combinées : Sables mouvants (Soldate + Ilo, ralentit) et Orage invisible (Gamin + Ilo, impossible à esquiver).
6. **Le rêve de la Tortue** : Ilo fait entrer l'équipe dans le rêve de la Tortue. Le Gamin rallume les lanternes du rêve avec sa Foudre pour faire réapparaître le chemin, puis affronte le Gardien du Rêve (sa carapace se reforme : il faut la briser avec les attaques combinées). Première communion : **le joueur choisit Bercer ou Éveiller**. Puis la Tortue montre au Gamin la vérité : il est un rêve de l'Oiseau devenu enfant. Il le cache à la Soldate, mais Ilo a compris.
7. **La Grande Foreuse** : Orsane fore jusqu'au cœur de la Tortue et la capitale s'effondre. Fuite sous une pluie de débris (une lueur rouge annonce où ils tombent), Tess aide à évacuer, puis combat contre le Noyau de la Grande Foreuse et ses deux forets. La Tortue se lève à moitié, Orsane part avec la flotte vers le Serpent. Fin de l'acte II.

### Acte III · Le Serpent des Marées
8. **La mer de brume** : le vieux bateau du culte s'échoue sur les îles-écailles du Serpent. On avance d'écaille en écaille en dissipant les Spectres à la Foudre (s'ils te touchent, retour en arrière), puis combat contre un Spectre ancien.
9. **Le dernier temple** : on joue Ilo. Il lit les fresques de son culte et avoue la vérité : le culte savait que les titans peuvent parler, et l'a caché. **Deuxième communion, avec le Serpent : Bercer ou Éveiller.** La nuit, le Gamin avoue son secret à la Soldate, qui refuse de choisir entre lui et le monde.
10. **La flotte d'Orsane** : on joue la Soldate, à l'assaut des vaisseaux accrochés au Serpent, sous les tirs de canon. Combat contre Orsane et ses trois Kevrês volés (Foudre, puis Pierre et son armure, puis Brume et ses esquives). L'extraction réveille l'Oiseau : le Gamin commence à s'effacer.
11. **Le Rêve Commun** : le donjon final, où les rêves des trois titans se mêlent. Les Kevrês passent au niveau 3 et une jauge commune apparaît : chaque action la remplit, et pleine, elle déclenche l'attaque des trois héros, **Rêve Commun**. On peut écouter chacun des trois titans. Combat final contre le Cauchemar Commun, puis le dernier choix.

### Les trois fins
- **Le Long Sommeil** (surtout Bercer) : les titans se rendorment, les Kevrês s'éteignent, le Gamin devient un enfant ordinaire.
- **Le Réveil** (surtout Éveiller) : les titans se lèvent, le monde change de forme, le Gamin devient la voix de l'Oiseau.
- **L'Accord**, la vraie fin : il faut avoir **écouté les trois titans** dans le Rêve Commun **et** ne pas avoir fait le même choix avec la Tortue et le Serpent. Une troisième option apparaît alors au dernier choix.

### Bercer ou Éveiller
Les choix des communions changent les pouvoirs de l'équipe :
| | Bercer | Éveiller |
|---|---|---|
| Pierre niveau 2 (Soldate) | Rempart : bouclier sur toute l'équipe et petit soin | Séisme : frappe tous les ennemis et brise les armures |
| Foudre (Gamin) | Arc apaisant : ralentit toutes les jauges ennemies | Tempête : énormes dégâts, mais risque de surcharge (le Gamin perd un tour) |
| Brume niveau 2 (Ilo, choix du Serpent) | Berceuse : soigne l'équipe et endort les jauges ennemies | Marée noire : vole la jauge des ennemis pour l'équipe |

Au niveau 3 (Rêve Commun), ces pouvoirs deviennent plus forts.

Treize **Éclats de rêve** sont cachés (2 au village, 3 sur le pont, 2 dans les mines, 2 dans le rêve de la Tortue, 2 dans la mer de brume, 2 dans le Rêve Commun). Chacun révèle un souvenir de l'Oiseau d'Orage et donne +6 PV au Gamin dans les combats.

## Équilibrage
Le combat du pont a été réglé en simulant 2 400 parties (`tools/sim_combat.py`) : environ 99 % de victoires en jouant bien, environ 90 % en jouant au hasard une fois sur trois, pour une durée d'une minute et demie à deux minutes.

## Organisation du projet
- `scripts/` : le code du jeu (Main, Title, Exploration, Dialogue, Battle, Ending, Game…).
- `art/` : les illustrations peintes avec Codex (héros, monstres, décors).
- `audio/` : musiques et bruitages générés (`tools/audio_synth.py`).
- `tools/art/` : les prompts Codex et le script `generer.sh` pour repeindre ou ajouter des visuels.
- `scripts/levels/` : les chapitres (Village, Convoi, Pont, Centre, Mines, Reve, Effondrement, Brume, Temple, Flotte, ReveCommun).
- `tools/AutoShots.gd` : outil qui joue tout le jeu tout seul (`--act2` pour commencer à l'acte II, `--fin2` pour commencer au chapitre 6, `--eveiller` pour choisir Éveiller, `--act3` pour l'acte III, `--fin=accord|sommeil|reveil` pour la fin) et prend des captures (`godot --path . -- --shots=/chemin`).

## Sauvegarde
La partie est sauvegardée automatiquement au début de chaque chapitre (`user://sauvegarde.json`) ; « Continuer » apparaît alors sur l'écran titre. Le menu « Chapitres » sert au rejeu et n'écrase pas la sauvegarde.
Le format est versionné (`scripts/SaveData.gd`, `VERSION`) : toute évolution du format incrémente la version et ajoute une migration ; une sauvegarde abîmée ou venant d'une version plus récente est ignorée, jamais chargée à moitié.

## Tests
```bash
godot --headless --path . -- --unit        # tests unitaires (sauvegarde, aides manette)
GODOT=godot tools/ci.sh --act3             # le robot joue un lot (voir .github/workflows/tests.yml)
```
La CI GitHub lance les tests unitaires et la partie complète en trois lots parallèles sur chaque PR.
