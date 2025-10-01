Class {
	#name : 'CompleteLeaderElectionEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'cluster',
		'electedDrone'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
CompleteLeaderElectionEvent >> affectedEntities [
    ^ Set withAll: { cluster. electedDrone }.
]

{ #category : 'accessing' }
CompleteLeaderElectionEvent >> cluster [

	^ cluster
]

{ #category : 'accessing' }
CompleteLeaderElectionEvent >> cluster: anObject [

	cluster := anObject
]

{ #category : 'accessing' }
CompleteLeaderElectionEvent >> electedDrone [

	^ electedDrone
]

{ #category : 'accessing' }
CompleteLeaderElectionEvent >> electedDrone: anObject [

	electedDrone := anObject
]

{ #category : 'as yet unclassified' }
CompleteLeaderElectionEvent >> executeOn: aSimulator [
    aSimulator handleCompleteLeaderElection: self.
]
