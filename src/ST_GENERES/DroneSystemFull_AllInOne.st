"DroneSystemFull_AllInOne.st"

"=========================================================="
"  DRONE SYSTEM FULL - All in one file (Pharo 13 + Roassal)"
"  - Optional PharoOWS integration (fallback to Roassal-only)"
"  - Multi-fleet, hostile drones, behaviors, evaluator, scenarios"
"=========================================================="

"========================"
" Traits and Utilities "
"========================"

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

TPositionable>>latitude ^ latitude.
TPositionable>>longitude ^ longitude.
TPositionable>>altitude ^ altitude.
TPositionable>>setPositionLat: lat lon: lon alt: alt
    latitude := lat. longitude := lon. altitude := alt.

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

"========================"
" Core domain classes "
"========================"

Object subclass: #Drone
    uses: { TIdentifiable . TPositionable . TConsumableCarrier . TDamageable }
    instanceVariableNames: 'fuel speed perceptionRange behavior uniqueId type currentMission needsHelp detectedEnemy consumables'
    classVariableNames: ''
    package: 'Drones-Core'.

Drone>>initialize
    self initializeId.
    latitude := 48.8566. "default: Paris"
    longitude := 2.3522.
    altitude := 100.
    fuel := 100.
    self initializeConsumables.
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
        ifFalse: [ needsHelp := true. Transcript show: 'Drone ', self id, ' low fuel'; cr ].

Drone>>distanceToLatitude: lat longitude: lon altitude: alt
    ^ ((latitude - lat) squared + (longitude - lon) squared + (altitude - alt) squared) sqrt.

Drone>>canPerceiveDrone: otherDrone
    ^ (self distanceToLatitude: otherDrone latitude longitude: otherDrone longitude altitude: otherDrone altitude) <= perceptionRange.

Drone>>communicateWithConsensus: consensus
    consensus receiveStatusMessage: self statusMessage.

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

Drone>>applyDamage: damage
    self applyDamage: damage. "delegate to trait method" ifFalse: [ Transcript show: 'applyDamage delegate failed'; cr ]. "placeholder"

Drone>>isDestroyed
    ^ (fuel = 0) or: [ speed = 0 ].

Drone>>setBehavior: aBehavior behavior := aBehavior.
Drone>>sendHelpRequestToConsensus: consensus
    consensus receiveMessage: self helpRequestMessage.

Drone>>helpRequestMessage
    ^ Dictionary new
        at: #type put: #helpRequest;
        at: #from put: uniqueId;
        at: #position put: { latitude. longitude. altitude };
        at: #reason put: 'Low fuel or under attack';
        yourself.

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

"--- Drone behaviors ---"

Object subclass: #DroneBehavior
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Behaviors'.

DroneBehavior>>executeFor: aDrone atTime: aTime
    self subclassResponsibility.

DroneBehavior subclass: #PatrolBehavior
    instanceVariableNames: 'waypoints currentIndex'
    classVariableNames: ''
    package: 'Drones-Behaviors'.

PatrolBehavior>>initializeWithWaypoints: aCollection
    waypoints := aCollection.
    currentIndex := 1.

PatrolBehavior>>executeFor: aDrone atTime: aTime
    | nextWaypoint |
    nextWaypoint := waypoints at: currentIndex.
    aDrone moveToLatitude: (nextWaypoint at: 1) longitude: (nextWaypoint at: 2) altitude: (nextWaypoint at: 3).
    currentIndex := (currentIndex \\ waypoints size) + 1.

DroneBehavior subclass: #StaticPositionBehavior
    instanceVariableNames: 'sLat sLon sAlt'
    classVariableNames: ''
    package: 'Drones-Behaviors'.

StaticPositionBehavior>>initializeWithLatitude: lat longitude: lon altitude: alt
    sLat := lat. sLon := lon. sAlt := alt.

StaticPositionBehavior>>executeFor: aDrone atTime: aTime
    aDrone moveToLatitude: sLat longitude: sLon altitude: sAlt.

"========================"
" Convex hull utility "
"========================"

