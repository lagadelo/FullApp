Class {
	#name : 'MissionStartEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'mission'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'executing' }
MissionStartEvent >> executeOn: simulator [

	self model events do: [ :a |  
		simulator scheduleEvent: a at: self timestamp after: (Set with: self) ]
]
