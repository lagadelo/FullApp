Class {
	#name : 'DroneCluster',
	#superclass : 'Object',
	#instVars : [
		'drones',
		'clusterId',
		'coverage',
		'capabilities',
		'currentMission'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'accessing' }
DroneCluster >> capabilities [

	^ capabilities
]

{ #category : 'accessing' }
DroneCluster >> capabilities: anObject [

	capabilities := anObject
]

{ #category : 'initialization' }
DroneCluster >> clusterCenter [
    | lats lons |
    coverage isNil ifTrue: [ ^ Point x: 0 y: 0 ].
    lats := coverage collect: [:p | p at: 1].
    lons := coverage collect: [:p | p at: 2].
    ^ Point x: (lons sum / lons size) y: (lats sum / lats size).
]

{ #category : 'accessing' }
DroneCluster >> clusterId [

	^ clusterId
]

{ #category : 'accessing' }
DroneCluster >> clusterId: anObject [

	clusterId := anObject
]

{ #category : 'accessing' }
DroneCluster >> coverage [

	^ coverage
]

{ #category : 'accessing' }
DroneCluster >> coverage: anObject [

	coverage := anObject
]

{ #category : 'accessing' }
DroneCluster >> currentMission [

	^ currentMission
]

{ #category : 'accessing' }
DroneCluster >> currentMission: anObject [

	currentMission := anObject
]

{ #category : 'accessing' }
DroneCluster >> deepCopy [
    | copy mapping newDrones |
    copy := DroneCluster new.
    copy clusterId: clusterId ifResponds: [] ifFalse: [].
    "Create fresh drone copies and keep mapping"
    mapping := Dictionary new.
    newDrones := OrderedCollection new.
    drones do: [:d |
        | cd |
        cd := d deepCopy.
        mapping at: d put: cd.
        newDrones add: cd.
    ].
    copy drones: newDrones "ifResponds: [] ifFalse: []".
    copy updateCapabilities.
    copy updateCoverage.
    copy currentMission: (currentMission ifNotNil: [ currentMission deepCopy ] ifNil: [ nil ]).
    ^ copy.
]

{ #category : 'accessing' }
DroneCluster >> drones [

	^ drones
]

{ #category : 'accessing' }
DroneCluster >> drones: anObject [

	drones := anObject
]

{ #category : 'initialization' }
DroneCluster >> initializeWithDrones: droneList clusterId: anId [
    drones := droneList.
    clusterId := anId.
    currentMission := nil.
    self updateCapabilities.
    self updateCoverage.
    ^ self.

]

{ #category : 'initialization' }
DroneCluster >> isOperational [
    ^ drones anySatisfy: [:d | d isDestroyed not].
]

{ #category : 'initialization' }
DroneCluster >> removeDestroyedDrones [
    drones := drones reject: [:d | d isDestroyed ].
    self updateCapabilities.
    self updateCoverage.
    ^ self.


]

{ #category : 'initialization' }
DroneCluster >> updateCapabilities [
    capabilities := Dictionary new.
    capabilities at: #fuel put: (drones sum: [:d | d isDestroyed ifFalse: [d fuel] ifTrue: [0]]).
    capabilities at: #perceptionRange put: (drones collect: [:d | d isDestroyed ifFalse: [d perceptionRange] ifTrue: [0]]) max.
    capabilities at: #munitions put: (drones sum: [:d | d isDestroyed ifFalse: [ (d consumables values sum) ] ifTrue: [0]]).
    ^ self.
]

{ #category : 'initialization' }
DroneCluster >> updateCoverage [
    | activePositions |
    activePositions := (drones select: [:d | d isDestroyed not]) collect: [:d | { d latitude. d longitude } ].
    coverage := (activePositions isEmpty ifTrue: [ #() ] ifFalse: [ ConvexHullCalculator new computeHullFrom: activePositions ]).
    ^ coverage.

]
