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
DroneScenarios class >> example10 [ 

"1. Drones"
| drones waypoints mission cluster simulator |
drones := (1 to: 10) collect: [:i |
    Drone new
        initializeId: i
        position: 0@0;
        yourself
].

"2. Waypoints (6 sommets d’un hexagone)"
waypoints := {
    0@0.  10@0.  15@8.  10@16.  0@16.  -5@8
} asOrderedCollection.

"3. Mission et Cluster"
mission := SurveillanceMission new initializeWithWaypoints: waypoints cluster: nil.
cluster := Cluster new initializeWithDrones: drones mission: mission.
mission cluster: cluster.

"4. Simulateur"
simulator := DroneSimulator new initializeWithMission: mission.

"5. Planifier le début de patrouille pour chaque drone"
drones do: [:drone |
    mission planNextPatrolFor: drone at: 0 in: simulator
].

"6. Simuler une détection d’intrus par le drone 1 à t = 5"
simulator scheduleEvent: (
    IntrusionDetectedEvent new
        timestamp: 5;
        drone: drones first;
        intruderPosition: 7@7;
        yourself
) after: (Set with: cluster).

"7. Lancer la simulation pas à pas (Transcript doit être ouvert)"
1 to: 15 do: [:t |
    simulator runStep.
].

]

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleRealisticFranceEngagement [ [
    "Realistic scenario:
    - 12 allied drones patrol a surveillance zone over France (Paris region).
    - Each drone has limited ammunition and energy.
    - 4 hostile drones enter from the north-east.
    - Hostiles attempt to cross the zone; allies must intercept.
    - Each engagement consumes ammunition.
    - Metrics: number of hostiles intercepted, ammunition spent, drones lost, zone breach events."

    | alliedDrones hostiles surveillanceWaypoints mission cluster hostileCluster simulator
      engagementEvents metrics step maxSteps zoneBreaches interceptedHostiles dronesLost ammoSpent |

    "Define Paris region surveillance waypoints (approximate lat/lon)"
    surveillanceWaypoints := {
        Waypoint latitude: 48.8566 longitude: 2.3522 altitude: 1200.  "Paris center"
        Waypoint latitude: 48.90 longitude: 2.30 altitude: 1200.
        Waypoint latitude: 48.90 longitude: 2.40 altitude: 1200.
        Waypoint latitude: 48.83 longitude: 2.30 altitude: 1200.
        Waypoint latitude: 48.83 longitude: 2.40 altitude: 1200.
        Waypoint latitude: 48.87 longitude: 2.37 altitude: 1200.
        Waypoint latitude: 48.85 longitude: 2.36 altitude: 1200.
    }.

    "Create 12 allied drones with ammo and energy"
    alliedDrones := (1 to: 12) collect: [:i |
        Drone new
            id: i;
            position: (GeoPoint latitude: 48.85 + (0.01 * (i \\ 4)) longitude: 2.35 + (0.01 * (i // 4)) altitude: 1200);
            ammunition: 4;
            energy: 1000;
            status: #active;
            yourself
    ].

    "Allied surveillance mission"
    mission := SurveillanceMission new
        waypoints: surveillanceWaypoints;
        yourself.

    cluster := DroneCluster new
        drones: alliedDrones.
    mission assignToCluster: cluster.

    "Create 4 hostile drones entering from NE"
    hostiles := (1 to: 4) collect: [:i |
        Drone new
            id: (100 + i);
            position: (GeoPoint latitude: 48.92 longitude: 2.45 + (0.01 * i) altitude: 1200);
            ammunition: 2;
            energy: 800;
            status: #hostile;
            yourself
    ].
    hostileCluster := DroneCluster new
        drones: hostiles.

    "Simulator with both clusters"
    simulator := DroneSimulator new
        clusters: { cluster. hostileCluster };
        yourself.

    "Metrics initialization"
    metrics := Dictionary new.
    metrics at: #interceptedHostiles put: 0.
    metrics at: #ammoSpent put: 0.
    metrics at: #dronesLost put: 0.
    metrics at: #zoneBreaches put: 0.

    maxSteps := 100.
    engagementEvents := OrderedCollection new.
    zoneBreaches := 0.
    interceptedHostiles := 0.
    dronesLost := 0.
    ammoSpent := 0.

    "Schedule hostiles to move through the zone"
    hostiles do: [:h |
        | path |
        path := {
            Waypoint latitude: 48.92 longitude: 2.45 altitude: 1200.
            Waypoint latitude: 48.85 longitude: 2.36 altitude: 1200.
            Waypoint latitude: 48.80 longitude: 2.30 altitude: 1200.
        }.
        1 to: path size - 1 do: [:i |
            simulator scheduleEvent: (MoveToWaypointEvent new
                drone: h;
                waypoint: (path at: i + 1);
                yourself) at: (i * 10).
        ].
    ].

    "Main simulation loop"
    1 to: maxSteps do: [:step |
        "Check for possible engagements"
        alliedDrones do: [:ad |
            (ad status = #active and: [ad ammunition > 0]) ifTrue: [
                hostiles do: [:hd |
                    (hd status = #hostile and: [
                        ad position distanceTo: hd position < 0.02
                    ]) ifTrue: [
                        "Engagement: intercept"
                        ad ammunition: ad ammunition - 1.
                        ammoSpent := ammoSpent + 1.
                        hd status: #intercepted.
                        interceptedHostiles := interceptedHostiles + 1.
                        engagementEvents add: {step. ad id. hd id}.
                    ].
                ].
            ].
        ].

        "Check for hostiles breaching the zone"
        hostiles do: [:hd |
            (hd status = #hostile and: [
                hd position latitude < 48.83
            ]) ifTrue: [
                zoneBreaches := zoneBreaches + 1.
                hd status: #breached.
            ].
        ].

        "Check for drones lost (energy depleted)"
        alliedDrones do: [:ad |
            (ad status = #active and: [ad energy <= 0]) ifTrue: [
                ad status: #lost.
                dronesLost := dronesLost + 1.
            ].
        ].

        "Simulate energy consumption"
        alliedDrones do: [:ad | ad energy: ad energy - 2 ].
        hostiles do: [:hd | hd energy: hd energy - 3 ].

        simulator step.
    ].

    "Store metrics"
    metrics at: #interceptedHostiles put: interceptedHostiles.
    metrics at: #ammoSpent put: ammoSpent.
    metrics at: #dronesLost put: dronesLost.
    metrics at: #zoneBreaches put: zoneBreaches.

    "Print metrics"
    Transcript show: 'Simulation complete. Metrics:'; cr.
    metrics keysAndValuesDo: [:k :v | Transcript show: k asString, ': ', v asString; cr ].
]
]

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleSecuring [
  
     | sim drones cluster mission polygon     |
    sim := SimulationState new initialize.
    sim setAsCurrent.
    drones := { Drone new. Drone new. Drone new } asOrderedCollection.
    (drones at: 1) moveToLatitude: 44.8566 longitude: 2.3522 altitude: 120.
    (drones at: 2) moveToLatitude: 48.8766 longitude: 2.3622 altitude: 120.
    (drones at: 3) moveToLatitude: 48.66 longitude: -2.3422 altitude: 120.
    cluster := DroneCluster new initializeWithDrones: drones clusterId: 2.
    sim addFleet: (DroneFleet new initializeWithClusters: { cluster } id: 2 hostile: false name: 'Green').
    polygon := { { 48.88. 2.34. 100 }. { 48.87. 2.37. 100 }. { 42.84. 2.36. 100 }. }.
    mission := SecurizationMission new  zoneParameters: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignToCluster: cluster.
"    view := DroneMapWithOWSView new initializeWithSimulation: sim centerLat: 48.8566 centerLon: 2.3522 zoom: 12.
    view open."
 
    ^ sim.
]

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleSimpleBlock [
	" self exampleSimpleBlock"

	| evt simulator polygon drones sim cluster1 mission fleet intervalMs running |
	intervalMs := 300. "ms entre steps"
	running := true.
	sim := SimulationState new.
	drones := { Drone exampleAngers } asOrderedCollection.

	cluster1 := DroneCluster new
		            initializeWithDrones: drones
		            clusterId: #Surveillance.


	fleet := DroneFleet new.

	fleet addCluster: cluster1.
	sim addFleet: fleet.

	polygon := {
		           { 48.3904. -4.4947. 100 }. "Brest"
		           { 50.6292. 3.0573. 100 }. "Lille"

		           { 43.2965. 5.3698. 100 }. "Marseille"
		           { 51.5074. -0.1276. 100 } "Londres" } collect: [ :a |
		           GeoPoint with: a ].

	mission := (SecurizationMission new polygon: polygon)
		           assignToCluster: cluster1.


	evt := MoveStepEvent
		       drone: drones first
		       wayPoint: (polygon at: 1)
		       speed: 20000 / 3600. "20km/h"
	evt timestamp: 1.
	"Date de l'evenement"
	simulator := DroneSimulator new.
	simulator model: sim.
	simulator timeStep: 1. " A verifier par rapport a intervalMs"

	simulator scheduleEvent: evt after: Set new.

	^ simulator
]

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleSimpleBlock2 [
	" self exampleSimpleBlock2"

	| evt simulator polygon drones sim cluster1 mission fleet intervalMs running |
	intervalMs := 300. "ms entre steps"
	running := true.
	sim := SimulationState new.
	drones := { Drone example   . Drone example  . Drone example  . Drone example } asOrderedCollection.

	cluster1 := DroneCluster new
		            initializeWithDrones: drones
		            clusterId: #Surveillance.


	fleet := DroneFleet new.

	fleet addCluster: cluster1.
	sim addFleet: fleet.

	polygon := {
		           { 48.3904. -4.4947. 100 }. "Brest"
		           { 50.6292. 3.0573. 100 }. "Lille"

		           { 43.2965. 5.3698. 100 }. "Marseille"
		           { 51.5074. -0.1276. 100 } "Londres" } collect: [ :a |
		           GeoPoint with: a ].

	mission := (SecurizationMission new polygon: polygon)
		           assignToCluster: cluster1.

	simulator := DroneSimulator new.
	simulator model: sim.
	simulator timeStep: 1. " A verifier par rapport a intervalMs"
	
1 to: 4 do:[:i| 	evt := MoveStepEvent
		       drone: (drones at: i)
		       wayPoint: (polygon at: i)
		       speed: 20000 / 3600. "20km/h"
 
evt timestamp:1.
	simulator scheduleEvent: evt after: Set new.].

	^ simulator
]

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleSimpleBlock2GUI [
	" self exampleSimpleBlock2GUI"

	| evt simulator polygon drones sim cluster1 mission fleet intervalMs running |
	intervalMs := 300. "ms entre steps"
	running := true.
	sim := SimulationState new.
	drones := { Drone example   . Drone example  . Drone example  . Drone example } asOrderedCollection.

	cluster1 := DroneCluster new
		            initializeWithDrones: drones
		            clusterId: #Surveillance.


	fleet := DroneFleet new.

	fleet addCluster: cluster1.
	sim addFleet: fleet.

	polygon := {
		           { 48.3904. -4.4947. 100 }. "Brest"
		           { 50.6292. 3.0573. 100 }. "Lille"

		           { 43.2965. 5.3698. 100 }. "Marseille"
		           { 51.5074. -0.1276. 100 } "Londres" } collect: [ :a |
		           GeoPoint with: a ].

	mission := (SecurizationMission new polygon: polygon)
		           assignToCluster: cluster1.

	simulator := DroneSimulator new.
	simulator model: sim.
	simulator timeStep: 1. " A verifier par rapport a intervalMs"
	
1 to: 4 do:[:i| 	evt := MoveStepEvent
		       drone: (drones at: i)
		       wayPoint: (polygon at: i)
		       speed: 20000 / 3600. "20km/h"
 
evt timestamp:1.
	simulator scheduleEvent: evt after: Set new.].
sim open.
      [1 to: 400 do: [ :i |
       UIManager default defer:[ sim step.
       
          " self model hasChanged. " 
        ].
        (Delay forMilliseconds: 50) wait.
    ].
] fork.
	^ simulator
]

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleSurveillance [
    | sim drones cluster mission polygon   |
    sim := SimulationState new initialize.
    sim setAsCurrent.
    drones := { Drone new. Drone new. Drone new } asOrderedCollection.
    (drones at: 1) moveToLatitude: 38.8566 longitude: 2.3522 altitude: 120.
    (drones at: 2) moveToLatitude: 48.8666 longitude: -2.3622 altitude: 120.
    (drones at: 3) moveToLatitude: 48.8466 longitude: -5.3422 altitude: 120.
    cluster := DroneCluster new initializeWithDrones: drones clusterId: 1.
    sim addFleet: (DroneFleet new initializeWithClusters: { cluster } id: 1 hostile: false name: 'Blue').
    polygon := { { 48.86. 2.34. 100 }. { 48.87. 2.36. 100 }. { 48.85. 2.37. 100 }. }.
    mission := ClusterMission new initializeWithType: #surveillance zoneParameters: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignToCluster: cluster.
  "  view := DroneMapWithOWSView new initializeWithSimulation: sim centerLat: 48.8566 centerLon: 2.3522 zoom: 12.
    view open."
    ^ sim.

]

{ #category : 'as yet unclassified' }
DroneScenarios class >> techPoint [
   | wms operations getmap layers size map |

"Create a WMS client targeting the IGN WMS server"
wms := OWSServiceWMS new.
wms url: 'https://data.geopf.fr/wms-r'.

"Introspect the server capabilities"
operations := wms operations.
"
# 'operations' is a XMLOrderedList(
#   a OWSServiceWMSOperation <GetCapabilities>
#   a OWSServiceWMSOperation <GetMap>
#   a OWSServiceWMSOperation <GetFeatureInfo>
# )
"
"Listing available image formats for maps"
getmap := operations detect: [ :request | request name = 'GetMap' ].
getmap formats.

"# 'formats' is an OrderedCollection(
#   image/jpeg
#   image/png
#   image/tiff
#   image/geotiff
#   image/x-bil;bits=32
# )"

"Listing available layers"
layers := wms layers.

"# 'layers' is a XMLOrderedList(
#   a OWSServiceWMSLayer(ADMINEXPRESS-COG-CARTO.LATEST)
#   a OWSServiceWMSLayer(ADMINEXPRESS-COG.2017)
#   [...]
# )
"
"Download a raster map with two layers for a bounding box 
    defined by EPSG:3857 coordinates"
map := wms
  map: { 'EL.GridCoverage'. 'FORETS.PUBLIQUES' }
  bbox: (-546079 @ 6126282 corner: -398839 @ 6212047)
  size: 800 @ 600
  epsg: '3857'
  format: 'image/png'.
"
# 'map' is a Bitmap"
]
