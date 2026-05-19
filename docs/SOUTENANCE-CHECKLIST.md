# Checklist de validation finale — Soutenance

> Référentiel **DoD** pour l'issue #80 — Passe finale "habillage flipper".
> Toutes les cases doivent être cochées avant la captation vidéo et la présentation orale.

## 🎬 Environnement de démo

- [ ] Les 4 services tournent sans erreur : `npm run dev:all`
- [ ] `http://localhost:5173` (Playfield) charge sans erreur console
- [ ] `http://localhost:5174` (Backglass) charge sans erreur console
- [ ] `http://localhost:5175` (DMD) charge sans erreur console
- [ ] Le serveur Socket.IO log bien `Serveur socket.io sur http://localhost:3000`
- [ ] Aucun warning bloquant dans la console navigateur (F12)

## 🎨 Cohérence visuelle (VFX — #79)

- [ ] **Playfield** : fond noir profond, bumpers jaune méth émissifs, ball avec halo ambre
- [ ] **Bloom** activé sur le playfield (tout brille naturellement)
- [ ] **Flash bumper** visible et net à chaque collision (scale pulse + emissive boost)
- [ ] **Overlay state** : flash jaune au start, rouge au game over, vert au milestone
- [ ] **Backglass** : titre "FLIPPER HETIC" en néon jaune méth (text-shadow triple)
- [ ] **Backglass** : score ambre brillant, flash radial à chaque action
- [ ] **DMD** : drop-shadow ambre permanent autour du canvas
- [ ] **DMD** : flash plein écran sur game over et start
- [ ] Cohérence palette sur les 3 écrans (jaune méth / vert toxique / ambre / rouge alerte)

## 🔊 Cohérence audio (Audio — #78)

- [ ] **Bumper hit** : 1 des 3 samples joué aléatoirement (pas de répétition)
- [ ] **Flipper fire (X/C)** : sample flipper joué à chaque appui
- [ ] **Game start (D)** : son "Ball Release" + thème principal en loop bas volume
- [ ] **Game over** : thème principal stoppe, sample "He can't keep getting away with it"
- [ ] **Milestone (1000 pts)** : sample "You're God damn right"
- [ ] Volumes équilibrés : aucun son n'écrase les autres
- [ ] Aucun trou de feedback audio sur les events principaux

## 🎚️ Contrôles UX audio (UX — #78)

- [ ] HUD audio visible en haut-droite (pill discret)
- [ ] **Touche M** : toggle mute fonctionnel (icône passe à 🔇, barre se vide)
- [ ] **Touche + / =** : volume monte par paliers de 5%
- [ ] **Touche − / _** : volume baisse par paliers de 5%
- [ ] **Clic sur l'icône** : toggle mute fonctionnel
- [ ] HUD fade-out après ~1.5s sans interaction
- [ ] **Persistance** : refresh la page → volume et mute conservés (localStorage)
- [ ] Bouger le slider remet en sourdine off si on était muté

## 🎮 Gameplay complet (parcours utilisateur)

- [ ] Démarrage : appuyer sur **D** ou **F** → la ball spawn, le thème démarre
- [ ] Lancement : **Espace** → la ball part vers le haut
- [ ] **Flèche gauche / X** : flipper gauche fonctionne
- [ ] **Flèche droite / C** : flipper droit fonctionne
- [ ] Hit bumper → flash + son + score incrémenté sur le backglass
- [ ] Hit slingshot → son + déviation correcte
- [ ] Ball perdue (drain) → décrémente les billes restantes
- [ ] 3 billes perdues → game over (overlay rouge + son + arrêt du thème)
- [ ] Score 1000+ → milestone vert toxique
- [ ] **R** : reset bille (debug) fonctionne

## 🌐 Synchronisation multi-écrans

- [ ] Score mis à jour en temps réel sur backglass ET DMD
- [ ] État (idle / playing / game_over) cohérent sur tous les écrans
- [ ] Pas de désync visible entre les 3 vues
- [ ] Latence WebSocket imperceptible (< 50ms localhost)

## ✅ Validation finale

- [ ] Tests unitaires passent : `npm run test:all`
- [ ] Build de production réussit : `npm run build:all`
- [ ] README à jour (instructions de lancement claires)
- [ ] PR `feat/vfx-bonus` à jour avec `Closes #78, #79, #80`
- [ ] Captation vidéo réalisée (60-90 secondes)
- [ ] Démo testée sur le PC qui sera utilisé en soutenance
- [ ] Plan B prêt : vidéo de secours si la démo live foire

---

**Date de validation :** _____________
**Validateur :** _____________
