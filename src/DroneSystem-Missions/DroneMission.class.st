Class {
	#name : 'DroneMission',
	#superclass : 'Object',
	#instVars : [
		'assignedDrone',
		'status'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'accessing' }
DroneMission >> assignedDrone [

	^ assignedDrone
]

{ #category : 'accessing' }
DroneMission >> assignedDrone: anObject [

	assignedDrone := anObject
]

{ #category : 'accessing' }
DroneMission >> status [

	^ status
]

{ #category : 'accessing' }
DroneMission >> status: anObject [

	status := anObject
]
