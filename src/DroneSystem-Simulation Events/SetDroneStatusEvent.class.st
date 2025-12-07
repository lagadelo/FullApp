Class {
	#name : 'SetDroneStatusEvent',
	#superclass : 'SetDroneStatusOrCapabilityEvent',
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
SetDroneStatusEvent >> target [

	^ self model status
]
