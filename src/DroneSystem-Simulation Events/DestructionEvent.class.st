Class {
	#name : 'DestructionEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'drone',
		'targetPosition'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'accessing' }
DestructionEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
DestructionEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'executing' }
DestructionEvent >> executeOn: simulator [

	"No more capabilities"
	self drone destroy.
	"No future"""
	simulator removeAllEventsFor: self drone after: self timestamp
]

{ #category : 'accessing' }
DestructionEvent >> targetPosition [

	^ targetPosition
]

{ #category : 'accessing' }
DestructionEvent >> targetPosition: anObject [

	targetPosition := anObject
]
