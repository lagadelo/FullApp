'DroneSystemFullWithHUD.st'

"===================="
"--- Modèle Drone ---"
"===================="

Object subclass: #Drone
    instanceVariableNames: 'latitude longitude altitude fuel consumables speed perceptionRange behavior uniqueId type currentMission needsHelp detectedEnemy'
    classVariableNames: ''
    package: 'Drones'.

Drone>>initialize
    latitude := 0.
    longitude := 0.
    altitude := 0.
    fuel := 100.
    consumables := Dictionary new.
    speed := 10.
    perceptionRange := 50.
    behavior := nil.
    uniqueId := UUID new asString.
    type := 'standard'.
    currentMission := nil.
    needsHelp := false.
    detectedEnemy := false.

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
        ifFalse: [ needsHelp := true. ^'Pas assez de carburant' ].

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
    (self canPerceiveDrone: targetDrone)
        ifFalse: [ ^'Cible hors de portée' ].
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
    fuel := (fuel - damage) max: 0.
    speed := (speed - (damage / 10)) max: 0.
    perceptionRange := (perceptionRange - (damage / 20)) max: 0.

Drone>>isDestroyed
    ^ fuel = 0 or: [speed = 0].

Drone>>setBehavior: aBehavior
    behavior := aBehavior.

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
Drone>>detectedEnemy ^ detectedEnemy.
Drone>>needsHelp: aBool needsHelp := aBool.
Drone>>detectedEnemy: aBool detectedEnemy := aBool.


"===================="
"--- Comportements ---"
"===================="

Object subclass: #DroneBehavior
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones'.

DroneBehavior>>executeFor: aDrone atTime: aTime
    self subclassResponsibility.

DroneBehavior subclass: #PatrolBehavior
    instanceVariableNames: 'waypoints currentIndex'
    classVariableNames: ''
    package: 'Drones'.

PatrolBehavior>>initializeWithWaypoints: aCollection
    waypoints := aCollection.
    currentIndex := 1.

PatrolBehavior>>executeFor: aDrone atTime: aTime
    | nextWaypoint |
    nextWaypoint := waypoints at: currentIndex.
    aDrone moveToLatitude: (nextWaypoint at: 1) longitude: (nextWaypoint at: 2) altitude: (nextWaypoint at: 3).
    currentIndex := currentIndex \ waypoints size + 1.

DroneBehavior subclass: #StaticPositionBehavior
    instanceVariableNames: 'latitude longitude altitude'
    classVariableNames: ''
    package: 'Drones'.

StaticPositionBehavior>>initializeWithLatitude: lat longitude: lon altitude: alt
    latitude := lat.
    longitude := lon.
    altitude := alt.

StaticPositionBehavior>>executeFor: aDrone atTime: aTime
    aDrone moveToLatitude: latitude longitude: longitude altitude: altitude.


"============================="
"--- Calcul enveloppe convexe ---"
"============================="

Object subclass: #ConvexHullCalculator
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones'.

ConvexHullCalculator>>computeHullFrom: points
    | sorted hull |
    sorted := points sort: [:a :b | (a at: 1) < (b at: 1) ].
    hull := OrderedCollection new.
    sorted do: [:p | 
        [ hull size >= 2 and: [ self turn: (hull at: hull size - 1) to: (hull last) to: p ] <= 0 ]
            whileTrue: [ hull removeLast ].
        hull add: p.
    ].
    sorted reversed do: [:p | 
        [ hull size >= 2 and: [ self turn: (hull at: hull size - 1) to: (hull last) to: p ] <= 0 ]
            whileTrue: [ hull removeLast ].
        hull add: p.
    ].
    ^ hull asArray.

ConvexHullCalculator>>turn: a to: b to: c
    ^ ((b at: 1) - (a at: 1)) * ((c at: 2) - (a at: 2))
        - ((b at: 2) - (a at: 2)) * ((c at: 1) - (a at: 1)).


"======================="
"--- Cluster ---"
"======================="

Object subclass: #DroneCluster
    instanceVariableNames: 'drones clusterId coverage capabilities currentMission'
    classVariableNames: ''
    package: 'Drones'.

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


"==========================="
"--- Simulation State ---"
"==========================="

Object subclass: #SimulationState
    instanceVariableNames: 'drones clusters missionHistory time eventLog reactionLog verificationFunctions'
    classVariableNames: ''
    package: 'Drones'.

SimulationState>>initialize
    drones := OrderedCollection new.
    clusters := OrderedCollection new.
    missionHistory := OrderedCollection new.
    eventLog := OrderedCollection new.
    reactionLog := OrderedCollection new.
    verificationFunctions := OrderedCollection new.
    time := 0.

SimulationState>>step
    drones do: [:drone | drone behavior ifNotNil: [ drone behavior executeFor: drone atTime: time ] ].
    clusters do: [:cluster | cluster updateCapabilities. cluster updateCoverage ].
    time := time + 1.

SimulationState>>time ^ time.


"======================="
"--- HUD temps réel ---"
"======================="

Trait named: #TRealTimeUpdate
uses: {}
category: 'Simulation-HUD'.

TRealTimeUpdate class >> withOn: aSimulation in: aCanvas
    ^ self new
        simulation: aSimulation;
        canvas: aCanvas;
        initializeHUD;
        yourself.

