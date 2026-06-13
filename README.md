# Robot Arm — URDF / Xacro & MoveIt 2

**Module :** Robotique Industrielle — Master 1 Robotique & Systèmes embarqués  
**Année :** 2025-2026  
**Technologies :** ROS 2 Humble · Xacro · MoveIt 2 · RViz 2

---

## Table des matières

1. [Présentation du robot](#1-présentation-du-robot)
2. [Justification du choix Xacro vs URDF](#2-justification-du-choix-xacro-vs-urdf)
3. [Hypothèses sur les masses, inerties et limites articulaires](#3-hypothèses-sur-les-masses-inerties-et-limites-articulaires)
4. [Structure du dépôt](#4-structure-du-dépôt)
5. [Installation pas-à-pas](#5-installation-pas-à-pas)
6. [Lancer RViz 2](#6-lancer-rviz-2)
7. [Lancer MoveIt 2](#7-lancer-moveit-2)
8. [Captures d'écran](#8-captures-décran)
9. [Difficultés rencontrées et solutions](#9-difficultés-rencontrées-et-solutions)

---

## 1. Présentation du robot

Le bras robotisé modélisé dans ce TP est un bras à **4 degrés de liberté** (DOF) avec une pince parallèle à deux doigts. Il est inspiré d'un bras de bureau type « Open Manipulator » de taille réduite.

### Chaîne cinématique

```
world (fixe)
  └── base_link          ← socle moteur (basement.stl)
        └── base_plate   ← plateau rotatif   [joint1 — révolution Z]
              └── forward_drive_arm           [joint2 — révolution X, shoulder]
                    └── horizontal_arm        [joint3 — révolution X, elbow]
                          └── claw_support    [joint_claw — révolution Z, wrist]
                                ├── gripper_right  [joint4 — prismatique X]
                                └── gripper_left   [joint_gripper_left — mimic]
```

| Segment | Mesh utilisé | Rôle |
|---|---|---|
| `base_link` | `basement.stl` | Socle fixe, supporte le moteur de rotation |
| `base_plate` | `base_plate.stl` | Plateau tournant (waist) |
| `forward_drive_arm` | `forward_drive_arm.stl` | Premier bras (épaule → coude) |
| `horizontal_arm` | `horizontal_arm.stl` | Deuxième bras (coude → poignet) |
| `claw_support` | `claw_support.stl` | Support de pince (poignet) |
| `gripper_right` | `right_finger.stl` | Doigt droit, commandé par `joint4` |
| `gripper_left` | `left_finger.stl` | Doigt gauche, miroir via `<mimic>` |

---

## 2. Justification du choix Xacro vs URDF

### Choix retenu : **Xacro modulaire**

#### Critère de décision

Le bras comporte plusieurs liens avec des patterns répétés (propriétés inertielles, matériaux, structure `<visual>/<collision>`). Le format Xacro permet :

- De définir des **macros paramétrables** (`box_inertia`) évitant la répétition de blocs XML identiques.
- D'utiliser des **constantes nommées** (`PI`, `mesh_scale`) en un seul endroit, ce qui simplifie la maintenance et réduit les erreurs.
- D'améliorer la **lisibilité** : le fichier Xacro est ~30 % plus court qu'un URDF équivalent.

#### Avantages de Xacro

| Avantage | Détail |
|---|---|
| **Réutilisabilité** | La macro `box_inertia` est appelée pour chaque link |
| **Maintenabilité** | Modifier l'échelle des meshes ne touche qu'une seule constante |
| **Lisibilité** | Les expressions mathématiques (`${PI/2}`) sont explicites |
| **Modularité** | Possibilité future de séparer bras / pince en fichiers `.xacro` inclus |

#### Inconvénients

| Inconvénient | Impact |
|---|---|
| Nécessite `xacro` pour compiler | Dépendance supplémentaire (mineure sous ROS 2) |
| Débogage moins direct | Les erreurs de macro peuvent être cryptiques |
| Pas utilisable directement par certains outils | Doit être converti en URDF (`xacro robot_arm.urdf.xacro > robot.urdf`) |

#### Quand aurions-nous choisi un URDF direct ?

Un fichier URDF unique aurait été préférable pour un robot très simple (2–3 joints, pas de répétition) ou pour une intégration dans un outil ne supportant pas Xacro. Dans ce cas, la complexité de la syntaxe Xacro ne serait pas justifiée par les gains.

---

## 3. Hypothèses sur les masses, inerties et limites articulaires

### Masses estimées

Les masses sont estimées sur la base d'une structure en plastique PLA imprimée en 3D, densité ≈ 1 200 kg/m³ :

| Lien | Masse estimée | Justification |
|---|---|---|
| `base_link` | 1.0 kg | Socle lourd, contient le moteur de base |
| `base_plate` | 0.5 kg | Plateau rotatif, plus léger |
| `forward_drive_arm` | 0.3 kg | Bras creux en plastique |
| `horizontal_arm` | 0.25 kg | Bras légèrement plus court |
| `claw_support` | 0.15 kg | Support de pince compact |
| `gripper_right/left` | 0.05 kg chacun | Doigts fins |

### Tenseurs d'inertie

Les tenseurs sont calculés avec la **formule analytique de la boîte solide** :

```
Ixx = m(y² + z²) / 12
Iyy = m(x² + z²) / 12
Izz = m(x² + y²) / 12
```

La macro `box_inertia` dans le Xacro applique cette formule automatiquement. C'est une approximation acceptable pour la planification de trajectoires en simulation (les meshes STL ne fournissent pas d'information sur la distribution de masse interne).

### Limites articulaires

| Joint | Type | Lower | Upper | Effort | Vitesse |
|---|---|---|---|---|---|
| `joint1` | Révolution | -π/2 | +π/2 | 100 N·m | 1.0 rad/s |
| `joint2` | Révolution | -π/2 | +π/2 | 100 N·m | 1.0 rad/s |
| `joint3` | Révolution | -π/2 | +π/2 | 100 N·m | 1.0 rad/s |
| `joint_claw` | Révolution | -π/2 | +π/2 | 50 N·m | 1.0 rad/s |
| `joint4` | Prismatique | 0 m | 0.022 m | 20 N | 0.5 m/s |

Les amplitudes ±π/2 sont conservatives pour un bras de bureau, évitant les auto-collisions.  
La limite supérieure du `joint4` (2.2 cm) est tirée directement du diagramme du TP.

---

## 4. Structure du dépôt

```
robot_arm_ws/
└── src/
    ├── robot_arm_description/          ← Package de description
    │   ├── urdf/
    │   │   └── robot_arm.urdf.xacro    ← Description complète du robot
    │   ├── meshes/
    │   │   ├── basement.stl
    │   │   ├── base_plate.stl
    │   │   ├── forward_drive_arm.stl
    │   │   ├── horizontal_arm.stl
    │   │   ├── claw_support.stl
    │   │   ├── right_finger.stl
    │   │   ├── left_finger.stl
    │   │   └── ...
    │   ├── launch/
    │   │   └── display.launch.py       ← Lance RViz 2
    │   ├── config/
    │   │   └── robot_arm.rviz          ← Config RViz 2
    │   ├── package.xml
    │   └── CMakeLists.txt
    │
    └── robot_arm_moveit_config/        ← Package MoveIt 2
        ├── config/
        │   ├── robot_arm.srdf          ← Groupes, collisions désactivées
        │   ├── kinematics.yaml         ← Solveur KDL
        │   ├── ompl_planning.yaml      ← Planificateur OMPL/RRTConnect
        │   ├── joint_limits.yaml       ← Limites vitesse/accélération
        │   └── moveit_controllers.yaml ← Contrôleurs simulés
        ├── launch/
        │   └── demo.launch.py          ← Lance MoveIt 2 + RViz 2
        ├── package.xml
        └── CMakeLists.txt
```

---

## 5. Installation pas-à-pas

### Prérequis

- Ubuntu 22.04 LTS
- ROS 2 Humble (ou Jazzy) installé et sourcé
- MoveIt 2 installé :

```bash
sudo apt install ros-humble-moveit
```

### Cloner le dépôt

```bash
mkdir -p ~/robot_arm_ws/src
cd ~/robot_arm_ws/src
git clone https://github.com/<VOTRE_USERNAME>/robot_arm_ws.git .
```

### Installer les dépendances

```bash
cd ~/robot_arm_ws
rosdep install --from-paths src --ignore-src -r -y
```

### Compiler le workspace

```bash
cd ~/robot_arm_ws
colcon build --symlink-install
source install/setup.bash
```

> **Conseil :** Ajoutez `source ~/robot_arm_ws/install/setup.bash` à votre `~/.bashrc` pour ne pas avoir à le faire à chaque terminal.

### Vérifier le URDF (optionnel)

```bash
# Convertir Xacro → URDF et vérifier
cd ~/robot_arm_ws/src/robot_arm_description/urdf
xacro robot_arm.urdf.xacro > /tmp/robot_arm.urdf
check_urdf /tmp/robot_arm.urdf
```

---

## 6. Lancer RViz 2

```bash
# Dans un terminal sourcé
ros2 launch robot_arm_description display.launch.py
```

Cela lance :
- `robot_state_publisher` — publie le TF depuis le URDF
- `joint_state_publisher_gui` — sliders interactifs pour chaque joint
- `rviz2` — visualisation 3D du modèle

> Vérifiez dans RViz que le panneau **TF** ne montre aucune erreur (tous les frames doivent apparaître en blanc, pas en rouge).

---

## 7. Lancer MoveIt 2

```bash
# Dans un terminal sourcé
ros2 launch robot_arm_moveit_config demo.launch.py
```

Cela lance :
- `robot_state_publisher`
- `move_group` (nœud MoveIt 2 principal)
- `rviz2` avec le plugin **MotionPlanning**

### Planifier une trajectoire dans RViz 2

1. Dans le panneau **MotionPlanning**, onglet **Planning**, sélectionnez le groupe `arm`.
2. Cliquez sur **Update** pour afficher l'état courant.
3. Déplacez le marqueur interactif de l'effecteur terminal vers une nouvelle pose cible.
4. Cliquez sur **Plan** pour générer la trajectoire.
5. Cliquez sur **Execute** pour exécuter la trajectoire sur le robot simulé.

---

## 8. Captures d'écran

> *Les captures d'écran suivantes sont à réaliser après lancement sur votre machine.*

| Vue | Description |
|---|---|
| `screenshots/rviz_model.png` | Modèle complet dans RViz 2, joints à zéro (pose home) |
| `screenshots/rviz_collision.png` | Représentation des formes de collision (boîtes/cylindres) |
| `screenshots/moveit_planning.png` | Trajectoire planifiée avec MoveIt 2 (pose home → extended) |
| `screenshots/moveit_execute.png` | Robot après exécution de la trajectoire |

---

## 9. Difficultés rencontrées et solutions

### 1. Echelle des meshes STL

**Problème :** Les fichiers `.stl` fournis sont en millimètres ; dans ROS/URDF l'unité est le mètre. Le robot apparaissait 100× trop grand.

**Solution :** Ajout d'un attribut `scale="0.01 0.01 0.01"` sur chaque balise `<mesh>`, ce qui correspond à une division par 100 (mm → cm → m).

### 2. Positionnement des origines visuelles

**Problème :** Les origines données dans le TP (ex. `xyz="-0.5 -0.5 0"`) sont relatives à l'origine du mesh, pas au joint. Il a fallu distinguer l'*origine du joint* (offset cinématique) de l'*origine du visuel* (offset d'affichage).

**Solution :** Dans chaque `<link>`, la balise `<visual><origin>` positionne le mesh dans le repère du link. La balise `<joint><origin>` positionne le repère du link fils par rapport au repère du link parent (offset cinématique tiré des mesures du TP).

### 3. Gripper mimic joint

**Problème :** MoveIt 2 ne planifie pas directement les joints `mimic` ; il faut les exclure du groupe de planification ou les traiter via un contrôleur dédié.

**Solution :** Seul `joint4` (doigt droit) est inclus dans le groupe `gripper`. La balise `<mimic joint="joint4" multiplier="-1"/>` assure que le doigt gauche suit automatiquement en simulation. Pour un vrai robot, un contrôleur hardware devrait gérer la synchronisation.

### 4. TF warnings au démarrage

**Problème :** Au premier lancement, des warnings TF apparaissaient pour le link `world` (frame introuvable).

**Solution :** Ajout du joint `world_to_base` de type `fixed` reliant `world` à `base_link`. Le `Fixed Frame` dans RViz 2 doit être réglé sur `world` (et non `base_link`).

---

*TP réalisé dans le cadre du cours Robotique Industrielle — K. Ramoth — 2026*
