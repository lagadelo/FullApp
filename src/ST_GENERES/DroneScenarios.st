"=========================================================="
"   Classe de scénarios DroneSystemWithOWS (Pharo 13)      "
"=========================================================="

Object subclass: #DroneScenarios
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Examples'.

DroneScenarios class>>exampleSurveillance
    | sim drones cluster mission polygon view |

    sim := SimulationState new.

    drones := {
        (Drone new moveToLat: 48.8566 lon: 2.3522 alt: 100).   "Paris"
        (Drone new moveToLat: 48.8666 lon: 2.3622 alt: 120).   "Paris nord-est"
        (Drone new moveToLat: 48.8466 lon: 2.3422 alt: 110).   "Paris sud-ouest"
    }.

    drones do: [:d | sim addDrone: d ].

    cluster := DroneCluster new initializeWith: drones id: 1.
    sim addCluster: cluster.

    polygon := {
        { 48.86 . 2.34 . 100 }.
        { 48.87 . 2.36 . 100 }.
        { 48.85 . 2.37 . 100 }.
        { 48.84 . 2.35 . 100 }
    }.

    mission := ClusterMission new initializeWithType: #surveillance params: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignTo: cluster.

    view := DroneMapWithOWSView new
        initializeWithSimulation: sim
        centerLat: 48.85
        centerLon: 2.35
        zoom: 12.

    view open.


DroneScenarios class>>exampleSecuring
    | sim drones cluster mission polygon view |

    sim := SimulationState new.

    drones := {
        (Drone new moveToLat: 48.8566 lon: 2.3522 alt: 100).   "Paris centre"
        (Drone new moveToLat: 48.8766 lon: 2.3622 alt: 100).   "Paris nord"
        (Drone new moveToLat: 48.8366 lon: 2.3422 alt: 100).   "Paris sud"
    }.

    drones do: [:d | sim addDrone: d ].

    cluster := DroneCluster new initializeWith: drones id: 2.
    sim addCluster: cluster.

    polygon := {
        { 48.88 . 2.34 . 100 }.
        { 48.87 . 2.37 . 100 }.
        { 48.84 . 2.36 . 100 }
    }.

    mission := ClusterMission new initializeWithType: #securisation params: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignTo: cluster.

    view := DroneMapWithOWSView new
        initializeWithSimulation: sim
        centerLat: 48.85
        centerLon: 2.35
        zoom: 12.

    view open.

"=========================================================="
"   Fin du fichier                                         "
"=========================================================="
