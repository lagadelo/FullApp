Class {
	#name : 'WayPointReachedEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'drone',
		'wayPoint',
		'initiator'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
WayPointReachedEvent >> affectedEntities [
    ^ Set with: drone.
]

{ #category : 'accessing' }
WayPointReachedEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
WayPointReachedEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'execution' }
WayPointReachedEvent >> executeOn: aSimulator [

	self model position: self wayPoint.
	aSimulator
		scheduleEvent:
		(ResumePatrolEvent for: self model at: self timestamp)
		after: (Set with: self).
	aSimulator synchonizeAllEvents: WayPointReachedEvent after: timestamp
]

{ #category : 'accessing' }
WayPointReachedEvent >> initiator [

	^ initiator
]

{ #category : 'accessing' }
WayPointReachedEvent >> initiator: aMoveEvent [

initiator := aMoveEvent
]

{ #category : 'printing' }
WayPointReachedEvent >> printOn:aStream [

aStream nextPutAll: self timestamp printString,': Drone ', self model id printString, ' reached ', wayPoint printString;cr  
]

{ #category : 'accessing' }
WayPointReachedEvent >> synchronizeAt: aTimestamp [

	| distance totalTime remainingTime |
	" my initiator is a moveEvent. I have to recompute my model's current position at a given time."
	distance := wayPoint distanceTo: self initiator startPoint.
	totalTime := distance / self initiator speed.

	remainingTime := self timestamp - aTimestamp.
	self model position: wayPoint
		-
		( (wayPoint - self initiator startPoint)* (remainingTime / totalTime) )
]

{ #category : 'accessing' }
WayPointReachedEvent >> wayPoint [

	^ wayPoint
]

{ #category : 'accessing' }
WayPointReachedEvent >> wayPoint: anObject [

	wayPoint := anObject
]
