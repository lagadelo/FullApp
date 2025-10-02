Class {
	#name : 'DetectionByClusterEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'cluster'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
DetectionByClusterEvent >> affectedEntities [
    ^ Set withAll: { #cluster }.
]
