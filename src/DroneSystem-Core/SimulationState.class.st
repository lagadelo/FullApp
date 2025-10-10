Class {
	#name : 'SimulationState',
	#superclass : 'Object',
	#instVars : [
		'time',
		'allFleets',
		'missions',
		'eventLog',
		'missionHistory',
		'reactionLog',
		'engagementMode',
		'steps',
		'verificationFunctions',
		'observers'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'visiting' }
SimulationState >> accept: aVisitor [

^aVisitor visitSimulationState: self 
]

{ #category : 'initialization' }
SimulationState >> addFleet: aFleet [
    allFleets add: aFleet.
    ^ self.
]

{ #category : 'accessing' }
SimulationState >> addMission: aMission [ 

self missions add: aMission
]

{ #category : 'api - selection' }
SimulationState >> allAlliedClusters [
    ^ self allClusters reject:[:c | c isHostile] 
]

{ #category : 'api - selection' }
SimulationState >> allAlliedDrones [
  "  ^ (self allFleets
        selectMany: [:f | f alliedClusters]) collectMany:[:c| c drones ]  "

| tmp |
tmp := self allHostileDrones.
^self allDrones reject:[:a| tmp includes:a].
]

{ #category : 'api - selection' }
SimulationState >> allClusters [
    ^ (self allFleets
        selectMany: [:f | f clusters ])  
]

{ #category : 'api - selection' }
SimulationState >> allDrones [
    ^ self allClusters collectMany:[:f| f drones  ]"protocol: #initialization"

]

{ #category : 'accessing' }
SimulationState >> allFleets [

	^ allFleets
]

{ #category : 'accessing' }
SimulationState >> allFleets: anObject [

	allFleets := anObject
]

{ #category : 'api - selection' }
SimulationState >> allHostileClusters [
    ^ self allClusters select:[:c | c isHostile] 
]

{ #category : 'api - selection' }
SimulationState >> allHostileDrones [
      "(self allFleets
        selectMany: [:f | f hostileClusters ]) collectMany:[:f| f drones  ]"

 ^self allDrones select:[:a| a isHostile]
]

{ #category : 'resolution' }
SimulationState >> allMissions [ 
"should refactor: select:[:a status ...]"
^(self allClusters collect:[:c| c currentMission]) reject:  [:a| a isNil]
]

{ #category : 'api - selection' }
SimulationState >> areInProximity: clusterA and: clusterB [
    "Simple threshold in km, refine later with Haversine."
  
^(clusterA canDetectCluster: clusterB) | (clusterB canDetectCluster: clusterA)
]

{ #category : 'resolution' }
SimulationState >> battleZone [

| tmp |
tmp := OrderedCollection new.
tmp addAll: (self allDrones collect:[:d| d position]).
tmp addAll:(self allMissions collectMany:[:m| m battleZone ]).
 ^ tmp 
]

{ #category : 'accessing' }
SimulationState >> battleZone: anObject [

	battleZone := anObject
]

{ #category : 'api - selection' }
SimulationState >> countAlliedAlive [
    "Retourne le nombre de drones alliés encore actifs (non détruits)."
    ^ (self allAlliedDrones select: [:d | d isDestroyed not]) size

]

{ #category : 'api - selection' }
SimulationState >> countHostileAlive [
    "Retourne le nombre de drones hostiles encore actifs (non détruits)."
    ^ (self allHostileDrones select: [:d | d isDestroyed not]) size
]

{ #category : 'initialization' }
SimulationState >> current [
    ^ Smalltalk at: #CurrentSimulation ifAbsent: [ nil ].

]

{ #category : 'initialization' }
SimulationState >> deepCopy [
    | copy droneMap clusterMap fleetMap newDrones newClusters newFleets |
    copy :=  SimulationState new initialize.
    "Clone standalone drones"
     
   
    newFleets := allFleets collect:[:f| f deepCopy].

    copy allFleets: newFleets "ifResponds: [] ifFalse: []".
    "Copy time and logs"
    copy time: time "fResponds: [] ifFalse: []".
    copy missionHistory: missionHistory copy "ifResponds: [] ifFalse: []".
    copy eventLog: eventLog copy "ifResponds: [] ifFalse: []".
    copy reactionLog: reactionLog copy "ifResponds: [] ifFalse: []".
    copy verificationFunctions: (verificationFunctions collect: [:f | f]) "ifResponds: [] ifFalse: []".
    ^ copy.
]

{ #category : 'accessing' }
SimulationState >> engagementMode [

	^ engagementMode
]

{ #category : 'accessing' }
SimulationState >> engagementMode: anObject [

	engagementMode := anObject
]

{ #category : 'facilities' }
SimulationState >> entitiesInPerceptionRangeOf: aDrone [
    ^ self allDrones select: [:e |
        (e position distanceTo: aDrone position) <= aDrone perceptionRange
    ].

]

{ #category : 'accessing' }
SimulationState >> eventLog [

	^ eventLog
]

{ #category : 'accessing' }
SimulationState >> eventLog: anObject [

	eventLog := anObject
]

{ #category : 'system changes' }
SimulationState >> hasChanged [
self observers do:[:a| a update:self] 
]

{ #category : 'initialization' }
SimulationState >> initialize [
 
    allFleets := OrderedCollection new.
   
    missionHistory := OrderedCollection new.
    eventLog := OrderedCollection new.
    reactionLog := OrderedCollection new.
    verificationFunctions := OrderedCollection new.
    time := 0.
    steps := OrderedCollection new.
	 observers := OrderedCollection new.

    engagementMode := #droneLevel.  "Default mode"
]

{ #category : 'accessing' }
SimulationState >> missionHistory [

	^ missionHistory
]

{ #category : 'accessing' }
SimulationState >> missionHistory: anObject [

	missionHistory := anObject
]

{ #category : 'accessing' }
SimulationState >> missions [ 

missions ifNil:[missions := OrderedCollection new].
^missions
]

{ #category : 'accessing' }
SimulationState >> missions: anObject [

	missions := anObject
]

{ #category : 'accessing' }
SimulationState >> observers [

	^ observers
]

{ #category : 'accessing' }
SimulationState >> observers: anObject [

	observers := anObject
]

{ #category : 'user interface' }
SimulationState >> open [ 
| tmp |
tmp  := (DroneMapWithOWSView  simulation: self ).
self  registerObserver: tmp.
tmp open
]

{ #category : 'accessing' }
SimulationState >> reactionLog [

	^ reactionLog
]

{ #category : 'accessing' }
SimulationState >> reactionLog: anObject [

	reactionLog := anObject
]

{ #category : 'system changes' }
SimulationState >> registerObserver: aClient [

self observers add:aClient
]

{ #category : 'initialization' }
SimulationState >> removeFleet: aFleet [
    allFleets remove: aFleet ifAbsent: [ nil ].
    ^ self.

]

{ #category : 'resolution' }
SimulationState >> resolveEngagements [
    engagementMode = #droneLevel
        ifTrue: [ ^ self resolveEngagementsDroneLevel ].
    engagementMode = #clusterLevel
        ifTrue: [ ^ self resolveEngagementsClusterLevel ].
    ^ self
]

{ #category : 'resolution' }
SimulationState >> resolveEngagementsClusterLevel [
    "Macro engagements between clusters"
    allFleets do: [:fleet |
        fleet alliedClusters do:[:anAlliedCluster| 
                fleet hostileClusters do:[:anHostileCluster| 
                    (self areInProximity: anAlliedCluster and: anHostileCluster)
                        ifTrue: [
                            | allyPower hostilePower winner loser | self halt. 
                            allyPower := anAlliedCluster capabilities sum.
                            hostilePower := anHostileCluster capabilities sum.

                            (allyPower >= hostilePower)
                                ifTrue: [ winner := anAlliedCluster. loser := anHostileCluster ]
                                ifFalse: [ winner := anHostileCluster. loser := anAlliedCluster ].

                            loser destroy.
                            reactionLog add: 'Cluster-level engagement: ', 
                                winner clusterId asString, 
                                ' neutralized ', loser clusterId asString,
                                ' at time ', time asString.
                        ].
                ].
            ].
        ].
     
    ^ self
]

{ #category : 'resolution' }
SimulationState >> resolveEngagementsDroneLevel [

"Tactical view"
    | hostiles allies |
    hostiles := self allHostileDrones select: [:h | h isDestroyed not].
    allies := self allAlliedDrones select: [:a | a isDestroyed not].

    "Hostile attacks"
    hostiles do: [:h |
        | target |
        target := allies detect: [:a | (h canPerceiveDrone: a)] ifNone: [nil].
        target ifNotNil: [
            | impact hits |
            impact := 8.
            hits := (Random new next) <= 0.7 ifTrue: [1] ifFalse: [0].
            target applyDamage: hits * impact.
            eventLog add: (String streamContents: [:s |
                s nextPutAll: 'Engagement: Hostile ';
                nextPutAll: h uniqueId;
                nextPutAll: ' attacked Allied ';
                nextPutAll: target uniqueId printString;
                nextPutAll: ' hits='; nextPutAll: hits asString ]).
        ].
    ].

    "Allied retaliation"
    allies do: [:a |
        | target |
        target := hostiles detect: [:h | (a canPerceiveDrone: h)] ifNone: [nil].
        target ifNotNil: [
            | impact hits |
            impact := 6.
            hits := (Random new next) <= 0.5 ifTrue: [1] ifFalse: [0].
            target applyDamage: hits * impact.
            reactionLog add: (String streamContents: [:s |
                s nextPutAll: 'Retaliation: Allied ';
                nextPutAll: a uniqueId printString;
                nextPutAll: ' attacked Hostile ';
                nextPutAll: target uniqueId;
                nextPutAll: ' hits='; nextPutAll: hits asString ]).
        ].
    ].
    ^ self
]

{ #category : 'initialization' }
SimulationState >> runSteps: n [
    "Fait avancer la simulation de n pas de temps, en enchaînant les appels à advanceStep."
    | snapshots |
    snapshots := OrderedCollection new.

    1 to: n do: [:i |
        snapshots add: self step ].

    ^ snapshots
]

{ #category : 'initialization' }
SimulationState >> setAsCurrent [
    Smalltalk at: #CurrentSimulation put: self.
    ^ self.


]

{ #category : 'initialization' }
SimulationState >> step [
    "Behaviors for standalone drones"
   |snapshot|  self allDrones do: [:d |
        d behavior ifNotNil: [
            d behavior executeFor: d atTime: time
        ]
    ].

    "Behaviors and updates for fleets/clusters"
    allFleets do: [:fleet |
        fleet clusters do: [:cluster |
            cluster updateCapabilities.
            cluster updateCoverage.
            cluster drones do: [:d |
                d behavior ifNotNil: [
                    d behavior executeFor: d atTime: time
                ]
            ]
        ]
    ].

    "Resolve engagements depending on mode"
    self resolveEngagements.

    "Advance time"
    time := time + 1.

    snapshot := Dictionary new.
    snapshot at: #time put: time.
    snapshot at: #fleets put: (self allFleets "collect: [:f | f deepCopy]").

    "4. Stocker dans steps"
    time := time + 1.
    steps size < time
        ifTrue: [ steps add: snapshot ]
        ifFalse: [ steps at: time put: snapshot ].

     
    ^ snapshot
]

{ #category : 'accessing' }
SimulationState >> steps [

	^ steps
]

{ #category : 'accessing' }
SimulationState >> steps: anObject [

	steps := anObject
]

{ #category : 'accessing' }
SimulationState >> time [

	^ time
]

{ #category : 'accessing' }
SimulationState >> time: anObject [

	time := anObject
]

{ #category : 'event processing' }
SimulationState >> updateDrone: aDrone with:consummable value: aValue [
     aDrone consumables at: consummable put:    aValue.

]

{ #category : 'event processing' }
SimulationState >> updateDrone: aDrone withPosition: aPosition [
aDrone position: aPosition.
^nil
]

{ #category : 'resolution' }
SimulationState >> useClusterLevelEngagements [
    engagementMode := #clusterLevel.
]

{ #category : 'resolution' }
SimulationState >> useDroneLevelEngagements [
    engagementMode := #droneLevel.
]

{ #category : 'accessing' }
SimulationState >> verificationFunctions [

	^ verificationFunctions
]

{ #category : 'accessing' }
SimulationState >> verificationFunctions: anObject [

	verificationFunctions := anObject
]
