Class {
	#name : 'ScenarioSimulator',
	#superclass : 'Object',
	#instVars : [
		'simulationState',
		'results'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'examples' }
ScenarioSimulator class >> example10 [ 

| simState simulator mission polygon fleet drones cluster1 cluster2
  workPoint tStep enemy enemyPath initialTime   |

"--- 1.  initialisation existant   ---"
simState := SimulationState new.

drones := {
    (Drone new moveToLatitude: 48.8566 longitude: 2.3522 altitude: 100) beAlly ; yourself.   "Paris"
    (Drone new moveToLatitude: 44.8378 longitude: -0.5792 altitude: 120) beAlly ; yourself. "Bordeaux"
    (Drone new moveToLatitude: 45.7640 longitude: 4.8357 altitude: 100) beAlly; yourself. "Lyon"
    (Drone new moveToLatitude: 40.7640 longitude: 2 altitude: 100) beHostile; yourself. "?"
} asOrderedCollection.

cluster1 := DroneCluster new initializeWithDrones: drones clusterId: 1.
cluster2 := DroneCluster example: 20.

fleet := DroneFleet new.
fleet addCluster: cluster1.
fleet addCluster: cluster2.
simState addFleet: fleet.

polygon := {
    {50.6292 . 3.0573  . 100}. "Lille"
    {48.3904 . -4.4947 . 100}. "Brest"
    {43.2965 . 5.3698 . 100}. "Marseille"
    {51.5074 . -0.1276   . 100}. "Londres"
} collect: [:a | GeoPoint with: a ].

mission := (SecurizationMission new polygon: polygon) assignToCluster: cluster1.
"mission connaît les waypoints, cluster1 mission: mission"

"--- 2. Créer le simulateur et configurer la granularité temporelle ---"
"J'utilise ici DroneSimulator qui manipule la file d'événements et un timeStep."
simulator := DroneSimulator new initializeWithState: simState.
simulator timeStep: 1. "1 unité de temps par step (ajuste si besoin)"

"--- 3. Choisir le point de travail : centroïde du polygone (workPoint) ---"
workPoint := "(mission waypoints inject: (0@0) into: [:acc :pt |
    acc + (pt asPoint)]) / (mission waypoints size)." mission polygon first.
"Si tes waypoints sont GeoPoint, adapte: workPoint := mission waypoints collect: [ :wp | wp asPoint ] etc."

"--- 4. Planifier pour chaque drone un MoveStepEvent vers workPoint ---"
initialTime := "simulator now"0. "probablement 0"

cluster1 drones do: [:drone |
    | ev |
   
     
    "Optionnel : définir perceptionRange si non défini"
    drone perceptionRange: (drone perceptionRange ifNil: [ 5.0 ]).

    ev := MoveStepEvent new
        timestamp: initialTime;
        drone: drone;
        wayPoint: workPoint;
        speed: (drone speed ifNil: [ 5.0 ]);
        yourself.

    simulator scheduleEvent: ev after: (Set with: mission).
].

"--- 5. Insérer un drone ennemi (hostile) qui traverse la zone ---"
"On crée un ennemi (hostile) et on lui donne une trajectoire qui croisera le polygone"
enemy := (Drone new moveToLatitude: 49.0 longitude: 0.0 altitude: 100) beHostile; yourself.
"ne pas l'ajouter au cluster allié ; il est 'intruder' dans le modèle"
 

