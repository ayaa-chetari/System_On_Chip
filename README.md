

# Architecture du système Qsys avec composant personnalisé Avalon

## 1. Introduction

Cette partie  consiste à intégrer un composant matériel personnalisé dans un système embarqué basé sur un processeur Nios II sur FPGA DE1.

L’objectif principal est de :

- créer un périphérique matériel personnalisé (`reg16`)
- l’intégrer dans Qsys
- permettre au processeur Nios II de communiquer avec ce périphérique via le bus Avalon
- afficher la valeur du registre sur les afficheurs 7 segments de la carte DE1



---

# 2. Architecture globale du système

```text
+--------------------------------------------------------------+
|                         FPGA DE1                             |
|                                                              |
|  +--------------------------------------------------------+  |
|  |              DE1_Basic_Computer.vhd                   |  |
|  |                    (Top Level)                        |  |
|  |                                                        |  |
|  |   +------------------------------------------------+   |  |
|  |   |               nios_system                      |   |  |
|  |   |                  (Qsys)                        |   |  |
|  |   |                                                |   |  |
|  |   |    +-------------------------------+           |   |  |
|  |   |    |          Nios II              |           |   |  |
|  |   |    +---------------+---------------+           |   |  |
|  |   |                    | Avalon-MM                |   |  |
|  |   |                    v                          |   |  |
|  |   |    +-------------------------------+          |   |  |
|  |   |    |  reg16_avalon_interface       |          |   |  |
|  |   |    |                               |          |   |  |
|  |   |    |       
|  |   |    |   
|  |   |    +---------------+---------------+          |   |    |
|  |   |                    |                          |   |    |
|  |   |                    v                          |   |    |
|  |   |                +--------+                    |   |    |
|  |   |                | reg16  |                    |   |    |
|  |   |                +--------+                    |   |    |
|  |   +------------------------------------------------+   |    |
|  |                      avalon conduit                    |    |
|  |             +----------------------+                   |    |
|  |             |      hex7seg         |<------------------+    |
|  |             +----------------------+                        |
|  +-------------------------------------------------------------+
|
+--------------------------------------------------------------+
```

---

# 3. Description des fichiers

| Fichier | Rôle |
|---|---|
| `DE1_Basic_Computer.vhd` | Top-level du FPGA |
| `nios_system.qsys` | Système Qsys contenant le Nios II et les périphériques |
| `reg16.vhd` | Registre matériel 16 bits |
| `reg16_avalon_interface.vhd` | Interface Avalon du composant personnalisé |
| `hex7seg.vhd` | Décodeur pour les afficheurs 7 segments |

---

# 4. Description du composant personnalisé

Le composant personnalisé est constitué de deux blocs :

```text
+-----------------------------------+
| reg16_avalon_interface            |
|                                   |
|  +-----------------------------+  |
|  |         reg16              |  |
|  +-----------------------------+  |
|                                   |
+-----------------------------------+
```

- `reg16` : stockage des données
- `reg16_avalon_interface` : interface entre le bus Avalon et le registre

Le registre `reg16` ne communique pas directement avec le processeur.

Toute la communication avec le système Qsys passe par `reg16_avalon_interface`.

---

# 5. Interfaces Avalon utilisées

Le composant personnalisé possède deux interfaces Avalon différentes :

| Interface | Type | Rôle |
|---|---|---|
| Avalon Memory-Mapped | Avalon-MM | communication avec le processeur Nios II |
| Avalon Conduit | Avalon Conduit | exportation des données vers l’extérieur |



---

# 6. Interface Avalon-MM

## Rôle

L’interface Avalon-MM permet au processeur Nios II :

- d’écrire dans le registre
- de lire le contenu du registre

Le composant agit comme un **slave Avalon-MM**.

Le processeur Nios II agit comme un **master Avalon-MM**.

---

## Signaux Avalon-MM utilisés

Dans `reg16_avalon_interface.vhd`, les signaux utilisés sont :

| Signal | Rôle |
|---|---|
| `clock` | horloge système |
| `resetn` | reset actif à 0 |
| `write` | demande d’écriture |
| `read` | demande de lecture |
| `chipselect` | sélection du composant |
| `writedata` | données envoyées par le Nios II |
| `readdata` | données retournées au Nios II |
| `byteenable` | validation des données |

---

# 7. Interface Avalon Conduit

## Rôle

L’interface Conduit permet d’exporter des signaux hors du système Qsys.

Dans cette partie , elle sert à envoyer la valeur du registre vers les afficheurs 7 segments.

---

## Signal utilisé

Le signal Conduit utilisé est :

Q_export
```

Ce signal contient la valeur du registre 16 bits.

---

# 8. Communication complète dans le système

## Écriture depuis le processeur

Le programme C exécute :

```c
IOWR(BASE,0,0x1234);
```

Flux matériel :

```text
Nios II
   |
Avalon-MM
   |
reg16_avalon_interface
   |
reg16
```

---

## Affichage sur les afficheurs HEX

La valeur du registre est ensuite exportée :

```text
reg16
   |
Q_export
   |
hex7seg
   |
HEX0..HEX3
```

---



---

# 10. Comment l’architecture répond à l’objectif

Cette architecture répond exactement aux exigences du tutoriel :

| Exigence | Réponse dans l’architecture |
|---|---|
| Création d’un composant personnalisé | `reg16.vhd` |
| Interface Avalon-MM | `reg16_avalon_interface.vhd` |
| Communication avec Nios II | bus Avalon-MM |
| Exportation externe | interface Conduit `Q_export` |
| Affichage sur FPGA | `hex7seg.vhd` |
| Intégration dans Qsys | `nios_system.qsys` |

Le processeur Nios II peut accéder au registre comme à une zone mémoire grâce au principe du **Memory-Mapped I/O**.

L’interface Avalon-MM assure la communication entre le logiciel et le matériel.

L’interface Avalon Conduit permet d’exporter la valeur du registre hors du système Qsys afin de l’utiliser dans le top-level FPGA.

Cette architecture montre comment intégrer un composant matériel personnalisé dans un système embarqué FPGA basé sur Qsys.

---

# 11. Conclusion

Cette architecture met en œuvre un système embarqué FPGA complet basé sur :

- un processeur Nios II
- un composant matériel personnalisé
- le protocole Avalon-MM
- une interface Conduit

Le composant personnalisé possède deux interfaces Avalon :

1. une interface Avalon-MM pour communiquer avec le Nios II
2. une interface Avalon Conduit pour exporter les données vers l’extérieur

Le processeur écrit dans le registre via le bus Avalon-MM et la valeur est affichée sur les afficheurs 7 segments grâce au signal `Q_export`.

Cette architecture constitue un exemple complet d’intégration d’un IP personnalisé dans un système Qsys.
