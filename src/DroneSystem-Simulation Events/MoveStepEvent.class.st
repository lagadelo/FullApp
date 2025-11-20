Class {
	#name : 'MoveStepEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'drone',
		'speed',
		'wayPoint'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'instance creation' }
MoveStepEvent class >> drone: aDrone wayPoint: aWaypoint speed: aSpeed [

	^ self new
		  drone: aDrone;
		  wayPoint: aWaypoint;
		  speed: aSpeed;
		  yourself
]

{ #category : 'accessing' }
MoveStepEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
MoveStepEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'accessing' }
MoveStepEvent >> executeOn: simulator [

	| distanceRemaining direction distanceToMove ratio evt |
	"evt should serve as a dependency when breaking down a global move into sub moveStepEvents"
	distanceRemaining := drone position distanceTo: wayPoint.
	direction := (wayPoint - drone position) normalize.
	distanceToMove := speed * simulator timeStep.
	distanceRemaining = 0 ifTrue:[ ratio :=2 "Ca ne devrait jamais arriver"] ifFalse:[
	ratio := distanceToMove / distanceRemaining.].
	self duration: simulator timeStep. "*ratio"
	"Calcul de nouvelle position"
	ratio > 1
		ifTrue: [
				drone position: wayPoint.
		 
	^ simulator scheduleEvent: (WayPointReachedEvent new
		                timestamp:  self timestamp +1 ;
		                drone: drone;
		                wayPoint: wayPoint;
		                yourself) after: (Set with: self) ]
		ifFalse: [
				drone position:
					drone position + ((wayPoint - drone position) * ratio).
				^ simulator
					  scheduleEvent: (evt := self class new
							          timestamp: self timestamp + simulator timeStep;
							          drone: drone;
							          wayPoint: wayPoint;
							          speed: speed;
							          yourself)
					  after: (Set with: self) ]
]

{ #category : 'printing' }
MoveStepEvent >> printOn: aStream [
aStream nextPutAll: 'Drone ', drone id printString,' moves towards ',self wayPoint printString,' at speed ', self speed printString,'  ... reached :', drone position printString;cr
]

{ #category : 'accessing' }
MoveStepEvent >> speed [

	^ speed
]

{ #category : 'accessing' }
MoveStepEvent >> speed: anObject [

	speed := anObject
]

{ #category : 'accessing' }
MoveStepEvent >> wayPoint [

	^ wayPoint
]

{ #category : 'accessing' }
MoveStepEvent >> wayPoint: anObject [

	wayPoint := anObject
]
