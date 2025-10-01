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
    | distanceRemaining direction   distanceToMove newPos |

    distanceRemaining := drone position distanceTo: wayPoint .
    direction := (wayPoint - drone position) normalize.
    distanceToMove := (speed  ) * simulator timeStep.

    "Calcul de nouvelle position"
    newPos := drone position + (direction * (distanceToMove min: distanceRemaining)).

    drone position: newPos.

    "Détection proximité"
    (simulator entitiesInPerceptionRangeOf: drone) do: [:entity |
        simulator scheduleEvent: (
            "IntrusionDetectedEvent"DetectionEvent new
                timestamp: self timestamp;
                drone: drone;
                intruder: entity  ;
                yourself
        ) after: (Set with: self)
    ].

    "Planifier prochaine étape si pas encore arrivé"
    distanceRemaining > distanceToMove ifTrue: [
        simulator scheduleEvent: (
            self class new
                timestamp: self timestamp + simulator timeStep;
                drone: drone;
                destination: wayPoint ;
                speed: speed;
                yourself
        ) after: (Set with: self)
    ].
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
