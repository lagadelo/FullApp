Class {
	#name : 'StartLeaderElectionRequest',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'requestedByDrone',
		'cluster'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'accessing' }
StartLeaderElectionRequest >> cluster [

	^ cluster
]

{ #category : 'accessing' }
StartLeaderElectionRequest >> cluster: anObject [

	cluster := anObject
]

{ #category : 'accessing' }
StartLeaderElectionRequest >> requestedByDrone [

	^ requestedByDrone
]

{ #category : 'accessing' }
StartLeaderElectionRequest >> requestedByDrone: anObject [

	requestedByDrone := anObject
]
