Class {
	#name : 'SurveillanceMission',
	#superclass : 'ZoneBasedMission',
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'strategy' }
SurveillanceMission >> detectIntrusionAt: aPoint timestamp: aTimestamp simulator: aSimulator [
    | strategy responseEvents |

    Transcript
        show: '🚨 Mission detected intrusion at ', aPoint printString, ' at t=', aTimestamp printString; cr.

    "1. Appliquer une stratégie de réponse"
    strategy := self responseStrategy.
    responseEvents := strategy generateResponseEventsFor: self threatAt: aPoint timestamp: aTimestamp.

    "2. Replanifier les événements futurs"
    responseEvents do: [:event |
        aSimulator rescheduleFor: event drone with: event after: (Set with: self)
    ].
]

{ #category : 'characterization' }
SurveillanceMission >> isSurveillanceMission [ 

^true
]

{ #category : 'strategy' }
SurveillanceMission >> nextWaypointFor: drone [

	| i j r weight |
	r := Random new.
	i := (r next * waypoints size rounded min: 1) max: waypoints size.
	[ j := (r next * waypoints size rounded min: 1) max: waypoints size ]
		doWhileTrue: [ j = i ].
	weight := r new.
	^ (self wayPoints at: i) * weight
	  + ((self wayPoints at: j) * (1 - weight))
]

{ #category : 'strategy' }
SurveillanceMission >> nextWaypointForDrone: drone currentWaypoint: currentWaypoint [
    |   currentIndex nextIndex |
 
    currentIndex := waypoints indexOf: currentWaypoint ifAbsent: [0].

    nextIndex := (currentIndex + 1) \\ waypoints size.
    nextIndex = 0 ifTrue: [ nextIndex := waypoints size ].

    ^ waypoints at: nextIndex.
]

{ #category : 'strategy' }
SurveillanceMission >> planNextPatrolFor: drone at: timestamp in: simulator [
    |   currentWaypoint nextWaypoint moveEvent |

    "Récupération des waypoints de la mission"
    

    "Position actuelle du drone sur la boucle des waypoints"
    currentWaypoint := drone waypoint ifNil: [ waypoints first ].

    "Calcul du prochain waypoint dans la boucle"
    nextWaypoint := self nextWaypointForDrone: drone currentWaypoint: currentWaypoint.

    "Création de l'événement de déplacement vers le prochain waypoint"
    moveEvent := MoveToWaypointEvent new
        timestamp: timestamp;
        drone: drone;
        destination: nextWaypoint;
        yourself.

    "Planification de l'événement dans le simulateur"
    simulator scheduleEvent: moveEvent after: (Set with: self).

]

{ #category : 'strategy' }
SurveillanceMission >> responseStrategy [
    ^ HybridStrategy new.

]