Object subclass: #ConvexHullCalculator
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Utils'.

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

"========================"
" Cluster and Missions "
"========================"

Object subclass: #DroneCluster
    instanceVariableNames: 'drones clusterId coverage capabilities currentMission'
    classVariableNames: ''
    package: 'Drones-Core'.

DroneCluster>>initializeWithDrones: droneList clusterId: anId
    drones := droneList.
    clusterId := anId.
    self updateCapabilities.
    self updateCoverage.
    currentMission := nil.

DroneCluster>>updateCapabilities
    capabilities := Dictionary new.
    capabilities at: #fuel put: (drones sum: [:d | d isDestroyed ifFalse: [d fuel] ifTrue: [0]]).
    capabilities at: #perceptionRange put: (drones collect: [:d | d isDestroyed ifFalse: [d perceptionRange] ifTrue: [0]]) max.
    capabilities at: #munitions put: (drones sum: [:d | d isDestroyed ifFalse: [d consumables values sum] ifTrue: [0]]).

DroneCluster>>updateCoverage
    | activePositions |
    activePositions := drones select: [:d | d isDestroyed not] collect: [:d | { d latitude. d longitude } ].
    coverage := ConvexHullCalculator new computeHullFrom: activePositions.

DroneCluster>>removeDestroyedDrones
    drones := drones select: [:d | d isDestroyed not].
    self updateCapabilities.
    self updateCoverage.

DroneCluster>>isOperational
    ^ drones anySatisfy: [:d | d isDestroyed not].

DroneCluster>>clusterCenter
    | lats lons |
    lats := coverage collect: [:p | p at: 1].
    lons := coverage collect: [:p | p at: 2].
    ^ Point x: (lons sum / lons size) y: (lats sum / lats size).

DroneCluster>>coverage ^ coverage.
DroneCluster>>capabilities ^ capabilities.
DroneCluster>>clusterId ^ clusterId.
DroneCluster>>drones ^ drones.
DroneCluster>>currentMission ^ currentMission.
DroneCluster>>currentMission: aMission currentMission := aMission.

"--- Cluster missions ---"

Object subclass: #ClusterMission
    instanceVariableNames: 'missionType zoneParameters'
    classVariableNames: ''
    package: 'Drones-Core'.

ClusterMission>>initializeWithType: aType zoneParameters: params
    missionType := aType.
    zoneParameters := params.

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
        drone setBehavior: (
            StaticPositionBehavior new initializeWithLatitude: (positions at: i) longitude: ((positions at: i) at: 2) altitude: ((positions at: i) at: 3)
        ).
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

"========================"
" Simulation State "
"========================"

Object subclass: #SimulationState
    instanceVariableNames: 'drones clusters missionHistory time eventLog reactionLog verificationFunctions allFleets'
    classVariableNames: ''
    package: 'Drones-Core'.

SimulationState>>initialize
    drones := OrderedCollection new.
    clusters := OrderedCollection new.
    missionHistory := OrderedCollection new.
    eventLog := OrderedCollection new.
    reactionLog := OrderedCollection new.
    verificationFunctions := OrderedCollection new.
    allFleets := OrderedCollection new.
    time := 0.

SimulationState class>>current
    "Convenience holder: store a global reference for behaviors that need quick access"
    ^ Smalltalk at: #CurrentSimulation ifAbsent: [ nil ].

SimulationState>>setAsCurrent
    Smalltalk at: #CurrentSimulation put: self.

SimulationState>>step
    "Execute behaviors for drones not in fleets"
    drones do: [:drone | drone behavior ifNotNil: [ drone behavior executeFor: drone atTime: time ] ].
    "Execute fleet behaviors and cluster updates"
    allFleets do: [:fleet | fleet clusters do: [:cluster | cluster updateCapabilities. cluster updateCoverage. cluster drones do: [:d | d behavior ifNotNil: [ d behavior executeFor: d atTime: time ] ] ] ].
    "Resolve engagements"
    self resolveEngagements.
    time := time + 1.

