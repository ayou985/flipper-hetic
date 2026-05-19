# Script oral — Soutenance Flipper HETIC Web3

> Texte de référence pour la présentation orale (~5 minutes de parole).
> À adapter selon le temps imparti et les questions du jury.

---

## Intro (30 secondes)

> "Bonjour. Je vais vous présenter le projet **Flipper HETIC Web3** : un flipper virtuel multi-écrans, jouable au clavier et contrôlable par un système IoT en aval.
>
> L'idée, c'est de reproduire l'expérience d'un vrai flipper d'arcade dans le navigateur, avec trois vues synchronisées en temps réel : un **playfield 3D** où se joue l'action, un **backglass** qui affiche les scores, et un **DMD** — le dot matrix display façon machines à sous des années 80."

## Architecture technique (60 secondes)

> "Côté technique, c'est un **monorepo JavaScript** géré avec npm workspaces. On a 4 services qui communiquent en temps réel via **Socket.IO** :
>
> - Un **serveur Node.js** qui centralise l'état de jeu (score, billes restantes, statut)
> - Trois clients web buildés avec **Vite** : le playfield qui utilise **Three.js** pour le rendu 3D et **Rapier** comme moteur physique, plus le backglass et le DMD qui sont des vues HTML/Canvas plus simples.
>
> J'ai opté pour une **architecture hexagonale** côté playfield : les use cases (gestion des collisions, drain, etc.) sont du JavaScript pur, sans aucune dépendance Three.js ou Rapier. La couche adaptateur fait le pont avec les frameworks. Ça nous permet de tester la logique métier de manière isolée et de pouvoir changer le moteur physique sans toucher au gameplay — ce qui nous a justement servi quand on a **migré de Cannon-es à Rapier** pour des raisons de performance."

## Démo (90 secondes — voir DEMO-SCRIPT.md)

> "Je vous montre tout ça en action."
>
> [Lancer la démo selon le `DEMO-SCRIPT.md`. Pendant que vous jouez :]
>
> "Vous voyez ici les **VFX** alignés sur un thème **Breaking Bad** : palette jaune méthamphétamine pour les bumpers, vert toxique pour les milestones, ambre pour la ball. Le post-processing Three.js avec **UnrealBloomPass** donne ce rendu lumineux quasi-arcade."
>
> "Les **trois écrans réagissent à chaque événement** : un hit bumper déclenche un flash sur le playfield, un pulse sur le backglass, et une mise à jour du DMD — tout ça via les events Socket.IO."
>
> "Côté audio, j'ai intégré un système basé sur la **Web Audio API native** : les samples sont préchargés au démarrage, joués via un AudioContext partagé avec un GainNode master qui gère le volume global et le mute. Les contrôles sont mappés au clavier — **M pour mute, + et - pour le volume** — et les préférences sont persistées en localStorage."

## Choix techniques marquants (60 secondes)

> "Trois choix méritent d'être soulignés :
>
> **Un :** la **migration de Cannon-es à Rapier**. Cannon nous donnait des FPS instables avec plusieurs corps actifs simultanés. Rapier, compilé en WebAssembly, nous a permis de passer à 60 FPS stables même avec le bloom postprocessing activé. La migration a été facilitée par l'architecture hexagonale : tout le code métier est resté inchangé.
>
> **Deux :** l'utilisation de **Socket.IO en mode "single source of truth serveur"**. C'est le serveur qui détient l'état autoritatif. Les clients sont des consommateurs d'événements. Ça nous permet de brancher demain un **contrôleur IoT** — typiquement un ESP32 ou un Arduino qui émulerait le clavier — sans changer une ligne côté playfield.
>
> **Trois :** l'**audio entièrement Web Audio API native**, sans dépendance externe comme Howler. Ça nous permet un contrôle fin de la chaîne audio, un préchargement asynchrone propre, et une lecture stable avec anti-spam intégré."

## Conclusion (30 secondes)

> "Le projet est **dockerisé** — il y a un `docker-compose.yml` à la racine — il a une CI/CD configurée, et un référentiel de documentation complet dans le dossier `docs/`. La PR `feat/vfx-bonus` clôture les trois dernières issues du backlog : VFX, audio et passe finale d'habillage.
>
> Merci, je suis prêt pour vos questions."

---

## 💬 Questions probables du jury et réponses préparées

**Q : Pourquoi Three.js plutôt que Babylon ou PixiJS ?**
R : Three.js est l'écosystème 3D web le plus mature, avec une communauté énorme et des modules clé en main comme l'EffectComposer pour le post-processing. Babylon aurait demandé plus de courbe d'apprentissage pour des gains marginaux sur un projet de cette taille. PixiJS est 2D, donc hors sujet pour un flipper en perspective.

**Q : Pourquoi un monorepo ?**
R : Pour partager le package `shared/` qui contient les noms d'événements Socket.IO. Source unique de vérité côté serveur et clients — fini les typos `bumper_hit` vs `bumperHit`. Les npm workspaces gèrent ça nativement.

**Q : Comment tu tests une scène 3D ?**
R : Je ne teste pas la scène elle-même. Je teste les use cases (logique métier) qui sont du JavaScript pur. Les fichiers `__tests__/` couvrent le `collisionHandler` (cooldowns, drain, impulses bumper) et les `actuators` (compteurs d'événements). Le rendu Three.js, c'est validé visuellement.

**Q : Et la sécurité du WebSocket ?**
R : Sur ce projet pédagogique, tout est local — pas d'authentification. En prod, on ajouterait un token JWT côté handshake et une validation des payloads avec une lib type Zod côté serveur.

**Q : Pourquoi Rapier en WebAssembly et pas une lib JS pure ?**
R : Rapier est écrit en Rust, compilé en WASM. C'est 5 à 10× plus rapide que Cannon-es sur les checks de collision intensifs. Pour un flipper où la physique est centrale, c'était le bon trade-off.

**Q : Tu as galéré sur quoi ?**
R : Honnêtement, la migration Cannon → Rapier. Les APIs sont différentes — Rapier utilise des handles plutôt que des références d'objets — et le concept de `world.step` avec fixed timestep demandait de repenser la boucle de jeu. Mais ça nous a forcés à mieux séparer adapters / use cases, donc gain net.

**Q : Et la suite ?**
R : Les issues #74 (pilotage IoT 10 solénoïdes) et #75 (persistance highscores) sont les prochaines étapes post-MVP. Le hook IoT est déjà prévu dans `input.js` via `bindExternalInputSource`, il manque juste le bridge ESP32 / serial.

---

## ⏱️ Timing global

| Phase | Durée |
|---|---|
| Intro | 30s |
| Architecture | 60s |
| Démo | 90s |
| Choix techniques | 60s |
| Conclusion | 30s |
| **Total parole** | **~4min30** |
| Questions | 5–10min |

## 🎙️ Conseils delivery

- **Parler lentement** : tendance naturelle à accélérer sous stress
- **Pointer concrètement** ce qu'on voit à l'écran ("ici", "regardez le score qui monte")
- **Pause de respiration** entre chaque grande partie
- **Ne pas s'excuser** pour ce qui n'est pas fait (#74, #75 sont post-MVP, c'est assumé)
- **Confiance** : tu as déployé une architecture propre, une démo qui marche, et un thème cohérent. C'est solide.

Bonne soutenance ! 🚀
