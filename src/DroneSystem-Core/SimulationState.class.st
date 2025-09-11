Class {
	#name : 'SimulationState',
	#superclass : 'Object',
	#instVars : [
		'drones',
		'clusters',
		'allFleets',
		'hostileFleets',
		'missionHistory',
		'eventLog',
		'reactionLog',
		'verificationFunctions',
		'time',
		'engagementMode'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'initialization' }
SimulationState >> addDrone: d [
    drones add: d.
    ^ self.
]

{ #category : 'initialization' }
SimulationState >> addFleet: aFleet [
    allFleets add: aFleet.
    ^ self.
]

{ #category : 'initialization' }
SimulationState >> allAlliedDrones [
    | allies |
    allies := OrderedCollection new.
    allFleets do: [:f | f isHostile ifFalse: [ allies addAll: (f clusters collectMany: [:c | c drones ]) ] ].
    ^ allies.

]

{ #category : 'accessing' }
SimulationState >> allFleets [

	^ allFleets
]

{ #category : 'accessing' }
SimulationState >> allFleets: anObject [

	allFleets := anObject
]

{ #category : 'initialization' }
SimulationState >> allHostileDrones [
    | hostiles |
    hostiles := OrderedCollection new.
    allFleets do: [:f | f isHostile ifTrue: [ hostiles addAll: (f clusters collectMany: [:c | c drones ]) ] ].
    ^ hostiles.
]

{ #category : 'initialization' }
SimulationState >> areInProximity: clusterA and: clusterB [
    "Simple threshold in km, refine later with Haversine."
    | distance |
    distance := clusterA position distanceTo: clusterB position.
    ^ distance < 50.0
]

{ #category : 'accessing' }
SimulationState >> clusters [

	^ clusters
]

{ #category : 'accessing' }
SimulationState >> clusters: anObject [

	clusters := anObject
]

{ #category : 'initialization' }
SimulationState >> current [
    ^ Smalltalk at: #CurrentSimulation ifAbsent: [ nil ].

]

{ #category : 'initialization' }
SimulationState >> deepCopy [
    | copy droneMap clusterMap fleetMap newDrones newClusters newFleets |
    copy := SimulationState new initialize.
    "Clone standalone drones"
    droneMap := Dictionary new.
    newDrones := OrderedCollection new.
    drones do: [:d |
        | cd |
        cd := d deepCopy.
        droneMap at: d put: cd.
        newDrones add: cd.
    ].
    copy drones: newDrones ifResponds: [] ifFalse: [].
    "Clone clusters and remap drone references"
    clusterMap := Dictionary new.
    newClusters := OrderedCollection new.
    clusters do: [:c |
        | cc mapping newClusterDrones |
        cc := DroneCluster new.
        cc clusterId: c clusterId ifResponds: [] ifFalse: [].
        mapping := Dictionary new.
        newClusterDrones := OrderedCollection new.
        c drones do: [:d |
            | cd |
            cd := (droneMap at: d) ifAbsent: [ d deepCopy ].
            mapping at: d put: cd.
            newClusterDrones add: cd.
        ].
        cc drones: newClusterDrones "ifResponds: [] ifFalse: []".
        cc updateCapabilities.
        cc updateCoverage.
        clusterMap at: c put: cc.
        newClusters add: cc.
    ].
    copy clusters: newClusters ifResponds: [] ifFalse: [].
    "Clone fleets and remap cluster references"
    fleetMap := Dictionary new.
    newFleets := OrderedCollection new.
    allFleets do: [:f |
        | nf |
        nf := DroneFleet new.
        nf fleetId: f fleetId "ifResponds: [] ifFalse: []".
        nf isHostile: f isHostile "ifResponds: [] ifFalse: []".
        nf name: f name "ifResponds: [] ifFalse: []".
        nf clusters: (f clusters collect: [:c | (clusterMap at: c) ifAbsent: [ c deepCopy ] ])" ifResponds: [] ifFalse: []".
        newFleets add: nf.
    ].
    copy allFleets: newFleets "ifResponds: [] ifFalse: []".
    "Copy time and logs"
    copy time: time i"fResponds: [] ifFalse: []".
    copy missionHistory: missionHistory copy "ifResponds: [] ifFalse: []".
    copy eventLog: eventLog copy "ifResponds: [] ifFalse: []".
    copy reactionLog: reactionLog copy "ifResponds: [] ifFalse: []".
    copy verificationFunctions: (verificationFunctions collect: [:f | f]) "ifResponds: [] ifFalse: []".
    ^ copy.
]

{ #category : 'accessing' }
SimulationState >> drones [

	^ drones
]

{ #category : 'accessing' }
SimulationState >> drones: anObject [

	drones := anObject
]

{ #category : 'accessing' }
SimulationState >> engagementMode [

	^ engagementMode
]

{ #category : 'accessing' }
SimulationState >> engagementMode: anObject [

	engagementMode := anObject
]

{ #category : 'accessing' }
SimulationState >> eventLog [

	^ eventLog
]

{ #category : 'accessing' }
SimulationState >> eventLog: anObject [

	eventLog := anObject
]

{ #category : 'accessing' }
SimulationState >> hostileFleets [

	^ hostileFleets
]

{ #category : 'accessing' }
SimulationState >> hostileFleets: anObject [

	hostileFleets := anObject
]

{ #category : 'initialization' }
SimulationState >> initialize [
    drones := OrderedCollection new.
    clusters := OrderedCollection new.
    allFleets := OrderedCollection new.
    hostileFleets := OrderedCollection new.
    missionHistory := OrderedCollection new.
    eventLog := OrderedCollection new.
    reactionLog := OrderedCollection new.
    verificationFunctions := OrderedCollection new.
    time := 0.
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
SimulationState >> reactionLog [

	^ reactionLog
]

{ #category : 'accessing' }
SimulationState >> reactionLog: anObject [

	reactionLog := anObject
]

{ #category : 'initialization' }
SimulationState >> removeFleet: aFleet [
    allFleets remove: aFleet ifAbsent: [ nil ].
    ^ self.

]

{ #category : 'initialization' }
SimulationState >> resolveEngagements [
    engagementMode = #droneLevel
        ifTrue: [ ^ self resolveEngagementsDroneLevel ].
    engagementMode = #clusterLevel
        ifTrue: [ ^ self resolveEngagementsClusterLevel ].
    ^ self
]

{ #category : 'initialization' }
SimulationState >> resolveEngagementsClusterLevel [
    "Macro engagements between clusters"
    allFleets do: [:fleet |
        fleet clusters do: [:allyCluster |
            self hostileFleets do: [:hostileFleet |
                hostileFleet clusters do: [:hostileCluster |
                    (self areInProximity: allyCluster and: hostileCluster)
                        ifTrue: [
                            | allyPower hostilePower winner loser |
                            allyPower := allyCluster capabilities sum.
                            hostilePower := hostileCluster capabilities sum.

                            (allyPower >= hostilePower)
                                ifTrue: [ winner := allyCluster. loser := hostileCluster ]
                                ifFalse: [ winner := hostileCluster. loser := allyCluster ].

                            loser isOperational: false.
                            reactionLog add: 'Cluster-level engagement: ', 
                                winner clusterId asString, 
                                ' neutralized ', loser clusterId asString,
                                ' at time ', time asString.
                        ].
                ].
            ].
        ].
    ].
    ^ self
]

{ #category : 'initialization' }
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
                nextPutAll: target uniqueId;
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
                nextPutAll: a uniqueId;
                nextPutAll: ' attacked Hostile ';
                nextPutAll: target uniqueId;
                nextPutAll: ' hits='; nextPutAll: hits asString ]).
        ].
    ].
    ^ self
]

{ #category : 'initialization' }
SimulationState >> setAsCurrent [
    Smalltalk at: #CurrentSimulation put: self.
    ^ self.


]

{ #category : 'initialization' }
SimulationState >> step [
    "Behaviors for standalone drones"
    drones do: [:d |
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

    ^ self
]

{ #category : 'accessing' }
SimulationState >> time [

	^ time
]

{ #category : 'accessing' }
SimulationState >> time: anObject [

	time := anObject
]

{ #category : 'initialization' }
SimulationState >> useClusterLevelEngagements [
    engagementMode := #clusterLevel.
]

{ #category : 'initialization' }
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
