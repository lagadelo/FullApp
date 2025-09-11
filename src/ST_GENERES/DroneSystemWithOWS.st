"=========================================================="
"  DRONE SYSTEM WITH OWS INTEGRATION (PHARO 13 + ROASSAL3) "
"=========================================================="

"--- Traits de base ---"

Trait named: #TIdentifiable
    uses: {}
    category: 'Drones-Core'.

TIdentifiable>>initializeId
    uniqueId := UUID new asString.

TIdentifiable>>id
    ^ uniqueId.


Trait named: #TPositionable
    uses: {}
    category: 'Drones-Core'.

TPositionable>>latitude
    ^ latitude.

TPositionable>>longitude
    ^ longitude.

TPositionable>>altitude
    ^ altitude.

TPositionable>>moveToLat: lat lon: lon alt: alt
    latitude := lat.
    longitude := lon.
    altitude := alt.


Trait named: #TConsumableCarrier
    uses: {}
    category: 'Drones-Core'.

TConsumableCarrier>>initializeConsumables
    consumables := Dictionary new.

TConsumableCarrier>>addConsumable: name qty: q
    consumables at: name put: ((consumables at: name ifAbsent: [ 0 ]) + q).

TConsumableCarrier>>consume: name qty: q
    | available |
    available := consumables at: name ifAbsent: [ 0 ].
    available >= q
        ifTrue: [ consumables at: name put: available - q. ^ true ].
    ^ false.


Trait named: #TDamageable
    uses: {}
    category: 'Drones-Core'.

TDamageable>>applyDamage: dmg
    fuel := (fuel - dmg) max: 0.
    speed := (speed - (dmg / 10)) max: 0.
    perceptionRange := (perceptionRange - (dmg / 20)) max: 0.

TDamageable>>isDestroyed
    ^ fuel = 0 or: [ speed = 0 ].


Trait named: #TRealTimeUpdate
    uses: {}
    category: 'Drones-Visualization'.

TRealTimeUpdate>>startUpdatingEvery: ms
    updateProcess ifNotNil: [ updateProcess terminate ].
    updateProcess := [
        [ true ] whileTrue: [
            self refreshView.
            (Delay forMilliseconds: ms) wait.
        ].
    ] forkAt: Processor userBackgroundPriority.

TRealTimeUpdate>>stopUpdating
    updateProcess ifNotNil: [ updateProcess terminate. updateProcess := nil ].

"--- Classe Drone ---"

Object subclass: #Drone
    uses: { TIdentifiable . TPositionable . TConsumableCarrier . TDamageable }
    instanceVariableNames: 'fuel speed perceptionRange behavior currentMission needsHelp detectedEnemy type'
    classVariableNames: ''
    package: 'Drones-Core'.

Drone>>initialize
    self initializeId.
    latitude := 48.8566. "Paris par défaut"
    longitude := 2.3522.
    altitude := 0.
    fuel := 100.
    self initializeConsumables.
    speed := 10.
    perceptionRange := 50.
    behavior := nil.
    currentMission := nil.
    needsHelp := false.
    detectedEnemy := false.
    type := 'standard'.

Drone>>executeStepAt: time
    behavior ifNotNil: [ behavior executeFor: self atTime: time ].

Drone>>setBehavior: aBehavior
    behavior := aBehavior.

Drone>>statusMessage
    ^ Dictionary new
        at: #id put: self id;
        at: #pos put: { latitude . longitude . altitude };
        at: #fuel put: fuel;
        at: #destroyed put: self isDestroyed;
        yourself.

Drone>>fuel
    ^ fuel.

"--- Comportements ---"

Object subclass: #DroneBehavior
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Behaviors'.

DroneBehavior>>executeFor: aDrone atTime: t
    self subclassResponsibility.

DroneBehavior subclass: #PatrolBehavior
    instanceVariableNames: 'waypoints currentIndex'
    classVariableNames: ''
    package: 'Drones-Behaviors'.

PatrolBehavior>>initializeWithWaypoints: pts
    waypoints := pts.
    currentIndex := 1.

PatrolBehavior>>executeFor: d atTime: t
    | wp |
    wp := waypoints at: currentIndex.
    d moveToLat: (wp at: 1) lon: (wp at: 2) alt: (wp at: 3).
    currentIndex := (currentIndex \\ waypoints size) + 1.

DroneBehavior subclass: #StaticPositionBehavior
    instanceVariableNames: 'lat lon alt'
    classVariableNames: ''
    package: 'Drones-Behaviors'.

StaticPositionBehavior>>initializeAtLat: a lon: b alt: c
    lat := a. lon := b. alt := c.

StaticPositionBehavior>>executeFor: d atTime: t
    d moveToLat: lat lon: lon alt: alt.

"--- Cluster ---"

Object subclass: #DroneCluster
    instanceVariableNames: 'drones clusterId coverage capabilities currentMission'
    classVariableNames: ''
    package: 'Drones-Core'.

DroneCluster>>initializeWith: ds id: cid
    drones := ds.
    clusterId := cid.
    currentMission := nil.
    self updateCapabilities.
    self updateCoverage.

DroneCluster>>updateCapabilities
    capabilities := Dictionary new.
    capabilities at: #fuel put: (drones sum: [:d | d isDestroyed ifFalse: [d fuel] ifTrue: [0]]).

