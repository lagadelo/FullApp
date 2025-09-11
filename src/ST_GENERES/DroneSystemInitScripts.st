"=== Script d'initialisation du système de drones (Europe - Mission de surveillance) ==="

| drones cluster mission simulation hud |

"Créer quelques drones placés en Europe"
drones := {
    Drone new.
    Drone new.
    Drone new.
} asOrderedCollection.

"Assigner des positions initiales réalistes (latitude, longitude, altitude)"
(drones at: 1) moveToLatitude: 48.8566 longitude: 2.3522 altitude: 500.   "Paris"
(drones at: 2) moveToLatitude: 52.5200 longitude: 13.4050 altitude: 600. "Berlin"
(drones at: 3) moveToLatitude: 41.9028 longitude: 12.4964 altitude: 550. "Rome"

"Créer un cluster"
cluster := DroneCluster new
    initializeWithDrones: drones
    clusterId: 1.

"Créer une mission de surveillance avec une zone polygonale (triangle Europe centrale)"
mission := ClusterMission new
    initializeWithType: #surveillance
    zoneParameters: (Dictionary new at: #polygon put: {
        { 50.1109. 8.6821. 500 }.   "Francfort"
        { 48.2100. 16.3738. 500 }. "Vienne"
        { 45.4642. 9.1900. 500 }.  "Milan"
    }; yourself).

mission assignToCluster: cluster.

"Créer une simulation"
simulation := SimulationState new.
simulation instVarNamed: 'drones' put: drones.
simulation instVarNamed: 'clusters' put: { cluster } asOrderedCollection.
simulation instVarNamed: 'missionHistory' put: OrderedCollection new.
simulation instVarNamed: 'time' put: 0.
simulation instVarNamed: 'eventLog' put: OrderedCollection new.
simulation instVarNamed: 'reactionLog' put: OrderedCollection new.
simulation instVarNamed: 'verificationFunctions' put: OrderedCollection new.

"Créer et ouvrir le HUD avec mise à jour temps réel"
hud := DroneMapHUD new
    initializeWithSimulation: simulation
    updateInterval: 1. "mise à jour toutes les secondes"

hud open.


"=== Script d'initialisation du système de drones (Europe - Mission de sécurisation) ==="

| drones cluster mission simulation hud |

"Créer quelques drones placés en Europe"
drones := {
    Drone new.
    Drone new.
    Drone new.
} asOrderedCollection.

"Assigner des positions initiales réalistes (latitude, longitude, altitude)"
(drones at: 1) moveToLatitude: 48.8566 longitude: 2.3522 altitude: 500.   "Paris"
(drones at: 2) moveToLatitude: 52.5200 longitude: 13.4050 altitude: 600. "Berlin"
(drones at: 3) moveToLatitude: 41.9028 longitude: 12.4964 altitude: 550. "Rome"

"Créer un cluster"
cluster := DroneCluster new
    initializeWithDrones: drones
    clusterId: 2.

"Créer une mission de sécurisation avec des positions fixes (Londres, Madrid, Varsovie)"
mission := ClusterMission new
    initializeWithType: #securisation
    zoneParameters: (Dictionary new at: #polygon put: {
        { 51.5074. -0.1278. 500 }.   "Londres"
        { 40.4168. -3.7038. 500 }.  "Madrid"
        { 52.2297. 21.0122. 500 }.  "Varsovie"
    }; yourself).

mission assignToCluster: cluster.

"Créer une simulation"
simulation := SimulationState new.
simulation instVarNamed: 'drones' put: drones.
simulation instVarNamed: 'clusters' put: { cluster } asOrderedCollection.
simulation instVarNamed: 'missionHistory' put: OrderedCollection new.
simulation instVarNamed: 'time' put: 0.
simulation instVarNamed: 'eventLog' put: OrderedCollection new.
simulation instVarNamed: 'reactionLog' put: OrderedCollection new.
simulation instVarNamed: 'verificationFunctions' put: OrderedCollection new.

"Créer et ouvrir le HUD avec mise à jour temps réel"
hud := DroneMapHUD new
    initializeWithSimulation: simulation
    updateInterval: 1. "mise à jour toutes les secondes"

hud open.
