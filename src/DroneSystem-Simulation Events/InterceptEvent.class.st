Class {
	#name : 'InterceptEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'drone',
		'targetPosition'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
InterceptEvent >> affectedEntities [
    ^ Set with: drone.
]

{ #category : 'accessing' }
InterceptEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
InterceptEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'as yet unclassified' }
InterceptEvent >> duration [
    ^ (drone position distanceTo: targetPosition) / drone speed.
]

{ #category : 'as yet unclassified' }
InterceptEvent >> executeOn: simulator [
    | reach |
    reach := WayPointReachedEvent new
        timestamp: self endTimestamp;
        drone: drone;
        wayPoint: targetPosition;
        yourself.
    simulator scheduleEvent: reach after: (Set with: self).
]

{ #category : 'accessing' }
InterceptEvent >> targetPosition [

	^ targetPosition
]

{ #category : 'accessing' }
InterceptEvent >> targetPosition: anObject [

	targetPosition := anObject
]