fleet addCluster: (DroneCluster new initializeWithDrones: {enemy} clusterId: #Intruder).

"Définir un chemin de traversée (quelques points) — traversée en 1..n steps"
enemyPath := OrderedCollection with: (GeoPoint with: {52.0 . -1.0 . 100})
                              with: (GeoPoint with: {50.0 . 1.0 . 100})
                              with: (GeoPoint with: {48.0 . 2.5 . 100})
                              with: (GeoPoint with: {46.0 . 4.0 . 100}).

"Planifier un MoveStepEvent pour chaque segment de l'ennemi, en commençant à t = 2"
tStep := 2.
enemyPath withIndexDo: [:pt :i |
    | mev |
    mev := MoveStepEvent new
        timestamp: (initialTime + (i * tStep));
        drone: enemy;
        wayPoint: pt  ; "ou pt si GeoPoint compatible"
        speed: 6; "speed de l'ennemi"
        yourself.
    simulator scheduleEvent: mev after: (Set with: nil). "pas de dépendance explicitée"
].

"--- 6. Exécuter la simulation pas à pas et afficher les événements ---"
"On exécute jusqu'à un temps max (ici t = 40) ou jusqu'à vidage de la queue"
[ simulator hasEvents and: [ simulator currentTime <= 40 ] ] whileTrue: [
    simulator step.
    (Delay forMilliseconds: 10) wait. "optionnel, si tu veux voir le Transcript défiler"
].

"--- 7. Après exécution : affichage sommaire ---"
Transcript show: 'Simulation finished at t=', simulator currentTime printString; cr.
simState drones do: [:d | Transcript show: d id printString, ' pos: ', d position printString; cr ].

]

