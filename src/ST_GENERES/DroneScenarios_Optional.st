
Object subclass: #DroneScenarios
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-System'.

"--- Exemple de scénario de surveillance ---"
DroneScenarios class>>exampleSurveillance
    | drones cluster mission state view |
    drones := (1 to: 5) collect: [:i | Drone new ].
    cluster := DroneCluster new initializeWithDrones: drones clusterId: 1.
    mission := ClusterMission new initializeWithType: #surveillance zoneParameters: (Dictionary new at: #polygon put: { {48.85. 2.35. 100}. {48.86. 2.36. 100}. {48.87. 2.35. 100}. }; yourself).
    mission assignToCluster: cluster.
    state := SimulationState new.
    state initializeWithDrones: drones clusters: { cluster }.
    "Vue avec Roassal et OWS optionnel"
    (Smalltalk includesKey: #OWSMapView)
        ifTrue: [ view := OWSMapView new.
                  view center: (48.8566 @ 2.3522).
                  view zoomLevel: 12.
                  view addOverlay: (DroneMapView new initializeWithDrones: drones clusters: { cluster }).
                  view open ]
        ifFalse: [ view := DroneMapView new initializeWithDrones: drones clusters: { cluster }.
                  view open ].
    state startUpdatingEvery: 1 second.

"--- Exemple de scénario de sécurisation ---"
DroneScenarios class>>exampleSecuring
    | drones cluster mission state view |
    drones := (1 to: 4) collect: [:i | Drone new ].
    cluster := DroneCluster new initializeWithDrones: drones clusterId: 2.
    mission := ClusterMission new initializeWithType: #securisation zoneParameters: (Dictionary new at: #polygon put: { {48.85. 2.34. 100}. {48.85. 2.36. 100}. {48.87. 2.36. 100}. {48.87. 2.34. 100}. }; yourself).
    mission assignToCluster: cluster.
    state := SimulationState new.
    state initializeWithDrones: drones clusters: { cluster }.
    "Vue avec Roassal et OWS optionnel"
    (Smalltalk includesKey: #OWSMapView)
        ifTrue: [ view := OWSMapView new.
                  view center: (48.8566 @ 2.3522).
                  view zoomLevel: 12.
                  view addOverlay: (DroneMapView new initializeWithDrones: drones clusters: { cluster }).
                  view open ]
        ifFalse: [ view := DroneMapView new initializeWithDrones: drones clusters: { cluster }.
                  view open ].
    state startUpdatingEvery: 1 second.
