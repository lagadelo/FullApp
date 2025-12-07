Class {
	#name : 'MoveToWaypointEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'wayPoint',
		'speed',
		'startPoint'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
MoveToWaypointEvent class >> for: aDrone to: aWaypoint at: aTimestamp [
    ^ self new
        timestamp: aTimestamp;
        drone: aDrone;
        wayPoint: aWaypoint;
        yourself.

]

{ #category : 'as yet unclassified' }
MoveToWaypointEvent class >> for: aDrone to: aWaypoint speed: aSpeed at: aTimestamp [

	^ self new
		  timestamp: aTimestamp;
		  drone: aDrone;
		  wayPoint: aWaypoint;
		  speed: aSpeed;
		  yourself
]

{ #category : 'as yet unclassified' }
MoveToWaypointEvent >> affectedEntities [
    ^ Set withAll: { #cluster. #toDrone }.
]

{ #category : 'executing' }
MoveToWaypointEvent >> executeOn: simulator [

	| arrivalEvent directionChange |
	"evt should serve as a dependency when breaking down a global move into sub moveStepEvents"
	self startPoint. "Force lazy initialization"

	directionChange := SetDroneStatusEvent new
		                   timestamp: self timestamp;
		                   model: self model;
		                   set: #orientation
		                   to: (self startPoint bearingTo: wayPoint);
		                   yourself.


	duration := ((self startPoint distanceTo: wayPoint) / self speed)
		            ceiling.

	arrivalEvent := WayPointReachedEvent new
		                initiator: self;
		                timestamp: self timestamp + duration;
		                model: self model;
		                wayPoint: wayPoint;
		                yourself.
	simulator scheduleEvent: directionChange after: (Set with: self).
	^ simulator scheduleEvent: arrivalEvent after: (Set with: self) "directionChange with:"
]

{ #category : 'accessing' }
MoveToWaypointEvent >> speed [

	speed ifNil: [ speed := self model status get: #speed ].

	^ speed
]

{ #category : 'accessing' }
MoveToWaypointEvent >> speed: anObject [

	speed := anObject
]

{ #category : 'accessing' }
MoveToWaypointEvent >> startPoint [

	startPoint ifNil: [ startPoint := self model status get: #position ].
	^ startPoint
]

{ #category : 'accessing' }
MoveToWaypointEvent >> wayPoint [

	^ wayPoint
]

{ #category : 'accessing' }
MoveToWaypointEvent >> wayPoint: anObject [

	wayPoint := anObject
]
