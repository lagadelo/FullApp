Class {
	#name : 'SetDroneCapabilityEvent',
	#superclass : 'SetDroneStatusOrCapabilityEvent',
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'accessing' }
SetDroneCapabilityEvent >> target [

	^ self model capabilities 
]