SimulationState>>resolveEngagements
    "Simple engagements: hostiles attack allies in range; allies may retaliate"
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
            eventLog add: (String streamContents: [:s | s nextPutAll: 'Engagement: Hostile '; nextPutAll: h id; nextPutAll: ' attacked Allied '; nextPutAll: target id; nextPutAll: ' hits='; nextPutAll: hits asString ]).
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
            reactionLog add: (String streamContents: [:s | s nextPutAll: 'Retaliation: Allied '; nextPutAll: a id; nextPutAll: ' attacked Hostile '; nextPutAll: target id; nextPutAll: ' hits='; nextPutAll: hits asString ]).
        ].
    ].

SimulationState>>addDrone: d
    drones add: d.

SimulationState>>addCluster: c
    clusters add: c.

SimulationState>>drones ^ drones.
SimulationState>>clusters ^ clusters.
SimulationState>>time ^ time.

" Fleet management "

SimulationState>>addFleet: aFleet
    allFleets add: aFleet.

SimulationState>>removeFleet: aFleet
    allFleets remove: aFleet ifAbsent: [ nil ].

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

"========================"
" Visualization (Roassal + optional PharoOWS) "
"========================"

Object subclass: #DroneMapWithOWSView
    instanceVariableNames: 'simulation owsMap rsCanvas trait centerLat centerLon zoom hudLayer'
    classVariableNames: ''
    package: 'Drones-Visualization'.

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

