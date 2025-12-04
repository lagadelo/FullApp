Class {
	#name : 'JumpInTime',
	#superclass : 'ScheduledEvent',
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'executing' }
JumpInTime >> executeOn: aSimulator [
	"force refresh every timeStep"

	aSimulator scheduleEvent: (self class new
			 timestamp: self timestamp + aSimulator timeStep;
			 yourself)
]
