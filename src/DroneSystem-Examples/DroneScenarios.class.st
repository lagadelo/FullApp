"
""-----------------------------""
"" Scenarios convenience class""
""-----------------------------""

"
Class {
	#name : 'DroneScenarios',
	#superclass : 'Object',
	#category : 'DroneSystem-Examples',
	#package : 'DroneSystem-Examples'
}

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleSecuring [
    | sim drones cluster mission polygon view |
    sim := SimulationState new initialize.
    sim setAsCurrent.
    drones := { Drone new. Drone new. Drone new } asOrderedCollection.
    (drones at: 1) moveToLatitude: 48.8566 longitude: 2.3522 altitude: 120.
    (drones at: 2) moveToLatitude: 48.8766 longitude: 2.3622 altitude: 120.
    (drones at: 3) moveToLatitude: 48.8366 longitude: 2.3422 altitude: 120.
    cluster := DroneCluster new initializeWithDrones: drones clusterId: 2.
    sim addFleet: (DroneFleet new initializeWithClusters: { cluster } id: 2 hostile: false name: 'Green').
    polygon := { { 48.88. 2.34. 100 }. { 48.87. 2.37. 100 }. { 48.84. 2.36. 100 }. }.
    mission := ClusterMission new initializeWithType: #securisation zoneParameters: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignToCluster: cluster.
    view := DroneMapWithOWSView new initializeWithSimulation: sim centerLat: 48.8566 centerLon: 2.3522 zoom: 12.
    view open.
    ^ sim.
]

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleSurveillance [
    | sim drones cluster mission polygon view |
    sim := SimulationState new initialize.
    sim setAsCurrent.
    drones := { Drone new. Drone new. Drone new } asOrderedCollection.
    (drones at: 1) moveToLatitude: 48.8566 longitude: 2.3522 altitude: 120.
    (drones at: 2) moveToLatitude: 48.8666 longitude: 2.3622 altitude: 120.
    (drones at: 3) moveToLatitude: 48.8466 longitude: 2.3422 altitude: 120.
    cluster := DroneCluster new initializeWithDrones: drones clusterId: 1.
    sim addFleet: (DroneFleet new initializeWithClusters: { cluster } id: 1 hostile: false name: 'Blue').
    polygon := { { 48.86. 2.34. 100 }. { 48.87. 2.36. 100 }. { 48.85. 2.37. 100 }. }.
    mission := ClusterMission new initializeWithType: #surveillance zoneParameters: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignToCluster: cluster.
    view := DroneMapWithOWSView new initializeWithSimulation: sim centerLat: 48.8566 centerLon: 2.3522 zoom: 12.
    view open.
    ^ sim.

]
