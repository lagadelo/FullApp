Class {
	#name : 'SetDroneCapabilityEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'statusData'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
SetDroneCapabilityEvent >> affectedEntities [
    ^ Set with: self model
]

{ #category : 'executing' }
SetDroneCapabilityEvent >> executeOn: aSimulator [
    self model capabilities set:statusData key to: statusData value
]
