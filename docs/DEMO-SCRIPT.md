# Script de démo — Soutenance

> Déroulé minute par minute de la démo live (90 secondes max).
> Optimisé pour la captation vidéo de secours et la présentation.

## ⚙️ Préparation (avant les jurys)

1. Ouvrir un terminal à la racine du projet : `npm run dev:all`
2. Attendre que les 4 services soient prêts (logs "Local: http://localhost:...")
3. Ouvrir 3 fenêtres navigateur (idéalement sur 3 écrans / 3 moniteurs) :
   - **Écran principal** (centre) : `http://localhost:5173` — Playfield
   - **Écran gauche / haut** : `http://localhost:5174` — Backglass
   - **Écran droit / bas** : `http://localhost:5175` — DMD
4. Cliquer une fois dans le playfield (focus clavier + débloque l'AudioContext)
5. Vérifier que le volume est à ~60% (refresh si besoin)

## 🎬 Déroulé (durée cible : 90s)

### Phase 1 — Plan d'ensemble (0–15s)
- Montrer les 3 écrans simultanément (silence ou commentaire posé)
- Souligner la **cohérence visuelle** (palette Breaking Bad sur les 3 écrans)
- Pointer le HUD audio en haut-droite du playfield

### Phase 2 — Démarrage de la partie (15–30s)
- Appuyer sur **D** (start)
- Effet attendu : thème principal démarre + son "Ball Release" + flash jaune + ball spawn
- Le backglass affiche `STATUT : playing`, le DMD passe sur le score
- Appuyer sur **Espace** (launch ball)
- Effet attendu : la bille part vers le haut

### Phase 3 — Action gameplay (30–60s)
- Jouer activement avec **flèche gauche** / **flèche droite** (ou X/C)
- Toucher au moins **2 bumpers** différents : flash + son + score qui grimpe
- Le backglass montre le score qui monte en live (effet glow ambre)
- Atteindre **1000 pts** si possible : milestone vert toxique sur les 3 écrans

### Phase 4 — Contrôles audio (60–75s)
- Appuyer sur **M** : tout se coupe (HUD passe rouge)
- Appuyer sur **−** plusieurs fois : volume descend
- Appuyer sur **+** plusieurs fois : volume remonte
- Appuyer sur **M** : son revient

### Phase 5 — Game over (75–90s)
- Laisser la bille passer (ou attendre les 3 drains)
- Effet attendu : overlay rouge plein écran sur les 3 vues + son "He can't keep getting away with it" + thème stoppé
- Backglass affiche `STATUT : game_over`

## 🎥 Captation vidéo

- **Outil** : OBS Studio (gratuit) ou logiciel de capture intégré Windows (Win+G)
- **Résolution** : 1920x1080 minimum, 60 fps recommandé
- **Audio** : capturer le son système (pas juste le micro)
- **Format de sortie** : MP4 H.264, < 50 Mo si possible
- **Stockage** : `docs/demo/demo-soutenance.mp4` (et backup cloud)

## 🆘 Plan B si la démo live foire

1. Garder la vidéo enregistrée en local sur le PC de présentation
2. Vidéo pré-lancée en pause dans VLC dès le début de la soutenance
3. Si bug live : "Pas de souci, on a une captation de référence" → lancer la vidéo
4. Continuer le commentaire oral comme si de rien n'était