DroneCluster>>updateCoverage
    coverage := drones collect: [:d | { d latitude. d longitude } ].

DroneCluster>>drones
    ^ drones.

DroneCluster>>clusterId
    ^ clusterId.

DroneCluster>>capabilities
    ^ capabilities.

DroneCluster>>coverage
    ^ coverage.

"--- Mission ---"

Object subclass: #ClusterMission
    instanceVariableNames: 'missionType zoneParameters'
    classVariableNames: ''
    package: 'Drones-Core'.

ClusterMission>>initializeWithType: t params: p
    missionType := t.
    zoneParameters := p.

ClusterMission>>assignTo: c
    c currentMission: self.
    (missionType = #surveillance) ifTrue: [ self assignSurveillance: c ].
    (missionType = #securisation) ifTrue: [ self assignSecuring: c ].

ClusterMission>>assignSurveillance: c
    | polygon n |
    polygon := zoneParameters at: #polygon.
    n := c drones size.
    c drones withIndexDo: [:d :i |
        d setBehavior: (PatrolBehavior new initializeWithWaypoints: { polygon at: i }).
    ].

ClusterMission>>assignSecuring: c
    | polygon n |
    polygon := zoneParameters at: #polygon.
    n := c drones size.
    c drones withIndexDo: [:d :i |
        | pt |
        pt := polygon at: i.
        d setBehavior: (StaticPositionBehavior new initializeAtLat: (pt at: 1) lon: (pt at: 2) alt: (pt at: 3)).
    ].

"--- Simulation ---"

Object subclass: #SimulationState
    instanceVariableNames: 'drones clusters time'
    classVariableNames: ''
    package: 'Drones-Core'.

SimulationState>>initialize
    drones := OrderedCollection new.
    clusters := OrderedCollection new.
    time := 0.

SimulationState>>addDrone: d
    drones add: d.

SimulationState>>addCluster: c
    clusters add: c.

SimulationState>>step
    drones do: [:d | d executeStepAt: time ].
    clusters do: [:c | c updateCapabilities; updateCoverage ].
    time := time + 1.

SimulationState>>drones
    ^ drones.

SimulationState>>clusters
    ^ clusters.

SimulationState>>time
    ^ time.

"--- Visualisation Roassal + OWS ---"

Object subclass: #DroneMapWithOWSView
    instanceVariableNames: 'simulation rsCanvas owsMap viewTrait centerLat centerLon zoom'
    classVariableNames: ''
    package: 'Drones-Visualization'.

DroneMapWithOWSView>>initializeWithSimulation: s centerLat: lat centerLon: lon zoom: z
    simulation := s.
    centerLat := lat.
    centerLon := lon.
    zoom := z.
    rsCanvas := RSCanvas new.
    self tryInitializeOWSMap.
    self traitInitialize.

DroneMapWithOWSView>>tryInitializeOWSMap
    "Essaie de trouver la classe OWSMapView (PharoOWS)"
    owsMap := (Smalltalk at: #OWSMapView ifAbsent: [ nil ]) ifNotNil: [ :cls |
        cls new
            center: centerLat@centerLon;
            zoom: zoom;
            yourself ].

DroneMapWithOWSView>>traitInitialize
    viewTrait := TDroneVisualizationWithOWS new.
    viewTrait simulation: simulation.
    viewTrait canvas: rsCanvas.
    viewTrait owsMap: owsMap.
    viewTrait initializeHUD.

DroneMapWithOWSView>>open
    owsMap ifNotNil: [ owsMap open ].
    rsCanvas open.
    viewTrait startUpdatingEvery: 500.

"--- Trait de visualisation ---"

Trait named: #TDroneVisualizationWithOWS
    uses: { TRealTimeUpdate }
    category: 'Drones-Visualization'.

TDroneVisualizationWithOWS>>simulation: s
    simulation := s.

TDroneVisualizationWithOWS>>canvas: c
    canvas := c.

TDroneVisualizationWithOWS>>owsMap: m
    owsMap := m.

TDroneVisualizationWithOWS>>initializeHUD
    timeLabel := RSLabel new text: 't=0s'.

TDroneVisualizationWithOWS>>refreshView
    self updateCanvasWith: simulation.
    timeLabel string: 't=', simulation time asString, 's'.

TDroneVisualizationWithOWS>>updateCanvasWith: s
    canvas clear.
    s drones do: [:d |
        | pos node |
        pos := self projectLat: d latitude lon: d longitude.
        node := RSShapeBuilder circle size: 10 color: Color blue on: canvas.
        node translateTo: pos.
    ].
    canvas signalUpdate.

TDroneVisualizationWithOWS>>projectLat: lat lon: lon
    (owsMap notNil and: [ owsMap respondsTo: #worldToScreen: ]) ifTrue: [
        ^ owsMap worldToScreen: lat@lon
    ].
    | cx cy scale x y |
    cx := centerLon ifNil: [ 0 ].
    cy := centerLat ifNil: [ 0 ].
    scale := 10000.
    x := (lon - cx) * scale.
    y := ((lat - cy) * scale) negated.
    ^ x@y.

"=========================================================="
"                FIN DU FICHIER .st                        "
"=========================================================="
