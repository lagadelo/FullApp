Class {
	#name : 'LeaderElectionRequest',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'fromDrone',
		'cluster'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
LeaderElectionRequest >> affectedEntities [
    ^ Set with: cluster.
]

{ #category : 'accessing' }
LeaderElectionRequest >> cluster [

	^ cluster
]

{ #category : 'accessing' }
LeaderElectionRequest >> cluster: anObject [

	cluster := anObject
]

{ #category : 'as yet unclassified' }
LeaderElectionRequest >> executeOn: aSimulator [
    aSimulator handleStartLeaderElection: self.
]

{ #category : 'accessing' }
LeaderElectionRequest >> fromDrone [

	^ fromDrone
]

{ #category : 'accessing' }
LeaderElectionRequest >> fromDrone: anObject [

	fromDrone := anObject
]
