Class {
	#name : 'RequestDroneCapabilitiesEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'toDrone',
		'cluster'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'executing' }
RequestDroneCapabilitiesEvent >> affectedEntities [
    ^ Set with: self model
]

{ #category : 'executing' }
RequestDroneCapabilitiesEvent >> executeOn: aSimulator [
    ^self model capabilities
]
