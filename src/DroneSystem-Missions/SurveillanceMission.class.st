Class {
	#name : 'SurveillanceMission',
	#superclass : 'ZoneBasedMission',
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'characterization' }
SurveillanceMission >> computePositions [

	| drones nb extra |
	drones := self model drones.
wayPoints := OrderedCollection new.

	nb := (drones size / polygon size - 1) floor. " how many full rounds"
	extra := drones size - (nb + 1 * polygon size). "which vertices receives an extra drone"
	1 to: polygon size do: [ :i |
			| src dest nbPoints |
			src := polygon at: i.
			dest := polygon at: (i + 1 \\ polygon size max: 1).
 
			nbPoints := i <= extra
				            ifTrue: [ nb + 1 ]
				            ifFalse: [ nb ].
			1 to: nbPoints do: [ :j |
					wayPoints add:
						src   * (nbPoints +1 - j) + (dest   * j)
						/ (nbPoints + 1) ] ]
]

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
SurveillanceMission >> events [

	| drones mobilized |
	drones := self model drones.
	mobilized := drones size > self polygon size
		             ifTrue: [
		             (1 to: self polygon size) collect: [ :i | drones at: i ] ]
		             ifFalse: [ drones ].
	^ (1 to: mobilized size) collect: [ :i |
			  MoveToWaypointEvent new
				  model: (drones at: i);
				  wayPoint: (self polygon at: i);
				  speed: 20000 / 3600;
				  yourself "20km/h" ]
]

{ #category : 'characterization' }
SurveillanceMission >> isSurveillanceMission [ 

^true
]

{ #category : 'strategy' }
SurveillanceMission >> nextWayPointFor: drone [

	| pos potentialPos |
	self isActive ifFalse:[^nil].
	pos := self model drones collect: [ :b | b position ].
	potentialPos := self polygon reject: [ :a | pos includes: a ].
	potentialPos ifEmpty: [ ^ nil ].
	^ potentialPos at: ((Random new next * potentialPos size) rounded max: 1)
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
