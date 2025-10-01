Class {
	#name : 'DroneSimulator',
	#superclass : 'Object',
	#instVars : [
		'model',
		'scheduler',
		'currentTime',
		'entityEventMap',
		'eventGraph',
		'electionSessions'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'accessing' }
DroneSimulator >> electionSessions [
    ^ electionSessions ifNil: [ electionSessions := Dictionary new ].
]

{ #category : 'as yet unclassified' }
DroneSimulator >> handleClusterAlert: event [
    | strategy orders |

    strategy := event cluster currentMission responseStrategy.

    orders := strategy generateOrdersFor: event cluster 
        threatAt: event enemyPosition
        at: event timestamp.

    orders do: [:order |
        self scheduleEvent: order after: (Set with: event).
    ].
]

{ #category : 'events' }
DroneSimulator >> handleCompleteLeaderElection: event [
    | drones |
    drones := event cluster drones.
    drones do: [:drone |
        | announce |
        announce := AnnounceNewLeaderEvent new
            timestamp: event timestamp + 1;
            cluster: event cluster;
            newLeader: event electedDrone;
            toDrone: drone;
            yourself.
        self scheduleEvent: announce after: (Set with: event).
    ].
]

{ #category : 'events' }
DroneSimulator >> handleEnemyDetection: event [
    | cluster alertEvent |

    cluster := event detectingDrone cluster.

    alertEvent := ClusterAlertEvent new
        timestamp: event timestamp + 1;
        cluster: cluster;
        alertingDrone: event detectingDrone;
        enemyPosition: event position;
        enemy: event enemyDrone;
        yourself.

    self scheduleEvent: alertEvent after: (Set with: event).
]

{ #category : 'events' }
DroneSimulator >> handleEvent: aSimulationEvent [
    aSimulationEvent executeOn: self.
]

{ #category : 'events' }
DroneSimulator >> handleEventOld: anEvent [
    | drone updatedPos nextEvents simulationState |

    drone := anEvent drone.

    "1. Met à jour la position ou l’état dans SimulationState"
    updatedPos := anEvent reachedWaypoint ifNotNil: [ anEvent reachedWaypoint ] ifNil: [ drone position ].
    simulationState updateDrone: drone withPosition: updatedPos.

    "2. Recalcule la suite des événements pour ce drone"
    nextEvents := self recalculateEventsFor: drone fromTime: anEvent timestamp.
    scheduler updateEventsForDrone: drone with: nextEvents.

    "3. Notifie la mission / cluster"
    drone mission notifyDroneUpdate: drone.

    "4. Log"
    Transcript show: 'Event handled for drone ', drone id printString, ' at ', anEvent timestamp printString; cr.

]

{ #category : 'events' }
DroneSimulator >> handleHelpRequest: anEvent [
    | responders |

    Transcript show: 'Help requested by ', anEvent fromDrone id printString; cr.

    responders := self selectAvailableDronesNear: anEvent location.

    responders do: [:drone |
        self assignRescueMissionTo: drone at: anEvent location threatLevel: anEvent threatLevel.
    ].
]

{ #category : 'events' }
DroneSimulator >> handleMissionChanged: anEvent [
    | cluster |
    cluster := anEvent cluster.
    cluster currentMission: anEvent newMission.

    Transcript show: 'Mission updated for cluster ', cluster clusterId printString; cr.

    cluster drones do: [:drone |
        self recalculateEventsFor: drone fromTime: anEvent timestamp
    ].
]

{ #category : 'events' }
DroneSimulator >> handleRequestDroneStatus: event [
    | status response |
    status := event toDrone generateStatusData.
    response := SendDroneStatusEvent new
        timestamp: event timestamp + 1;
        fromDrone: event toDrone;
        cluster: event cluster;
        statusData: status;
        yourself.
    self scheduleEvent: response after: (Set with: event).

]

{ #category : 'events' }
DroneSimulator >> handleRequestLeaderElection: event [
    | startEvent |
    startEvent := StartLeaderElectionRequest new
        timestamp: event timestamp + 1;
        cluster: event cluster;
        requestedByDrone: event fromDrone;
        yourself.
    self scheduleEvent: startEvent after: (Set with: event).
]

{ #category : 'events' }
DroneSimulator >> handleSendDroneStatus: event [
    | session completion |

    session := self electionSessions at: event cluster.
    session receiveStatusFrom: event fromDrone data: event statusData.

    session isComplete ifTrue: [
        completion := session createCompletionEventAt: event timestamp + 1.
        self scheduleEvent: completion after: (Set with: event).
        self electionSessions removeKey: event cluster.
    ].
]

{ #category : 'events' }
DroneSimulator >> handleStartLeaderElection: event [

    | session |

    session := ElectionSession for: event cluster initiatedBy: event requestedByDrone at: event timestamp.
    self electionSessions at: event cluster put: session.

    event cluster drones do: [:drone |
        | req |
        req := RequestDroneStatusEvent new
            timestamp: event timestamp + 1;
            cluster: event cluster;
            toDrone: drone;
            yourself.
        self scheduleEvent: req after: (Set with: event).
    ].

]

{ #category : 'events' }
DroneSimulator >> handleWaypointReached: anEvent [
    | drone updatedPos nextEvents |
    
    drone := anEvent drone.
    updatedPos := anEvent reachedWaypoint.
    model updateDrone: drone withPosition: updatedPos.

    nextEvents := self recalculateEventsFor: drone fromTime: anEvent timestamp.
    scheduler updateEventsForDrone: drone with: nextEvents.

    drone mission ifNotNil: [ drone mission notifyDroneUpdate: drone ].

    Transcript show: 'Drone ', drone id printString, ' reached ', updatedPos printString; cr.

]

{ #category : 'initialization' }
DroneSimulator >> initialize [
     
	 scheduler := DiscreteEventScheduler new.
	 entityEventMap := Dictionary new. "Drone → Set of events"

    currentTime := 0.
]

{ #category : 'scheduling' }
DroneSimulator >> invalidateFutureEventsFor: anEntity after: timestamp [
    | eventsToRemove       |

    eventsToRemove := (entityEventMap at: anEntity ifAbsent: [#()]) select: [:event |
        event timestamp > timestamp
    ].
self removeEvents: eventsToRemove fromEntity: anEntity
 
]

{ #category : 'removing' }
DroneSimulator >> removeEvents: events fromEntity: entity [
    | set |
    set := entityEventMap at: entity ifAbsent: [ Set new ].
    set := set difference: events asSet.
    entityEventMap at: entity put: set.
]

{ #category : 'scheduling' }
DroneSimulator >> rescheduleDrone: aDrone from: timestamp [
    | newEvents |
    self invalidateEventsForEntity: aDrone after: timestamp.


    newEvents := self recalculateEventsFor: aDrone fromTime: timestamp.
    newEvents do: [:e | self scheduleEvent: e ].

]

{ #category : 'instance creation' }
DroneSimulator >> runSimulation [
    [ scheduler hasEvents ] whileTrue: [
        | event |
        event := scheduler nextEvent.
        currentTime := event timestamp.
        event simulationState: self.
        event execute.
        "self updateGUI."
    ].

]

{ #category : 'instance creation' }
DroneSimulator >> runSimulationWithRealTime [
    | simulationStartTime timeScale |
simulationStartTime := Time millisecondClockValue.
    timeScale := 1.0.

    [ scheduler hasEvents ] whileTrue: [
        | event simTime realElapsed realExpected realDelay |

        event := scheduler nextEvent.
        currentTime := event timestamp.

        "Calcule le temps attendu en millisecondes depuis le début"
        simTime := currentTime asFloat.
        realExpected := (simTime / timeScale * 1000) asInteger.
        realElapsed := Time millisecondClockValue - simulationStartTime.
        realDelay := realExpected - realElapsed.

        "Attend si nécessaire pour synchroniser"
        realDelay > 0 ifTrue: [ (Delay forMilliseconds: realDelay) wait ].

        "Exécute l’événement"
        event simulationState: self.
        event execute.

        self updateGUI.
    ].

]

{ #category : 'scheduling' }
DroneSimulator >> scheduleEvent: anEvent [
    | entityEventMap |
scheduler addEvent: anEvent.

    anEvent affectedEntities do: [:entity |
        (entityEventMap at: entity ifAbsentPut: [Set new]) add: anEvent.
    ].
]

{ #category : 'dependencies' }
DroneSimulator >> scheduleEvent: anEvent after: dependencyEvents [
    scheduler addEvent: anEvent.
    anEvent affectedEntities do: [:entity |
        (entityEventMap at: entity ifAbsentPut: [ Set new ]) add: anEvent.
    ].
    eventGraph addEvent: anEvent withDependencies: dependencyEvents.
]
