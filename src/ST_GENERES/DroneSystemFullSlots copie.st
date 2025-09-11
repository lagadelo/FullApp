"DroneSystemFullSlots.st"

"=========================================================="
"  DRONE SYSTEM FULL - All in one (Pharo 13 .slots style)   "
"  - Roassal3 visualization + optional PharoOWS overlay     "
"  - Multi-fleet, hostile drones, behaviors, strategies     "
"  - Strategy evaluator, CSV export, Roassal charts         "
"=========================================================="

"-----------------------------"
" Helper: STFileIn (programmatic file-in)"
"-----------------------------"
Object << #STFileIn
    slots: { #dummy }
    package: 'DroneSystem-Utils'.

STFileIn class >> fileInSt: aPath
    (FileStream readOnlyFileNamed: aPath) do: [:stream |
        Compiler evaluate: stream contents
    ].

STFileIn class >> fileInAll: aCollectionOfPaths
    aCollectionOfPaths do: [:p | self fileInSt: p ].

"-----------------------------"
" Traits (kept as traits)"
"-----------------------------"
Trait named: #TRealTimeUpdate
    uses: {}
    category: 'DroneSystem-Traits'.

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

"-----------------------------"
" Core domain objects (slots notation)"
"-----------------------------"

Object << #Drone
    slots: { #latitude . #longitude . #altitude . #fuel . #consumables . #speed . #perceptionRange . #behavior . #uniqueId . #type . #currentMission . #needsHelp . #detectedEnemy }
    package: 'DroneSystem-Core'.

"Constructor and basic accessors"
Drone>>initialize
    uniqueId := UUID new asString.
    latitude := 48.8566. "default Paris"
    longitude := 2.3522.
    altitude := 100.
    fuel := 100.
    consumables := Dictionary new.
    speed := 10.
    perceptionRange := 50.
    behavior := nil.
    currentMission := nil.
    needsHelp := false.
    detectedEnemy := false.
    type := 'standard'.

Drone>>moveToLatitude: lat longitude: lon altitude: alt
    | distance fuelConsumed |
    distance := self distanceToLatitude: lat longitude: lon altitude: alt.
    fuelConsumed := distance * (speed / 10).
    (fuel >= fuelConsumed)
        ifTrue: [
            latitude := lat.
            longitude := lon.
            altitude := alt.
            fuel := fuel - fuelConsumed.
        ]
        ifFalse: [ needsHelp := true. Transcript show: 'Drone ', uniqueId, ' low fuel'; cr ].

Drone>>distanceToLatitude: lat longitude: lon altitude: alt
    ^ ((latitude - lat) squared + (longitude - lon) squared + (altitude - alt) squared) sqrt

Drone>>canPerceiveDrone: otherDrone
    ^ (self distanceToLatitude: otherDrone latitude longitude: otherDrone longitude altitude: otherDrone altitude) <= perceptionRange

Drone>>statusMessage
    ^ Dictionary new
        at: #id put: uniqueId;
        at: #position put: { latitude. longitude. altitude };
        at: #fuel put: fuel;
        at: #isDestroyed put: self isDestroyed;
        at: #needsHelp put: needsHelp;
        at: #detectedEnemy put: detectedEnemy;
        yourself.

Drone>>attackDrone: targetDrone withWeapon: weaponName quantity: qty probability: prob impact: impactValue
    (self canPerceiveDrone: targetDrone) ifFalse: [ ^'Cible hors de portée' ].
    | availableQty hits totalImpact |
    availableQty := consumables at: weaponName ifAbsent: [0].
    (availableQty >= qty)
        ifTrue: [
            consumables at: weaponName put: (availableQty - qty).
            hits := (1 to: qty) count: [:each | (Random new next <= prob)].
            totalImpact := hits * impactValue.
            targetDrone applyDamage: totalImpact.
            ^'Attaque effectuée: ', hits asString, ' coups au but, impact total: ', totalImpact asString
        ]
        ifFalse: [ ^'Pas assez de munitions disponibles' ].

"Note: applyDamage/isDestroyed implemented inline for slots style"
Drone>>applyDamage: damage
    fuel := (fuel - damage) max: 0.
    speed := (speed - (damage / 10)) max: 0.
    perceptionRange := (perceptionRange - (damage / 20)) max: 0.

Drone>>isDestroyed
    ^ fuel = 0 or: [ speed = 0 ]

"Getters/setters (slots provide direct accessors in Pharo but define a few helpers)"
Drone>>latitude ^ latitude.
Drone>>longitude ^ longitude.
Drone>>altitude ^ altitude.
Drone>>fuel ^ fuel.
Drone>>consumables ^ consumables.
Drone>>behavior ^ behavior.
Drone>>uniqueId ^ uniqueId.
Drone>>type ^ type.
Drone>>currentMission ^ currentMission.
Drone>>currentMission: aMission currentMission := aMission.
Drone>>needsHelp ^ needsHelp.
Drone>>needsHelp: aBool needsHelp := aBool.
Drone>>detectedEnemy ^ detectedEnemy.
Drone>>detectedEnemy: aBool detectedEnemy := aBool.
Drone>>speed ^ speed.
Drone>>perceptionRange ^ perceptionRange.
Drone>>setBehavior: b behavior := b.

"-----------------------------"
" Behaviors"
"-----------------------------"

Object << #DroneBehavior
    slots: {}
    package: 'DroneSystem-Behaviors'.

DroneBehavior>>executeFor: aDrone atTime: aTime
    self subclassResponsibility.

Object << #PatrolBehavior
    slots: { #waypoints . #currentIndex }
    package: 'DroneSystem-Behaviors'.

PatrolBehavior>>initializeWithWaypoints: aCollection
    waypoints := aCollection.
    currentIndex := 1.
    ^ self.

PatrolBehavior>>executeFor: aDrone atTime: aTime
    | nextWaypoint |
    waypoints isEmpty ifTrue: [ ^ self ].
    nextWaypoint := waypoints at: currentIndex.
    aDrone moveToLatitude: (nextWaypoint at: 1) longitude: (nextWaypoint at: 2) altitude: (nextWaypoint at: 3).
    currentIndex := (currentIndex \\ waypoints size) + 1.

Object << #StaticPositionBehavior
    slots: { #sLat . #sLon . #sAlt }
    package: 'DroneSystem-Behaviors'.

StaticPositionBehavior>>initializeWithLatitude: lat longitude: lon altitude: alt
    sLat := lat. sLon := lon. sAlt := alt. ^ self.

StaticPositionBehavior>>executeFor: aDrone atTime: aTime
    aDrone moveToLatitude: sLat longitude: sLon altitude: sAlt.

"Attack and aggressive behaviors for hostiles"
Object << #AttackBehavior
    slots: { #weaponName . #quantity . #probability . #impact . #targetSelector }
    package: 'DroneSystem-Behaviors'.

AttackBehavior>>initializeWithWeapon: w qty: q prob: p impact: i targetSelector: sel
    weaponName := w. quantity := q. probability := p. impact := i. targetSelector := sel. ^ self.

AttackBehavior>>executeFor: aDrone atTime: t
    | targets target |
    targets := targetSelector value: aDrone.
    targets isEmpty ifTrue: [ ^ self ].
    target := targets first.
    (aDrone canPerceiveDrone: target) ifFalse: [ ^ self ].
    | available hits totalImpact |
    available := aDrone consumables at: weaponName ifAbsent: [ 0 ].
    (available >= quantity) ifFalse: [ ^ self ].
    aDrone consumables at: weaponName put: (available - quantity).
    hits := (1 to: quantity) count: [:each | (Random new next) <= probability ].
    totalImpact := hits * impact.
    target applyDamage: totalImpact.
    Transcript show: 'Time ', t printString, ' - ', aDrone uniqueId, ' attacked ', target uniqueId, ' hits=', hits asString, ' impact=', totalImpact asString; cr.

Object << #AggressiveBehavior
    slots: {}
    package: 'DroneSystem-Behaviors'.

AggressiveBehavior>>executeFor: aDrone atTime: t
    | enemies nearest |
    SimulationState current ifNil: [ ^ self ].
    enemies := SimulationState current allAlliedDrones select: [:a | a isDestroyed not].
    enemies isEmpty ifTrue: [ ^ self ].
    nearest := enemies first.
    enemies do: [:e | ((aDrone distanceToLatitude: e latitude longitude: e longitude altitude: e altitude) < (aDrone distanceToLatitude: nearest latitude longitude: nearest longitude altitude: nearest altitude)) ifTrue: [ nearest := e ] ].
    aDrone moveToLatitude: ((aDrone latitude + nearest latitude) / 2) longitude: ((aDrone longitude + nearest longitude) / 2) altitude: ((aDrone altitude + nearest altitude) / 2).
    (aDrone canPerceiveDrone: nearest) ifTrue: [
        | impact hits |
        impact := 10.
        hits := (Random new next) <= 0.6 ifTrue: [ 1 ] ifFalse: [ 0 ].
        nearest applyDamage: hits * impact.
        Transcript show: 'Aggressive: ', aDrone uniqueId, ' attacked ', nearest uniqueId, ' hits=', hits asString; cr.
    ].

"-----------------------------"
" Convex hull utility "
"-----------------------------"

Object << #ConvexHullCalculator
    slots: {}
    package: 'DroneSystem-Utils'.

ConvexHullCalculator>>computeHullFrom: points
    | sorted hull |
    sorted := points sort: [:a :b | (a at: 1) < (b at: 1) ].
    hull := OrderedCollection new.
    sorted do: [:p | 
        [ hull size >= 2 and: [ self turn: (hull at: hull size - 1) to: (hull last) to: p ] <= 0 ] whileTrue: [ hull removeLast ].
        hull add: p.
    ].
    sorted reversed do: [:p | 
        [ hull size >= 2 and: [ self turn: (hull at: hull size - 1) to: (hull last) to: p ] <= 0 ] whileTrue: [ hull removeLast ].
        hull add: p.
    ].
    ^ hull asArray.

ConvexHullCalculator>>turn: a to: b to: c
    ^ ((b at: 1) - (a at: 1)) * ((c at: 2) - (a at: 2)) - ((b at: 2) - (a at: 2)) * ((c at: 1) - (a at: 1)).

"-----------------------------"
" Cluster and Missions "
"-----------------------------"

Object << #DroneCluster
    slots: { #drones . #clusterId . #coverage . #capabilities . #currentMission }
    package: 'DroneSystem-Core'.

DroneCluster>>initializeWithDrones: droneList clusterId: anId
    drones := droneList.
    clusterId := anId.
    self updateCapabilities.
    self updateCoverage.
    currentMission := nil.
    ^ self.

DroneCluster>>updateCapabilities
    capabilities := Dictionary new.
    capabilities at: #fuel put: (drones sum: [:d | d isDestroyed ifFalse: [d fuel] ifTrue: [0]]).
    capabilities at: #perceptionRange put: (drones collect: [:d | d isDestroyed ifFalse: [d perceptionRange] ifTrue: [0]]) max.
    capabilities at: #munitions put: (drones sum: [:d | d isDestroyed ifFalse: [ (d consumables values sum) ] ifTrue: [0]]).

DroneCluster>>updateCoverage
    | activePositions |
    activePositions := drones select: [:d | d isDestroyed not] collect: [:d | { d latitude. d longitude } ].
    coverage := (activePositions isEmpty ifTrue: [ #() ] ifFalse: [ ConvexHullCalculator new computeHullFrom: activePositions ]).
    ^ coverage.

DroneCluster>>removeDestroyedDrones
    drones := drones select: [:d | d isDestroyed not].
    self updateCapabilities.
    self updateCoverage.

DroneCluster>>isOperational
    ^ drones anySatisfy: [:d | d isDestroyed not].

DroneCluster>>clusterCenter
    | lats lons |
    coverage isNil ifTrue: [ ^ Point x: 0 y: 0 ].
    lats := coverage collect: [:p | p at: 1].
    lons := coverage collect: [:p | p at: 2].
    ^ Point x: (lons sum / lons size) y: (lats sum / lats size).

DroneCluster>>coverage ^ coverage.
DroneCluster>>capabilities ^ capabilities.
DroneCluster>>clusterId ^ clusterId.
DroneCluster>>drones ^ drones.
DroneCluster>>currentMission ^ currentMission.
DroneCluster>>currentMission: aMission currentMission := aMission.

Object << #ClusterMission
    slots: { #missionType . #zoneParameters }
    package: 'DroneSystem-Core'.

ClusterMission>>initializeWithType: aType zoneParameters: params
    missionType := aType.
    zoneParameters := params.
    ^ self.

ClusterMission>>assignToCluster: aCluster
    aCluster currentMission: self.
    (missionType = #surveillance) ifTrue: [ self assignSurveillanceBehaviorsTo: aCluster ].
    (missionType = #securisation) ifTrue: [ self assignSecuringBehaviorsTo: aCluster ].

ClusterMission>>assignSurveillanceBehaviorsTo: aCluster
    | segments |
    segments := self computeSurveillanceWaypointsFor: aCluster.
    aCluster drones withIndexDo: [:drone :i |
        drone setBehavior: (PatrolBehavior new initializeWithWaypoints: (segments at: i)).
    ].

ClusterMission>>assignSecuringBehaviorsTo: aCluster
    | positions |
    positions := self computeSecuringPositionsFor: aCluster.
    aCluster drones withIndexDo: [:drone :i |
        drone setBehavior: (StaticPositionBehavior new initializeWithLatitude: ((positions at: i) at: 1) longitude: ((positions at: i) at: 2) altitude: ((positions at: i) at: 3)).
    ].

ClusterMission>>computeSurveillanceWaypointsFor: aCluster
    | polygon n segments |
    polygon := zoneParameters at: #polygon.
    n := aCluster drones size.
    segments := (1 to: n) collect: [:i | { (polygon at: i) } ].
    ^ segments.

ClusterMission>>computeSecuringPositionsFor: aCluster
    | polygon n positions |
    polygon := zoneParameters at: #polygon.
    n := aCluster drones size.
    positions := (1 to: n) collect: [:i | polygon at: i ].
    ^ positions.

"-----------------------------"
" Simulation State "
"-----------------------------"

Object << #SimulationState
    slots: { #drones . #clusters . #missionHistory . #time . #eventLog . #reactionLog . #verificationFunctions . #allFleets }
    package: 'DroneSystem-Core'.

SimulationState>>initialize
    drones := OrderedCollection new.
    clusters := OrderedCollection new.
    missionHistory := OrderedCollection new.
    eventLog := OrderedCollection new.
    reactionLog := OrderedCollection new.
    verificationFunctions := OrderedCollection new.
    allFleets := OrderedCollection new.
    time := 0.
    ^ self.

SimulationState class >> current
    ^ Smalltalk at: #CurrentSimulation ifAbsent: [ nil ].

SimulationState>>setAsCurrent
    Smalltalk at: #CurrentSimulation put: self.

SimulationState>>addDrone: d
    drones add: d.

SimulationState>>addCluster: c
    clusters add: c.

SimulationState>>addFleet: aFleet
    allFleets add: aFleet.

SimulationState>>removeFleet: aFleet
    allFleets remove: aFleet ifAbsent: [ nil ].

SimulationState>>drones ^ drones.
SimulationState>>clusters ^ clusters.
SimulationState>>time ^ time.

SimulationState>>allHostileDrones
    | hostiles |
    hostiles := OrderedCollection new.
    allFleets do: [:f | f isHostile ifTrue: [ hostiles addAll: (f clusters collectMany: [:c | c drones ]) ] ].
    ^ hostiles.

SimulationState>>allAlliedDrones
    | allies |
    allies := OrderedCollection new.
    allFleets do: [:f | f isHostile ifFalse: [ allies addAll: (f clusters collectMany: [:c | c drones ]) ] ].
    ^ allies.

SimulationState>>step
    "Behaviors for standalone drones"
    drones do: [:d | d behavior ifNotNil: [ d behavior executeFor: d atTime: time ] ].
    "Behaviors and updates for fleets/clusters"
    allFleets do: [:fleet | fleet clusters do: [:cluster | cluster updateCapabilities. cluster updateCoverage. cluster drones do: [:d | d behavior ifNotNil: [ d behavior executeFor: d atTime: time ] ] ] ].
    "Resolve engagements"
    self resolveEngagements.
    time := time + 1.
    ^ self.

SimulationState>>resolveEngagements
    | hostiles allies |
    hostiles := self allHostileDrones select: [:h | h isDestroyed not].
    allies := self allAlliedDrones select: [:a | a isDestroyed not].
    hostiles do: [:h |
        | target |
        target := allies detect: [:a | (h canPerceiveDrone: a) ] ifNone: [ nil ].
        target ifNotNil: [
            | impact hits |
            impact := 8.
            hits := (Random new next) <= 0.7 ifTrue: [ 1 ] ifFalse: [ 0 ].
            target applyDamage: hits * impact.
            eventLog add: (String streamContents: [:s | s nextPutAll: 'Engagement: Hostile '; s nextPutAll: h uniqueId; s nextPutAll: ' attacked Allied '; s nextPutAll: target uniqueId; s nextPutAll: ' hits='; s nextPutAll: hits asString ]).
        ].
    ].
    allies do: [:a |
        | target |
        target := hostiles detect: [:h | (a canPerceiveDrone: h) ] ifNone: [ nil ].
        target ifNotNil: [
            | impact hits |
            impact := 6.
            hits := (Random new next) <= 0.5 ifTrue: [ 1 ] ifFalse: [ 0 ].
            target applyDamage: hits * impact.
            reactionLog add: (String streamContents: [:s | s nextPutAll: 'Retaliation: Allied '; s nextPutAll: a uniqueId; s nextPutAll: ' attacked Hostile '; s nextPutAll: target uniqueId; s nextPutAll: ' hits='; s nextPutAll: hits asString ]).
        ].
    ].
    ^ self.

"-----------------------------"
" Visualization: Roassal + optional PharoOWS"
"-----------------------------"

Object << #DroneMapWithOWSView
    slots: { #simulation . #owsMap . #rsCanvas . #trait . #centerLat . #centerLon . #zoom }
    package: 'DroneSystem-Visualization'.

DroneMapWithOWSView>>initializeWithSimulation: aSimulation centerLat: lat centerLon: lon zoom: z
    simulation := aSimulation.
    centerLat := lat.
    centerLon := lon.
    zoom := z.
    "Try to init PharoOWS if present"
    (Smalltalk includesKey: #OWSMapView) ifTrue: [
        owsMap := (Smalltalk at: #OWSMapView) new.
        (owsMap respondsTo: #center:) ifTrue: [ owsMap center: lat@lon ].
        (owsMap respondsTo: #zoom:) ifTrue: [ owsMap zoom: z ].
    ] ifFalse: [ owsMap := nil ].
    rsCanvas := RSCanvas new.
    rsCanvas extent: 1000@700.
    trait := (Smalltalk includesKey: #TDroneVisualizationWithOWS) ifTrue: [ (Smalltalk at: #TDroneVisualizationWithOWS) new ] ifFalse: [ nil ].
    trait ifNotNil: [
        trait simulation: simulation.
        trait rsCanvas: rsCanvas.
        trait owsMap: owsMap.
        trait centerLat: centerLat.
        trait centerLon: centerLon.
        trait initializeHUD.
    ].
    ^ self.

DroneMapWithOWSView>>open
    owsMap ifNotNil: [ (owsMap respondsTo: #open) ifTrue: [ owsMap open ] ].
    rsCanvas open.
    trait ifNotNil: [ trait startUpdatingEvery: 1000 ].
    ^ self.

Trait named: #TDroneVisualizationWithOWS
    uses: { #TRealTimeUpdate }
    category: 'DroneSystem-Visualization'.

TDroneVisualizationWithOWS>>simulation: aSim simulation := aSim.
TDroneVisualizationWithOWS>>rsCanvas: c rsCanvas := c.
TDroneVisualizationWithOWS>>owsMap: m owsMap := m.
TDroneVisualizationWithOWS>>centerLat: lat centerLat := lat.
TDroneVisualizationWithOWS>>centerLon: lon centerLon := lon.
TDroneVisualizationWithOWS>>initializeHUD
    updateDelay := 1000.
    ^ self.

TDroneVisualizationWithOWS>>projectLat: lat lon: lon
    (owsMap notNil) ifTrue: [
        (owsMap respondsTo: #worldToScreen:) ifTrue: [ ^ owsMap worldToScreen: (lat@lon) ].
        (owsMap respondsTo: #latLonToScreen:) ifTrue: [ ^ owsMap latLonToScreen: (lat@lon) ].
    ].
    | cx cy scale x y |
    cx := centerLon ifNil: [ 0 ].
    cy := centerLat ifNil: [ 0 ].
    scale := 10000.
    x := (lon - cx) * scale.
    y := ((lat - cy) * scale) negated.
    ^ x @ y.

TDroneVisualizationWithOWS>>updateCanvasWith: aSimulation
    rsCanvas clear.
    "Draw allied fleets (green) and hostiles (red)"
    aSimulation allAlliedDrones do: [:d |
        | p shape |
        p := self projectLat: d latitude lon: d longitude.
        shape := RSCircle new size: 10.
        shape translateTo: p.
        shape color: Color green.
        rsCanvas add: shape.
    ].
    aSimulation allHostileDrones do: [:h |
        | p shape |
        p := self projectLat: h latitude lon: h longitude.
        shape := RSCircle new size: 10.
        shape translateTo: p.
        shape color: Color red.
        rsCanvas add: shape.
    ].
    rsCanvas signalUpdate.
    ^ self.

TDroneVisualizationWithOWS>>refreshView
    self updateCanvasWith: simulation.
    ^ self.

"-----------------------------"
" Hostile drone class"
"-----------------------------"

Object << #HostileDrone
    slots: {}
    package: 'DroneSystem-Core'.

HostileDrone class >> new
    | inst |
    inst := super new.
    inst type: 'hostile' ifResponds: [] ifFalse: []. "placeholder for slot set; keep simple"
    ^ inst.

HostileDrone>>initialize
    "Customize defaults for hostiles"
    fuel := 120.
    speed := 12.
    perceptionRange := 60.
    type := 'hostile'.
    ^ self.

"-----------------------------"
" Fleet class"
"-----------------------------"

Object << #DroneFleet
    slots: { #clusters . #fleetId . #isHostile . #name }
    package: 'DroneSystem-Core'.

DroneFleet>>initializeWithClusters: cls id: fid hostile: aBool name: aName
    clusters := cls. fleetId := fid. isHostile := aBool. name := aName. ^ self.

DroneFleet>>clusters ^ clusters.
DroneFleet>>fleetId ^ fleetId.
DroneFleet>>isHostile ^ isHostile.
DroneFleet>>name ^ name.
DroneFleet>>allDrones ^ clusters collectMany: [:c | c drones ].

"-----------------------------"
" StrategyEvaluator and Strategies"
"-----------------------------"

Object << #StrategyEvaluator
    slots: { #simulation . #snapshots . #results }
    package: 'DroneSystem-Eval'.

StrategyEvaluator>>initialize
    simulation := nil.
    snapshots := Dictionary new.
    results := OrderedCollection new.
    ^ self.

StrategyEvaluator>>runScenario: aSimulation steps: n label: aLabel
    simulation := aSimulation.
    simulation setAsCurrent.
    1 to: n do: [:i | simulation step ].
    | metrics |
    metrics := self computeMetricsFor: simulation.
    results add: { aLabel . metrics }.
    ^ metrics.

StrategyEvaluator>>computeMetricsFor: aSimulation
    | allies hostiles allySurvive hostSurvive allyLost hostLost |
    allies := aSimulation allAlliedDrones.
    hostiles := aSimulation allHostileDrones.
    allySurvive := (allies select: [:a | a isDestroyed not]) size.
    hostSurvive := (hostiles select: [:h | h isDestroyed not]) size.
    allyLost := allies size - allySurvive.
    hostLost := hostiles size - hostSurvive.
    ^ Dictionary new
        at: #allySurvivors put: allySurvive;
        at: #hostSurvivors put: hostSurvive;
        at: #allyLost put: allyLost;
        at: #hostLost put: hostLost;
        at: #time put: aSimulation time;
        yourself.

"Evaluate multiple strategies (tries to copy simulation)"
StrategyEvaluator>>evaluate: strategies onSimulation: aSimulation forSteps: steps
    | results clone metrics |
    results := OrderedCollection new.
    strategies do: [:strat |
        clone := (aSimulation copy) ifFail: [ nil ].
        (clone notNil) ifTrue: [
            clone setAsCurrent.
            strat applyTo: clone.
            1 to: steps do: [:i | clone step ].
            metrics := self computeMetricsFor: clone.
            results add: { strat class name. metrics }.
        ] ifFalse: [
            aSimulation setAsCurrent.
            strat applyTo: aSimulation.
            1 to: steps do: [:i | aSimulation step ].
            metrics := self computeMetricsFor: aSimulation.
            results add: { strat class name, ' (in-place)'. metrics }.
        ].
    ].
    ^ results.

StrategyEvaluator>>exportResultsToCSV: results toFile: filePath
    | stream |
    stream := FileStream fileNamed: filePath.
    stream nextPutAll: 'Strategy,AllySurvivors,HostSurvivors,AllyLost,HostLost,Time'; nl.
    results do: [:row |
        | name metrics |
        name := row first.
        metrics := row second.
        stream nextPutAll: (name, ',', (metrics at: #allySurvivors) asString, ',', (metrics at: #hostSurvivors) asString, ',', (metrics at: #allyLost) asString, ',', (metrics at: #hostLost) asString, ',', (metrics at: #time) asString); nl.
    ].
    stream close.
    ^ self.

StrategyEvaluator>>visualizeStrategyResults: results
    "Simple bar chart using Roassal. Adjust if your RS version differs."
    | names allyValues hostValues chart |
    names := results collect: [:r | r first].
    allyValues := results collect: [:r | (r second at: #allySurvivors) asNumber ].
    hostValues := results collect: [:r | (r second at: #hostSurvivors) asNumber ].
    chart := RSChart new.
    chart addBarSeries: allyValues label: 'Allied'.
    chart addBarSeries: hostValues label: 'Hostile'.
    chart labels: names.
    chart open.
    ^ self.

"-----------------------------"
" Strategies (heuristics) - integrated"
"-----------------------------"

Object << #DroneStrategy
    slots: {}
    package: 'DroneSystem-Strategies'.

DroneStrategy>>applyTo: aSimulation
    self subclassResponsibility.

Object << #ReinforceWeakestClusterStrategy
    slots: { #maxReinforcements }
    package: 'DroneSystem-Strategies'.

ReinforceWeakestClusterStrategy>>initialize
    maxReinforcements := 2.
    ^ self.

ReinforceWeakestClusterStrategy>>initializeWithMax: n
    maxReinforcements := n. ^ self.

ReinforceWeakestClusterStrategy>>applyTo: aSimulation
    | alliedClusters vulnScores targetCluster centerPt centerLat centerLon donorPool donors |
    alliedClusters := aSimulation allFleets select: [:f | f isHostile not ] collectMany: [:f | f clusters ].
    alliedClusters isEmpty ifTrue: [ ^ self ].
    vulnScores := alliedClusters collect: [:c |
        | aliveCount totalFuel avgFuel score |
        aliveCount := (c drones select: [:d | d isDestroyed not ]) size.
        totalFuel := (c drones inject: 0 into: [:sum :d | sum + (d fuel ifNil: [0]) ]).
        avgFuel := (aliveCount > 0) ifTrue: [ totalFuel / aliveCount ] ifFalse: [ 0 ].
        score := (aliveCount = 0) ifTrue: [ 1.0e6 ] ifFalse: [ (1.0 / (avgFuel + 1e-6)) * (1.0 + (1.0 / aliveCount)) ].
        { c . score } ].
    targetCluster := (vulnScores asSortedCollection: [:a :b | (a second) > (b second)]) first first.
    targetCluster ifNil: [ ^ self ].
    centerPt := targetCluster clusterCenter.
    centerLat := centerPt y. centerLon := centerPt x.
    donorPool := (aSimulation allAlliedDrones select: [:d | (targetCluster drones includes: d) not and: [ d isDestroyed not and: [ d fuel > 30 ] ] ]).
    donorPool isEmpty ifTrue: [ ^ self ].
    donors := donorPool asSortedCollection: [:a :b |
        (a distanceToLatitude: centerLat longitude: centerLon altitude: 0) < (b distanceToLatitude: centerLat longitude: centerLon altitude: 0) ].
    (donors first: (maxReinforcements min: donors size)) do: [:d |
        d setBehavior: (StaticPositionBehavior new initializeWithLatitude: centerLat longitude: centerLon altitude: 120).
    ].
    Transcript show: 'ReinforceWeakestClusterStrategy applied to cluster ', (targetCluster clusterId asString), ' donors=', (maxReinforcements min: donors size) asString; cr.
    ^ self.

Object << #InterceptHostilesStrategy
    slots: { #maxInterceptors . #perHostile . #fuelReserve }
    package: 'DroneSystem-Strategies'.

InterceptHostilesStrategy>>initialize
    maxInterceptors := 3.
    perHostile := 1.
    fuelReserve := 30.
    ^ self.

InterceptHostilesStrategy>>initializeWithMaxInterceptors: max perHostile: ph fuelReserve: fr
    maxInterceptors := max. perHostile := ph. fuelReserve := fr. ^ self.

InterceptHostilesStrategy>>applyTo: aSimulation
    | hostiles allies candidates selected |
    hostiles := aSimulation allHostileDrones select: [:h | h isDestroyed not ].
    allies := aSimulation allAlliedDrones select: [:d | d isDestroyed not and: [ d fuel > fuelReserve ] ].
    (hostiles isEmpty or: [ allies isEmpty ]) ifTrue: [ ^ self ].
    hostiles do: [:h |
        candidates := allies asSortedCollection: [:a :b |
            | ta tb |
            ta := (a distanceToLatitude: h latitude longitude: h longitude altitude: h altitude) / (a speed max: 0.1).
            tb := (b distanceToLatitude: h latitude longitude: h longitude altitude: h altitude) / (b speed max: 0.1).
            ta < tb ].
        selected := (candidates first: (perHostile min: candidates size)).
        selected do: [:d |
            d setBehavior: (PatrolBehavior new initializeWithWaypoints: { { h latitude. h longitude. h altitude } }).
        ].
    ].
    Transcript show: 'InterceptHostilesStrategy dispatched interceptors for ', hostiles size asString, ' hostiles'; cr.
    ^ self.

Object << #ConcentricDefenseStrategy
    slots: { #center . #radiusLayers . #spacing . #dronesPerLayer }
    package: 'DroneSystem-Strategies'.

ConcentricDefenseStrategy>>initializeWithCenter: aCenter radiusLayers: layers spacing: s dronesPerLayer: n
    center := aCenter. radiusLayers := layers. spacing := s. dronesPerLayer := n. ^ self.

ConcentricDefenseStrategy>>applyTo: aSimulation
    | allies lat0 lon0 i angle ringCount totalNodes idx d |
    allies := aSimulation allAlliedDrones.
    allies isEmpty ifTrue: [ ^ self ].
    lat0 := (center isPoint) ifTrue: [ center x ] ifFalse: [ center at: 1 ].
    lon0 := (center isPoint) ifTrue: [ center y ] ifFalse: [ center at: 2 ].
    1 to: radiusLayers do: [:i |
        ringCount := dronesPerLayer * i.
        totalNodes := ringCount.
        1 to: totalNodes do: [:idx |
            angle := (2 * Float pi * (idx - 1)) / totalNodes.
            lat := lat0 + ((spacing * i) * (angle cos) * 0.01).
            lon := lon0 + ((spacing * i) * (angle sin) * 0.01).
            d := (allies at: ((idx - 1) \\ allies size) + 1).
            d setBehavior: (StaticPositionBehavior new initializeWithLatitude: lat longitude: lon altitude: 120).
        ].
    ].
    Transcript show: 'ConcentricDefenseStrategy applied with ', radiusLayers asString, ' layers'; cr.
    ^ self.

Object << #EnergySavingPatrolStrategy
    slots: { #activeRatio . #cycleLength . #lastAppliedAt }
    package: 'DroneSystem-Strategies'.

EnergySavingPatrolStrategy>>initializeWithActiveRatio: ratio cycleLength: cycles
    activeRatio := ratio. cycleLength := cycles. lastAppliedAt := nil. ^ self.

EnergySavingPatrolStrategy>>applyTo: aSimulation
    | allies alliesList t activeCount |
    alliesList := aSimulation allAlliedDrones.
    alliesList isEmpty ifTrue: [ ^ self ].
    t := aSimulation time.
    (lastAppliedAt notNil and: [ (t - lastAppliedAt) < cycleLength ]) ifTrue: [ ^ self ].
    lastAppliedAt := t.
    activeCount := (alliesList size * activeRatio) asInteger max: 1.
    alliesList withIndexDo: [:d :i |
        (i <= activeCount)
            ifTrue: [ d setBehavior: (PatrolBehavior new initializeWithWaypoints: { { d latitude . d longitude . d altitude } }) ]
            ifFalse: [ d setBehavior: (StaticPositionBehavior new initializeWithLatitude: d latitude longitude: d longitude altitude: d altitude) ]
    ].
    Transcript show: 'EnergySavingPatrolStrategy applied at time ', t asString; cr.
    ^ self.

"-----------------------------"
" Scenarios convenience class"
"-----------------------------"

Object << #DroneScenarios
    slots: {}
    package: 'DroneSystem-Examples'.

DroneScenarios class >> exampleSurveillance
    | sim drones cluster mission polygon view |
    sim := SimulationState new.
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

DroneScenarios class >> exampleSecuring
    | sim drones cluster mission polygon view |
    sim := SimulationState new.
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

"-----------------------------"
" End of .st file"
"-----------------------------"
