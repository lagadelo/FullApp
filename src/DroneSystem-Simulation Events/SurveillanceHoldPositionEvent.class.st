Class {
	#name : 'SurveillanceHoldPositionEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'drone',
		'holdDuration',
		'waypoint'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
SurveillanceHoldPositionEvent class >> for: aDrone atWaypoint: aWaypoint duration: aDuration timestamp: aTimestamp [
    ^ self new
        timestamp: aTimestamp;
        drone: aDrone;
        waypoint: aWaypoint;
        holdDuration: aDuration;
        yourself.
]

{ #category : 'as yet unclassified' }
SurveillanceHoldPositionEvent >> affectedEntities [
    ^ Set with: drone.
]

{ #category : 'accessing' }
SurveillanceHoldPositionEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
SurveillanceHoldPositionEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'as yet unclassified' }
SurveillanceHoldPositionEvent >> duration [
    ^ holdDuration ifNil: [ 10 ]. "Valeur par défaut"
]

{ #category : 'as yet unclassified' }
SurveillanceHoldPositionEvent >> executeOn: simulator [
    Transcript
        show: 'Drone ', drone id printString,
              ' holds position at waypoint ', waypoint printString,
              ' from t=', self timestamp printString,
              ' for duration ', self duration printString;
        cr.

    drone state: #holding.
    drone position: waypoint.

    "Planifier reprise de patrouille après hold"
    simulator scheduleEvent: (
        ResumePatrolEvent for: drone at: self timestamp + self duration
    ) after: (Set with: self).
]

{ #category : 'accessing' }
SurveillanceHoldPositionEvent >> holdDuration [

	^ holdDuration
]

{ #category : 'accessing' }
SurveillanceHoldPositionEvent >> holdDuration: anObject [

	holdDuration := anObject
]

{ #category : 'accessing' }
SurveillanceHoldPositionEvent >> waypoint [

	^ waypoint
]

{ #category : 'accessing' }
SurveillanceHoldPositionEvent >> waypoint: anObject [

	waypoint := anObject
]
