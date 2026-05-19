# Trame d'oral

Notes perso pour la soutenance, a adapter selon le temps. ~5 minutes total.

## Intro

Flipper HETIC Web3 : flipper virtuel multi-ecrans (playfield 3D, backglass,
DMD), prevu pour etre pilotable plus tard par un controleur IoT.

## Architecture

- Monorepo JS avec npm workspaces.
- Serveur Node.js + Socket.IO autoritatif sur l'etat de jeu.
- Trois clients Vite : playfield (Three.js + Rapier), backglass (DOM), DMD
  (Canvas).
- Package `shared/` pour les noms d'events Socket.IO.
- Architecture en couches : `domain/` pur, `usecases/` agnostiques,
  `adapters/` pour les libs externes, `composition/` pour le wiring.

Le point qui me semble fort : on a migre la physique de Cannon-es a Rapier
sans toucher au gameplay, justement parce que tout passait par cette
couche adapter.

## Demo

(voir DEMO-SCRIPT.md)

Pendant la demo, mentionner :
- les VFX bloom + flash bumpers + overlays, alignes sur une palette unique
- le moteur audio Web Audio API (pas de lib externe), preload + GainNode
  master + persistance localStorage
- la sync temps reel entre les 3 vues, gere par les events Socket.IO

## Trois choix qui meritent d'etre expliques

1. Rapier en WebAssembly plutot que Cannon-es. Cannon nous donnait des
   FPS instables avec plusieurs corps actifs en simultane. Rapier est plus
   rapide et plus deterministe. La migration a ete facilitee par
   l'isolation du moteur physique derriere un port.

2. Socket.IO en mode "single source of truth serveur". C'est le serveur
   qui detient l'etat. Les clients sont consommateurs. Ca permet de
   brancher demain un ESP32 ou un Arduino qui emule juste le clavier,
   sans toucher au reste.

3. Web Audio API native plutot qu'Howler. On voulait un controle fin
   de la chaine audio (GainNode master, gestion du mute, preload), et eviter
   une dependance externe sur quelque chose qu'on pouvait faire en 100
   lignes.

## Conclusion

Projet dockerise (`docker-compose.yml` a la racine), CI/CD en place
(`.github/workflows/`), documentation dans `docs/`. La derniere PR
clot les issues bonus du backlog soutenance.

## Questions probables

Three.js plutot que Babylon ou Pixi ?
Ecosysteme le plus mature, beaucoup de modules cle en main pour le post-
processing. Babylon serait justifie pour un projet plus gros, Pixi est 2D
donc hors sujet.

Pourquoi un monorepo ?
Pour partager `shared/` (noms d'events) entre serveur et clients. Avec npm
workspaces, c'est trivial a gerer.

Comment tu testes une scene 3D ?
On ne teste pas la scene. On teste les use cases (collisionHandler,
drain logic) qui sont du JS pur. Le rendu, c'est valide visuellement.

Securite WebSocket ?
Sur ce projet pedagogique, tout est local. En prod : token JWT au
handshake, validation des payloads cote serveur.

Sur quoi tu as galere ?
La migration Cannon -> Rapier. APIs differentes, concept de handles au
lieu de references. Mais ca a force a mieux separer les couches, donc
gain net.

La suite ?
Issues #74 (10 solenoides IoT) et #75 (persistance highscores). Le hook
IoT est deja prevu dans `input.js`, il manque le bridge ESP32.
