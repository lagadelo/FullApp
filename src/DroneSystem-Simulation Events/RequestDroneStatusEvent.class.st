Class {
	#name : 'RequestDroneStatusEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'toDrone',
		'cluster'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
RequestDroneStatusEvent >> affectedEntities [
    ^ Set withAll: { cluster. toDrone }.
]

{ #category : 'accessing' }
RequestDroneStatusEvent >> cluster [

	^ cluster
]

{ #category : 'accessing' }
RequestDroneStatusEvent >> cluster: anObject [

	cluster := anObject
]

{ #category : 'executing' }
RequestDroneStatusEvent >> executeOn: aSimulator [
    aSimulator handleRequestDroneStatus: self.
]

{ #category : 'accessing' }
RequestDroneStatusEvent >> toDrone [

	^ toDrone
]

{ #category : 'accessing' }
RequestDroneStatusEvent >> toDrone: anObject [

	toDrone := anObject
]
