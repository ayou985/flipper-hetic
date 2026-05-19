# Checklist de validation avant soutenance

Petite checklist pour relire le projet de bout en bout avant la demo.
Pas exhaustif, juste les points qui peuvent vraiment foirer le jour J.

## Lancement

- [ ] `npm run dev:all` demarre sans erreur les 4 services
- [ ] Les 3 onglets navigateur (5173, 5174, 5175) chargent
- [ ] Aucune erreur rouge dans la console (warnings tolérés)

## Playfield

- [ ] Bumpers visibles, scene lumineuse (post-processing actif)
- [ ] Flash bumper visible a chaque collision
- [ ] Bille glow ambre
- [ ] Overlay flash a chaque transition (start / game_over / milestone)

## Audio

- [ ] Son a chaque hit bumper (varié, pas tjrs le même sample)
- [ ] Theme principal se lance au start, s'arrête au game over
- [ ] Sample "game_over" joue a la perte
- [ ] Sample "milestone" joue au franchissement de 1000 pts
- [ ] Touches M / + / - fonctionnent
- [ ] Refresh -> volume et mute conserves

## Backglass

- [ ] Titre "FLIPPER HETIC" affiche correctement
- [ ] Score se met a jour en temps reel
- [ ] Flash radial a chaque event

## DMD

- [ ] Score visible sur le canvas
- [ ] Flash plein ecran a la perte / au start

## Sync

- [ ] Le score est identique sur backglass et DMD
- [ ] Le statut (idle / playing / game_over) coherent partout

## Production

- [ ] Tests : `npm run test --workspaces` passe
- [ ] Build : `npm run build:all` reussit
- [ ] PR ouverte, link les bonnes issues
- [ ] Captation video de secours pretes au cas ou
