Class {
	#name : 'ElectionSession',
	#superclass : 'Object',
	#instVars : [
		'cluster',
		'initiator',
		'dronesPending',
		'statusByDrone',
		'createdAt',
		'strategy'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'as yet unclassified' }
ElectionSession class >> for: aCluster initiatedBy: aDrone at: aTimestamp [
    ^ self new
        cluster: aCluster;
        initiator: aDrone;
        dronesPending: aCluster drones asSet;
        statusByDrone: Dictionary new;
        createdAt: aTimestamp;
        yourself.
]

{ #category : 'accessing' }
ElectionSession >> cluster [

	^ cluster
]

{ #category : 'accessing' }
ElectionSession >> cluster: anObject [

	cluster := anObject
]

{ #category : 'accessing' }
ElectionSession >> createdAt [

	^ createdAt
]

{ #category : 'accessing' }
ElectionSession >> createdAt: anObject [

	createdAt := anObject
]

{ #category : 'events-processing' }
ElectionSession >> defaultLeaderSelectionCriteria [
^[:a :b| a fuel > b fuel]
]

{ #category : 'events-processing' }
ElectionSession >> defaultStrategy [ 

^MaxFuelStrategy new
]

{ #category : 'accessing' }
ElectionSession >> dronesPending [

	^ dronesPending
]

{ #category : 'accessing' }
ElectionSession >> dronesPending: anObject [

	dronesPending := anObject
]

{ #category : 'accessing' }
ElectionSession >> initiator [

	^ initiator
]

{ #category : 'accessing' }
ElectionSession >> initiator: anObject [

	initiator := anObject
]

{ #category : 'testing' }
ElectionSession >> isComplete [
    ^ dronesPending isEmpty.

]

{ #category : 'events-processing' }
ElectionSession >> receiveStatusFrom: aDrone data: aStatus [
    dronesPending remove: aDrone ifAbsent: [ ].
    statusByDrone at: aDrone put: aStatus.

]

{ #category : 'events-processing' }
ElectionSession >> selectLeader [

"example

| session strategy |
strategy := BestPerceptionStrategy new.
session := ElectionSession for: cluster initiatedBy: drone at: 100.
session strategy: strategy."


    ^ self strategy selectLeaderFrom: statusByDrone.
]

{ #category : 'accessing' }
ElectionSession >> statusByDrone [

	^ statusByDrone
]

{ #category : 'accessing' }
ElectionSession >> statusByDrone: anObject [

	statusByDrone := anObject
]

{ #category : 'events-processing' }
ElectionSession >> strategy [
    ^ strategy ifNil: [ self defaultStrategy ]. "Stratégie par défaut"
]

{ #category : 'events-processing' }
ElectionSession >> strategy: aStrategy [
    strategy := aStrategy.
]
