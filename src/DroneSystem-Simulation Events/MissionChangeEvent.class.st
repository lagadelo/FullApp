Class {
	#name : 'MissionChangeEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'cluster',
		'newMission'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
MissionChangeEvent >> affectedEntities [
    ^ Set withAll: { cluster }.
]

{ #category : 'accessing' }
MissionChangeEvent >> cluster [

	^ cluster
]

{ #category : 'accessing' }
MissionChangeEvent >> cluster: anObject [

	cluster := anObject
]

{ #category : 'accessing' }
MissionChangeEvent >> newMission [

	^ newMission
]

{ #category : 'accessing' }
MissionChangeEvent >> newMission: anObject [

	newMission := anObject
]