{ #category : 'examples' }
ScenarioSimulator class >> exampleClasses [ 
| simulator polygon target ratios outcome |
simulator := ScenarioSimulator new.

polygon := {
    #(48.85 2.35 200).
    #(48.87 2.36 200).
    #(48.86 2.34 200) } collect:[:a|GeoPoint with: a]..

target := #(48.90 2.31 50).
ratios := #(0.2 0.5 0.8).

outcome := simulator runMixedMissionWithRatios: ratios polygon: polygon target: target.

Transcript show: outcome; cr.
]

{ #category : 'examples' }
ScenarioSimulator class >> exampleSurveillance [
      | sim     mission polygon     fleet drones cluster1 cluster2 |

    sim := SimulationState new.

    drones := {
        (Drone new moveToLatitude: 48.8566 longitude: 2.3522 altitude: 100) beHostile; yourself.   "Paris"
        (Drone new moveToLatitude: 44.8378 longitude: -0.5792 altitude: 120)beHostile; yourself.   "Bordeaux"
        (Drone new moveToLatitude: 45.7640 longitude: 4.8357 altitude: 100)beHostile; yourself. "Lyon"
    (Drone new moveToLatitude: 40.7640 longitude: 2 altitude: 100)beHostile; yourself. "?"
    } asOrderedCollection.

  
    cluster1 := DroneCluster new initializeWithDrones:  drones clusterId: 1.
cluster2 := DroneCluster example:20.
 

    fleet := DroneFleet new.
fleet addCluster: cluster1.
fleet addCluster: cluster2.
sim addFleet: fleet.
 
    polygon := {
        { 50.6292 . 3.0573  . 100 }. "Lille"
        {48.3904 . -4.4947 . 100 }. "Brest"
        { 43.2965 . 5.3698 . 100 }. "Marseille"
        {51.5074 .-0.1276   . 100 } "Londres"
    } collect:[:a|GeoPoint with: a].

    mission := (SecurizationMission new  polygon: polygon) assignToCluster: cluster1.
    "Crée une mission de surveillance sur un polygone et l’assigne immédiatement au cluster."
    
   
^sim 
"    view := DroneMapWithOWSView new
        initializeWithSimulation: sim
        centerLat: 48.85
        centerLon: 2.35
        zoom: 12.

    view open."

]

{ #category : 'executing' }
ScenarioSimulator >> execute [
    self subclassResponsibility.

]

{ #category : 'initialization' }
ScenarioSimulator >> exportResults: results toCSVFile: filePath [
    "results is a collection of Dictionaries with keys #ratio #alliesRemaining #hostilesRemaining #coverageSize"
    | stream |
    stream := FileStream fileNamed: filePath.
    stream nextPutAll: 'ratio,alliesRemaining,hostilesRemaining,coverageSize'; nl.
    results do: [:r |
        | ratio allies hostiles cov |
        ratio := (r at: #ratio) asString.
        allies := (r at: #alliesRemaining) asString.
        hostiles := (r at: #hostilesRemaining) asString.
        cov := (r at: #coverageSize ifAbsent: [ (r at: #coverage ifAbsent: [ '' ]) size asString ]).
        stream nextPutAll: ratio, ',', allies, ',', hostiles, ',', cov; nl.
    ].
    stream close.
    ^ filePath.
]

{ #category : 'initialization' }
ScenarioSimulator >> exportResultsToCSVFile: aFilePath [
    | rows stream |
    rows := self results ifNil: [ ^ self error: 'No results to export' ].
    stream := FileStream fileNamed: aFilePath.
    stream nextPutAll: 'ratio,alliesRemaining,hostilesRemaining,coverageSize'; nl.
    rows do: [:r |
        stream nextPutAll: (String streamContents: [:s |
            s nextPutAll: (r at: #ratio) asString, ','.
            s nextPutAll: (r at: #alliesRemaining) asString, ','.
            s nextPutAll: (r at: #hostilesRemaining) asString, ','.
            s nextPutAll: (r at: #coverageSize ifAbsent: [ (r at: #coverage ifAbsent: [ #() ]) size ]) asString ]).
        stream cr ].
    stream close.
    ^ aFilePath.
]

{ #category : 'initialization' }
ScenarioSimulator >> generateDrones: n prefix: prefix [
    ^ (1 to: n) collect: [:i |
        Drone new
            initializeWithId: (prefix , i asString)
            latitude: 48.85 + (0.01 * i)
            longitude: 2.35 + (0.01 * i)
            altitude: 200
    ].
]

{ #category : 'initialization' }
ScenarioSimulator >> initialize [
"    simulationState := SimulationState new."
    results := OrderedCollection new.
    ^ self.
]

{ #category : 'accessing' }
ScenarioSimulator >> results [

	^ results
]

{ #category : 'accessing' }
ScenarioSimulator >> results: anObject [

	results := anObject
]

{ #category : 'accessing' }
ScenarioSimulator >> rsCircleForDrone: d [
    ^ self rsCircleForDrone: d color: nil.
]

{ #category : 'accessing' }
ScenarioSimulator >> rsCircleForDrone: d color: aColor [
    | x y circle |
    x := d longitude.
    y := d latitude.
    circle := RSEllipse new.
    circle size: 6@6.
    circle translateTo: (x@y).
    aColor ifNotNil: [ circle color: aColor ] ifNil: [ circle color: (d isHostile ifTrue: [ Color red ] ifFalse: [ Color green ]) ].
    circle tooltip: (d uniqueId , ' fuel=' , d fuel asString).
    ^ circle.

]

{ #category : 'initialization' }
ScenarioSimulator >> runMixedMissionWithRatios: ratios polygon: polygon target: target [
     | allyCluster hostileCluster |
self setupBasicScenario.

    ratios do: [:r |
        | mission stateCopy result |
        stateCopy := simulationState deepCopy. "Cloner l’état initial"
        allyCluster := stateCopy allFleets first alliedClusters first..  "récupérer le cluster allié"
        
        mission := ClusterMission
            mixedOn: polygon
            target: target
            ratio: r
            forCluster: allyCluster.
        
        stateCopy runSimulationSteps: 100.
        
        result := Dictionary newFrom: {
            #ratio -> r .
            #alliesRemaining -> (allyCluster drones count: [:d | d isDestroyed not]).
            #hostilesRemaining -> (hostileCluster drones count: [:d | d isDestroyed not]).
            #coverage -> allyCluster coverage }.
        
        results add: result.
    ].

    ^ results.
]

{ #category : 'initialization' }
ScenarioSimulator >> setupBasicScenario [
    "Créer deux flottes : une alliée, une hostile, avec quelques drones"
    
    
    | allyCluster hostileCluster f |

simulationState := SimulationState new. 
allyCluster := DroneCluster new
        initializeWithDrones: (self generateDrones: 10 prefix: 'A')
        clusterId: 1
        hostile: false
        name: 'Allies'.
    
    hostileCluster := DroneCluster new
        initializeWithDrones: (self generateDrones: 8 prefix: 'H')
        clusterId: 2
        hostile: true
        name: 'Hostiles'.
    
	f := DroneFleet new.
	f addCluster:allyCluster.
	f addHostileCluster: hostileCluster.
	simulationState addFleet: f.
 ^ Array with: allyCluster with: hostileCluster .
]

{ #category : 'accessing' }
ScenarioSimulator >> simulationState [

	^ simulationState
]

{ #category : 'accessing' }
ScenarioSimulator >> simulationState: anObject [

	simulationState := anObject
]

{ #category : 'user-interface' }
ScenarioSimulator >> visualizeSimulationOnMap: aState title: aString [
    | canvas group drones latMin latMax lonMin lonMax scaleX scaleY toPoint background |
    canvas := RSCanvas new.

    drones := (aState respondsTo: #drones)
        ifTrue: [ aState drones ]
        ifFalse: [ aState allDrones ].

    "Déterminer bounding box"
    latMin := (drones collect: #latitude) min.
    latMax := (drones collect: #latitude) max.
    lonMin := (drones collect: #longitude) min.
    lonMax := (drones collect: #longitude) max.

    scaleX := 800.   "largeur carte"
    scaleY := 600.   "hauteur carte"

    toPoint := [ :lat :lon |
        ((lon - lonMin) / (lonMax - lonMin + 0.0001) * scaleX) @
        ((latMax - lat) / (latMax - latMin + 0.0001) * scaleY) ].

    "Fond simple"
    background := RSBox new
        size: scaleX@scaleY;
        color: Color veryLightGray;
        yourself.
    canvas add: background.

    "Placer les drones"
    drones do: [:d |
        | c pt |
        pt := toPoint value: d latitude value: d longitude.
        c := RSEllipse new
            size: 8@8;
            translateTo: pt;
            color: (d isHostile ifTrue: [ Color red ] ifFalse: [ Color green ]);
            tooltip: d uniqueId.
        canvas add: c ].

    "Titre et interaction"
    canvas title: (aString ifNil: [ 'Drone Map' ]).
    (canvas shapes) as: RSGroup @ RSDraggable.
    canvas @ RSCanvasController.
    canvas open.

]

{ #category : 'user-interface' }
ScenarioSimulator >> visualizeSimulationOnMapWithOSM: aState title: aString [
    | mapMorph drones polygon coverage polygonOverlay coverageOverlay |

    "Créer la carte centrée sur l’Europe"
    mapMorph := OWSMapMorph new.
    mapMorph extent: 900@700.
    mapMorph center: (OWSLatLon latitude: 48.85 longitude: 2.35).
    mapMorph zoom: 8.

    drones := (aState respondsTo: #drones)
        ifTrue: [ aState drones ]
        ifFalse: [ aState allDrones ].

    "Ajouter les drones comme marqueurs interactifs"
    drones do: [:d |
        | marker color info |
        color := d isHostile
            ifTrue: [ Color red ]
            ifFalse: [ Color green ].

        info := String streamContents: [:s |
            s nextPutAll: 'ID: '; nextPutAll: d uniqueId; cr.
            s nextPutAll: 'Lat: '; nextPutAll: d latitude asString; cr.
            s nextPutAll: 'Lon: '; nextPutAll: d longitude asString; cr.
            s nextPutAll: 'Alt: '; nextPutAll: d altitude asString; cr.
            s nextPutAll: 'Energy: '; nextPutAll: d energy asString; cr.
            s nextPutAll: 'Status: '; nextPutAll: (d isDestroyed ifTrue: [ 'Destroyed' ] ifFalse: [ 'Active' ]) ].

        marker := OWSMarker new
            position: (OWSLatLon latitude: d latitude longitude: d longitude);
            label: d uniqueId;
            color: color;
            onClick: [ UIManager default inform: info ];
            yourself.

        mapMorph addMarker: marker
    ].

    "Ajouter la zone de mission si elle existe"
    (aState respondsTo: #fleets) ifTrue: [
        aState fleets do: [:fleet |
            fleet currentMission ifNotNil: [:mission |
                (mission zoneParameters includesKey: #polygon) ifTrue: [
                    polygon := mission zoneParameters at: #polygon.
                    polygonOverlay := OWSPolygon new.
                    polygon do: [:pt |
                        polygonOverlay addPoint: (OWSLatLon latitude: (pt at: 1) longitude: (pt at: 2)) ].
                    polygonOverlay color: (Color blue alpha: 0.2).
                    polygonOverlay borderColor: Color blue.
                    mapMorph addOverlay: polygonOverlay.
                ].
            ].
        ].
    ].

    "Ajouter la couverture (convex hull)"
    (aState respondsTo: #fleets) ifTrue: [
        aState fleets do: [:fleet |
            fleet coverage ifNotNil: [:cov |
                (cov isEmpty) ifFalse: [
                    coverageOverlay := OWSPolygon new.
                    cov do: [:pt |
                        coverageOverlay addPoint: (OWSLatLon latitude: (pt at: 1) longitude: (pt at: 2)) ].
                    coverageOverlay color: (Color green alpha: 0.15).
                    coverageOverlay borderColor: Color darkGreen.
                    mapMorph addOverlay: coverageOverlay.
                ].
            ].
        ].
    ].

    mapMorph openInWindowLabeled: (aString ifNil: [ 'Drone OSM Map' ]).

]

{ #category : 'initialization' }
ScenarioSimulator >> visualizeSimulationState: aState title: aString [
    "Affiche positions drones + coverage polygons pour l'état fourni (DroneSimulation or SimulationState)"
    | canvas group shapes clusters shapesByCluster title|
    (Smalltalk at: #RSCanvas) ifNil: [ 
        self error: 'Roassal3 not loaded. Load Roassal3 before calling visualizeSimulationState:' ].

    canvas := RSCanvas new.
    shapesByCluster := Dictionary new.

    "Collecter clusters or fallback to top-level drones"
    clusters := (aState respondsTo: #fleets) ifTrue: [ aState fleets ] ifFalse: [ 
        (aState respondsTo: #clusters) ifTrue: [ aState clusters ] ifFalse: [ #() ] ].

    (clusters isEmpty) ifTrue: [
        "No clusters — draw drones from state.drones"
        (aState respondsTo: #drones) ifTrue: [
            aState drones do: [:d |
                | c |
                c := self rsCircleForDrone: d.
                canvas add: c ] ].
    ] ifFalse: [
        clusters do: [:cluster |
            | clusterShapes color |
            color := (cluster respondsTo: #isHostile and: [ cluster isHostile ]) ifTrue: [ Color red ] ifFalse: [ Color green ].
            "draw drones"
            cluster drones do: [:d |
                | s |
                s := self rsCircleForDrone: d color: color.
                canvas add: s.
                (shapesByCluster at: cluster ifAbsentPut: [ OrderedCollection new ]) add: s ].
            "draw coverage polygon if present"
            (cluster coverage notNil and: [ cluster coverage notEmpty ]) ifTrue: [
                | pts edges |
                pts := cluster coverage.
                "create edges between consecutive hull points and close polygon"
                edges := OrderedCollection new.
                1 to: (pts size) do: [:i |
                    | p1 p2 line |
                    p1 := pts at: i.
                    p2 := (i < pts size) ifTrue: [ pts at: i + 1 ] ifFalse: [ pts at: 1 ].
                    line := RSLine new from: ((p1 at: 2) @ (p1 at: 1)) to: ((p2 at: 2) @ (p2 at: 1)).
                    line color: Color gray; dashed.
                    canvas add: line.
                    edges add: line ].
            ]] ].

    "Layout & controller"
    group := (canvas shapes) as: RSGroup.
    RSGridLayout on: group.
    group @ RSDraggable.
    canvas @ RSCanvasController.

    aString ifNil:  [ title := 'Simulation View' ]ifNotNil:[title := aString] .
    canvas title: title.
    canvas open.
    ^ canvas
]