TRealTimeUpdate>>simulation: aSimulation simulation := aSimulation.
TRealTimeUpdate>>canvas: aCanvas canvas := aCanvas.

TRealTimeUpdate>>initializeHUD
    updateDelay := 500.
    savedState := nil.
    savedTime := 0.
    self addControlButtons.

TRealTimeUpdate>>startUpdatingEvery: milliseconds
    self stopUpdating.
    updateProcess := [
        [ true ] whileTrue: [
            (Delay forMilliseconds: milliseconds) wait.
            simulation step.
            self refreshView.
        ].
    ] forkAt: Processor userBackgroundPriority.

TRealTimeUpdate>>stopUpdating
    updateProcess ifNotNil: [
        updateProcess terminate.
        updateProcess := nil
    ].

TRealTimeUpdate>>refreshView
    self updateCanvasWith: simulation.
    timeLabel string: 'Time: ', (simulation instVarNamed: 'time') asString, ' s'.

TRealTimeUpdate>>updateCanvasWith: aSimulation
    canvas shapes do: #remove.
    aSimulation drones do: [:drone |
        | shape |
        shape := RSCircle new size: 8; color: Color blue.
        shape translateTo: (drone latitude @ drone longitude).
        canvas add: shape
    ].
    canvas signalUpdate.

"==== HUD et boutons ===="
TRealTimeUpdate>>addControlButtons
    | hudY hudBackground startIcon pauseIcon stopIcon stepIcon resumeIcon background slider label padding barWidth barHeight pausePopup stopPopup |

    padding := 20.
    barWidth := canvas extent x.
    barHeight := 60.
    hudY := canvas extent y - (barHeight / 2).

    hudBackground := RSBox new
        size: barWidth @ barHeight;
        color: (Color gray alpha: 0.2);
        yourself.
    hudBackground translateTo: (barWidth / 2) @ hudY.

    startIcon := RSText new string: '▶️'; fontSize: 24; color: Color green.
    startIcon translateTo: (padding + 30) @ hudY.
    startIcon @ (RSInteraction onClickDo: [ self startUpdatingEvery: updateDelay ]).

    pauseIcon := RSText new string: '⏸️'; fontSize: 24; color: Color yellow.
    pauseIcon translateTo: (padding + 90) @ hudY.
    pausePopup := RSPopup new.
    pausePopup text: 'Pause options:'.
    pausePopup addItem: 'Pause simple' do: [ self stopUpdating ].
    pausePopup addItem: 'Pause + sauvegarde' do: [
        self stopUpdating.
        savedState := simulation copy.
        savedTime := simulation instVarNamed: 'time'.
    ].
    pauseIcon @ pausePopup.

    stopIcon := RSText new string: '⏹️'; fontSize: 24; color: Color red.
    stopIcon translateTo: (padding + 150) @ hudY.
    stopPopup := RSPopup new.
    stopPopup text: 'Stop options:'.
    stopPopup addItem: 'Stop simple' do: [ self stopUpdating ].
    stopPopup addItem: 'Stop + Reset' do: [
        self stopUpdating.
        simulation := SimulationState new.
        self refreshView.
    ].
    stopIcon @ stopPopup.

    stepIcon := RSText new string: '⏭️'; fontSize: 24; color: Color orange.
    stepIcon translateTo: (padding + 210) @ hudY.
    stepIcon @ (RSInteraction onClickDo: [
        simulation step.
        self refreshView.
    ]).

    resumeIcon := RSText new string: '🔄'; fontSize: 24; color: Color cyan.
    resumeIcon translateTo: (padding + 270) @ hudY.
    resumeIcon @ (RSInteraction onClickDo: [
        savedState ifNotNil: [
            simulation := savedState copy.
            simulation instVarNamed: 'time' put: savedTime.
            self refreshView.
            self startUpdatingEvery: updateDelay.
        ] ifNil: [
            Transcript show: 'Aucun état sauvegardé à reprendre.'; cr.
        ].
    ]).

    background := RSBox new size: 200@10; color: (Color gray alpha: 0.4).
    background translateTo: (padding + 480) @ hudY.

    slider := RSCircle new size: 15; color: Color blue.
    slider translateTo: (padding + 380) @ hudY.

    label := RSText new string: 'Delay: ', updateDelay asString, ' ms'; fontSize: 10.
    label translateTo: (padding + 480) @ (hudY + 20).

    slider @ (RSInteraction onDragDo: [:pt |
        | minX maxX newX ratio newDelay |
        minX := (padding + 380).
        maxX := (padding + 580).
        newX := pt x min: maxX max: minX.
        slider translateTo: newX @ hudY.
        ratio := (newX - minX) / (maxX - minX).
        newDelay := 100 + (2000 - 100) * (1 - ratio).
        updateDelay := newDelay asInteger.
        label string: 'Delay: ', updateDelay asString, ' ms'.
    ]).

    timeLabel := RSText new string: 'Time: 0 s'; fontSize: 12; color: Color white.
    timeLabel translateTo: (barWidth - 80) @ hudY.

    canvas hudLayer addAll: {
        hudBackground.
        startIcon. pauseIcon. stopIcon. stepIcon. resumeIcon.
        background. slider. label.
        timeLabel
    }.
