Class {
	#name : 'AnnounceNewLeaderEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'cluster',
		'newLeader',
		'toDrone'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
AnnounceNewLeaderEvent >> affectedEntities [
    ^ Set withAll: { cluster. toDrone }.

]

{ #category : 'accessing' }
AnnounceNewLeaderEvent >> cluster [

	^ cluster
]

{ #category : 'accessing' }
AnnounceNewLeaderEvent >> cluster: anObject [

	cluster := anObject
]

{ #category : 'as yet unclassified' }
AnnounceNewLeaderEvent >> executeOn: aSimulator [
    aSimulator handleAnnounceNewLeader: self.
]

{ #category : 'accessing' }
AnnounceNewLeaderEvent >> newLeader [

	^ newLeader
]

{ #category : 'accessing' }
AnnounceNewLeaderEvent >> newLeader: anObject [

	newLeader := anObject
]

{ #category : 'accessing' }
AnnounceNewLeaderEvent >> toDrone [

	^ toDrone
]

{ #category : 'accessing' }
AnnounceNewLeaderEvent >> toDrone: anObject [

	toDrone := anObject
]
