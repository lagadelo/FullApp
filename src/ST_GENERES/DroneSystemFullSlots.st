Object << #STFileIn
    slots: { #dummy };
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
     ;   package: 'DroneSystem-Core'.

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
     ;   package: 'DroneSystem-Behaviors'.

DroneBehavior>>executeFor: aDrone atTime: aTime
    self subclassResponsibility.

Object << #PatrolBehavior
    slots: { #waypoints . #currentIndex }
     ;   package: 'DroneSystem-Behaviors'.

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
     ;   package: 'DroneSystem-Behaviors'.

StaticPositionBehavior>>initializeWithLatitude: lat longitude: lon altitude: alt
    sLat := lat. sLon := lon. sAlt := alt. ^ self.

StaticPositionBehavior>>executeFor: aDrone atTime: aTime
    aDrone moveToLatitude: sLat longitude: sLon altitude: sAlt.

"Attack and aggressive behaviors for hostiles"
Object << #AttackBehavior
    slots: { #weaponName . #quantity . #probability . #impact . #targetSelector }
     ;   package: 'DroneSystem-Behaviors'.

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
     ;   package: 'DroneSystem-Behaviors'.

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
     ;   package: 'DroneSystem-Utils'.

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
     ;   package: 'DroneSystem-Core'.

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
    drones := drones select: [:d | d  ... truncated ...