# 7. Risques et contraintes

##  Tableau des risques

| Risque | Probabilité | Impact | Mitigation (solution prévue) |
|---------|-------------|--------|------------------------------|
| Désynchronisation multi-écran | Moyenne | Élevé | Serveur autoritaire + tests de synchronisation dès S2 |
| Latence WiFi des ESP32 | Moyenne | Moyen | Tests réseau anticipés + fallback clavier |
| Instabilité du moteur physique | Moyenne | Élevé | Utilisation d’un fixed timestep + POC physique |
| Mauvaise gestion des états du jeu | Faible | Élevé | Diagramme d’état UML + validation serveur |
| Retard sur la partie hardware | Moyenne | Moyen | Développement parallèle d’un mode sans ESP32 |
| Mauvaise répartition du travail | Faible | Moyen | Planning clair + conventions Git + revues régulières |
| Complexité sous-estimée du temps réel | Moyenne | Élevé | POC WebSocket précoce + simplification du MVP si nécessaire |

---

##  Contraintes du projet

###  Contraintes temporelles

- Durée totale : **10 semaines**
- Livraison finale avec **démonstration fonctionnelle**
- CDC validé avant développement complet

---

###  Contraintes humaines

- Équipe de **5 personnes**
- Niveaux techniques différents
- Nécessité de coordination régulière

---

###  Contraintes techniques

- Projet **web-native obligatoire**
- Synchronisation multi-écran
- Communication temps réel stable
- Intégration hardware via WiFi

---

###  Contraintes matérielles

- Budget limité (~50–80€)
- 1 ou 2 ESP32 disponibles
- 3 écrans nécessaires pour la démonstration
