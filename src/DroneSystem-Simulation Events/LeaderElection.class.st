Class {
	#name : 'LeaderElection',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'cluster'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'accessing' }
LeaderElection >> cluster [

	^ cluster
]

{ #category : 'accessing' }
LeaderElection >> cluster: anObject [

	cluster := anObject
]
