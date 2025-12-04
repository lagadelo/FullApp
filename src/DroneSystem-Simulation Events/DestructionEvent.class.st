Class {
	#name : 'DestructionEvent',
	#superclass : 'ScheduledEvent',
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'executing' }
DestructionEvent >> executeOn: simulator [

	"No more capabilities"
	self model set: #state to:#destroyed.
	"No future"""
	simulator removeAllEventsFor: self model after: self timestamp
]
