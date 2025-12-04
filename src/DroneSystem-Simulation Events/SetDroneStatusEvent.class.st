Class {
	#name : 'SetDroneStatusEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'capabilityData'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
SetDroneStatusEvent >> affectedEntities [
    ^ Set with: self model
]

{ #category : 'as yet unclassified' }
SetDroneStatusEvent >> executeOn: aSimulator [
    self model capabilities set:capabilityData key to: capabilityData value
]
