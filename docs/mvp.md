# Définition du MVP – Flipper Web Multi-écran

## 1. Problème et utilisateur

Notre projet consiste à développer un flipper moderne jouable directement dans un navigateur et contrôlé à la fois par le clavier et par des boutons physiques via ESP32.  
L’utilisateur est un joueur (par exemple un étudiant lors de la démonstration) qui cherche une expérience fluide et immersive proche d’une borne d’arcade.  
Le principal enjeu est de réussir à synchroniser une simulation physique en temps réel sur plusieurs écrans tout en intégrant des contrôleurs physiques.

--

## 2. Définition du MVP

Le MVP correspond à la version minimale fonctionnelle du projet. Il devra inclure :

- Une table de flipper en 3D affichée dans le navigateur  
- Une bille avec une gravité et des collisions cohérentes  
- Deux flippers activables via le clavier et via l’ESP32  
- Un système de score mis à jour en temps réel  
- Une synchronisation fonctionnelle sur au moins deux écrans  

Nous avons volontairement limité le périmètre.  
Le MVP ne comprend pas d’effets visuels avancés, d’éditeur de table ou de fonctionnalités secondaires.

--

## 3. Critères de succès mesurables

Pour considérer le MVP comme validé :

- La bille doit rester stable et jouable pendant au moins deux minutes sans bug physique majeur.  
- Les deux écrans doivent afficher le même score sans décalage visible.  
- Le temps de réponse d’un bouton physique doit rester inférieur à 100 ms.  

Ces critères sont concrets et vérifiables lors des tests.

---

## 4. Contraintes du projet

Le projet est soumis à plusieurs contraintes :

- Une durée totale de 10 semaines.  
- Une équipe de 5 personnes avec des niveaux techniques différents.  
- Un budget limité (environ 50 à 80 euros pour le matériel).  
- Une dépendance au réseau WiFi local pour la communication temps réel.  
- Une démonstration finale sur plusieurs écrans en conditions réelles.

---

## 5. Top 3 risques et plans B

### Risque 1 : désynchronisation entre les écrans  
Plan B : mettre en place un écran “maître” qui diffuse l’état du jeu aux autres.

### Risque 2 : latence ou instabilité de l’ESP32  
Plan B : permettre un contrôle complet au clavier pour assurer la démonstration.

### Risque 3 : instabilité du moteur physique  
Plan B : simplifier la table (réduction des bumpers et des collisions complexes).