DroneMapWithOWSView>>open
    owsMap ifNotNil: [ (owsMap respondsTo: #open) ifTrue: [ owsMap open ] ].
    rsCanvas open.
    trait ifNotNil: [ trait startUpdatingEvery: 1000 ].

" Trait for visualization "

Trait named: #TDroneVisualizationWithOWS
    uses: { #TRealTimeUpdate }
    category: 'Drones-Visualization'.

TDroneVisualizationWithOWS>>simulation: aSim simulation := aSim.
TDroneVisualizationWithOWS>>rsCanvas: c rsCanvas := c.
TDroneVisualizationWithOWS>>owsMap: m owsMap := m.
TDroneVisualizationWithOWS>>centerLat: lat centerLat := lat.
TDroneVisualizationWithOWS>>centerLon: lon centerLon := lon.
TDroneVisualizationWithOWS>>initializeHUD
    hudLayer := OrderedCollection new.
    updateDelay := 1000.
    savedState := nil.
    savedTime := 0.
    self addControlButtons.

" Basic HUD, simplified for monolithic file "
TDroneVisualizationWithOWS>>addControlButtons
    | hudY hudBackground start stop step resume label slider |
    hudY := rsCanvas extent y - 30.
    hudBackground := RSBox new size: rsCanvas extent; color: (Color gray alpha: 0.2).
    hudBackground translateTo: (rsCanvas extent / 2).
    start := RSText new string: '▶' fontSize: 18.
    start translateTo: 20 @ hudY.
    start @ (RSInteraction onClickDo: [ self startUpdatingEvery: updateDelay ]).
    stop := RSText new string: '⏹' fontSize: 18.
    stop translateTo: 60 @ hudY.
    stop @ (RSInteraction onClickDo: [ self stopUpdating ]).
    step := RSText new string: '⏭' fontSize: 18.
    step translateTo: 100 @ hudY.
    step @ (RSInteraction onClickDo: [ simulation step. self refreshView ]).
    resume := RSText new string: '🔄' fontSize: 18.
    resume translateTo: 140 @ hudY.
    resume @ (RSInteraction onClickDo: [ savedState ifNotNil: [ simulation := savedState copy. simulation instVarNamed: 'time' put: savedTime. self refreshView. self startUpdatingEvery: updateDelay ] ifNil: [ Transcript show: 'No saved state'; cr ] ]).
    label := RSText new string: 'Delay: ' , updateDelay asString , ' ms' ; fontSize: 10.
    label translateTo: 200 @ hudY.
    rsCanvas addAll: { hudBackground. start. stop. step. resume. label }.

TDroneVisualizationWithOWS>>refreshView
    self updateCanvasWith: simulation.
    "Update HUD elements if needed" .

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

"========================"
" Hostile drones & behaviors "
"========================"

Drone subclass: #HostileDrone
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Core'.

HostileDrone>>initialize
    super initialize.
    type := 'hostile'.
    fuel := 120.
    speed := 12.
    perceptionRange := 60.

Object subclass: #AttackBehavior
    instanceVariableNames: 'weaponName quantity probability impact targetSelector'
    classVariableNames: ''
    package: 'Drones-Behaviors'.

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

Object subclass: #AggressiveBehavior
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Behaviors'.

AggressiveBehavior>>executeFor: aDrone atTime: t
    | enemies nearest |
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

"========================"
" Fleet (group of clusters) "
"========================"

Object subclass: #DroneFleet
    instanceVariableNames: 'clusters fleetId isHostile name'
    classVariableNames: ''
    package: 'Drones-Core'.

DroneFleet>>initializeWithClusters: cls id: fid hostile: aBool name: aName
    clusters := cls. fleetId := fid. isHostile := aBool. name := aName. ^ self.

DroneFleet>>clusters ^ clusters.
DroneFleet>>fleetId ^ fleetId.
DroneFleet>>isHostile ^ isHostile.
DroneFleet>>name ^ name.
DroneFleet>>allDrones ^ clusters collectMany: [:c | c drones ].

"========================"
" Strategy evaluator "
"========================"

Object subclass: #StrategyEvaluator
    instanceVariableNames: 'simulation snapshots results'
    classVariableNames: ''
    package: 'Drones-Eval'.

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

StrategyEvaluator>>results ^ results.

"========================"
" Scenarios (convenience) "
"========================"

Object subclass: #DroneScenarios
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Examples'.

DroneScenarios class>>exampleSurveillance
    | sim drones cluster mission polygon view trait |
    sim := SimulationState new.
    sim setAsCurrent.

    drones := {
        Drone new. Drone new. Drone new
    } asOrderedCollection.
    drones at: 1 moveToLatitude: 48.8566 longitude: 2.3522 altitude: 120.
    drones at: 2 moveToLatitude: 48.8666 longitude: 2.3622 altitude: 120.
    drones at: 3 moveToLatitude: 48.8466 longitude: 2.3422 altitude: 120.

    cluster := DroneCluster new initializeWithDrones: drones clusterId: 1.
    sim addFleet: (DroneFleet new initializeWithClusters: { cluster } id: 1 hostile: false name: 'Blue').
    polygon := { { 48.86. 2.34. 100 }. { 48.87. 2.36. 100 }. { 48.85. 2.37. 100 }. }.
    mission := ClusterMission new initializeWithType: #surveillance zoneParameters: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignToCluster: cluster.

    view := DroneMapWithOWSView new initializeWithSimulation: sim centerLat: 48.8566 centerLon: 2.3522 zoom: 12.
    view open.
    ^ sim.

DroneScenarios class>>exampleSecuring
    | sim drones cluster mission polygon view |
    sim := SimulationState new.
    sim setAsCurrent.

    drones := {
        Drone new. Drone new. Drone new
    } asOrderedCollection.
    drones at: 1 moveToLatitude: 48.8566 longitude: 2.3522 altitude: 120.
    drones at: 2 moveToLatitude: 48.8766 longitude: 2.3622 altitude: 120.
    drones at: 3 moveToLatitude: 48.8366 longitude: 2.3422 altitude: 120.

    cluster := DroneCluster new initializeWithDrones: drones clusterId: 2.
    sim addFleet: (DroneFleet new initializeWithClusters: { cluster } id: 2 hostile: false name: 'Green').
    polygon := { { 48.88. 2.34. 100 }. { 48.87. 2.37. 100 }. { 48.84. 2.36. 100 }. }.
    mission := ClusterMission new initializeWithType: #securisation zoneParameters: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignToCluster: cluster.

    view := DroneMapWithOWSView new initializeWithSimulation: sim centerLat: 48.8566 centerLon: 2.3522 zoom: 12.
    view open.
    ^ sim.

"========================"
" End of file "
"========================"
