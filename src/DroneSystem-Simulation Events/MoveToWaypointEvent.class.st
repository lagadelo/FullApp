Class {
	#name : 'MoveToWaypointEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'drone',
		'wayPoint',
		'speed'
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

{ #category : 'accessing' }
MoveToWaypointEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
MoveToWaypointEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'executing' }
MoveToWaypointEvent >> execute [
    drone moveTo: wayPoint.
    (drone hasMoreWaypoints) ifTrue: [
        | nextWaypoint timeToReach |
        nextWaypoint := drone nextWaypoint.
        timeToReach := (drone distanceTo: nextWaypoint) / drone speed.
        simulationState scheduler scheduleEvent: (
            self class 
                for: drone
                to: nextWaypoint
                at: simulationState currentTime + timeToReach)
    ].

]

{ #category : 'executing' }
MoveToWaypointEvent >> executeOn: simulator [

	| arrivalEvent |
	"evt should serve as a dependency when breaking down a global move into sub moveStepEvents"
	drone position distanceTo: wayPoint.
	duration := ((drone position distanceTo: wayPoint) /   speed)
		            ceiling.

	arrivalEvent := WayPointReachedEvent new
		                timestamp: self endTimestamp;
		                drone: drone;
		                wayPoint: wayPoint;
		                yourself.
	^ simulator scheduleEvent: arrivalEvent after: (Set with: self)
]

{ #category : 'accessing' }
MoveToWaypointEvent >> speed [

	^ speed
]

{ #category : 'accessing' }
MoveToWaypointEvent >> speed: anObject [

	speed := anObject
]

{ #category : 'accessing' }
MoveToWaypointEvent >> wayPoint [

	^ wayPoint
]

{ #category : 'accessing' }
MoveToWaypointEvent >> wayPoint: anObject [

	wayPoint := anObject
]
