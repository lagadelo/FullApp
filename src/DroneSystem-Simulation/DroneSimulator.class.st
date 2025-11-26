Class {
	#name : 'DroneSimulator',
	#superclass : 'Object',
	#instVars : [
		'model',
		'scheduler',
		'currentTime',
		'timeStep',
		'entityEventMap',
		'eventGraph',
		'electionSessions',
		'autoResume',
		'isRunning'
	],
	#classInstVars : [
		'Singleton'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'instance creation' }
DroneSimulator class >> destroySingleton [

	Singleton := nil
]

{ #category : 'instance creation' }
DroneSimulator class >> new [ 

Singleton := super new.
^Singleton

]

{ #category : 'instance creation' }
DroneSimulator class >> uniqueInstance [

	^ Singleton
]

{ #category : 'accessing' }
DroneSimulator >> autoResume [

	^ autoResume
]

{ #category : 'accessing' }
DroneSimulator >> autoResume: anObject [

	autoResume := anObject
]

{ #category : 'accessing' }
DroneSimulator >> currentTime [

	^ currentTime
]

{ #category : 'accessing' }
DroneSimulator >> currentTime: anObject [

	currentTime := anObject
]

{ #category : 'accessing' }
DroneSimulator >> electionSessions [
    ^ electionSessions ifNil: [ electionSessions := Dictionary new ].
]

{ #category : 'accessing' }
DroneSimulator >> electionSessions: anObject [

	electionSessions := anObject
]

{ #category : 'accessing' }
DroneSimulator >> entityEventMap [

	^ entityEventMap
]

{ #category : 'accessing' }
DroneSimulator >> entityEventMap: anObject [

	entityEventMap := anObject
]

{ #category : 'accessing' }
DroneSimulator >> eventGraph [

	^ eventGraph
]

{ #category : 'accessing' }
DroneSimulator >> eventGraph: anObject [

	eventGraph := anObject
]

{ #category : 'scheduling' }
DroneSimulator >> execute: anEvent [
"Visitor DP"
^anEvent executeOn: self 
]

{ #category : 'events' }
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

{ #category : 'testing' }
DroneSimulator >> hasCompleted: aTimestamp [

	| nextEvt |
	self currentTime > aTimestamp ifTrue: [ ^ true ]. "Alread done"
	nextEvt := self scheduler potentialNextEvent.
	nextEvt ifNil: [ ^ false ]. "Not done, and nothing more to do, answers no"
	nextEvt timestamp ifNil: [ ^ false ]. "Supposed to be initial case"	
	^ nextEvt timestamp > aTimestamp "Something to do, but noting at our timeStamp, answers yes"
]

{ #category : 'scheduling' }
DroneSimulator >> hasEvents [ 
^self scheduler hasEvents 
]

{ #category : 'initialization' }
DroneSimulator >> initialize [
     
	scheduler := DiscreteEventScheduler new.
	entityEventMap := EventDependencyGraph new.

    currentTime := 0.
]

{ #category : 'initialization' }
DroneSimulator >> initializeWithState: aSimulationStep [

self model: aSimulationStep
]

{ #category : 'scheduling' }
DroneSimulator >> invalidateFutureEventsFor: anEntity after: timestamp [
    | eventsToRemove       |

    eventsToRemove := (entityEventMap at: anEntity ifAbsent: [#()]) select: [:event |
        event timestamp > timestamp
    ].
self removeEvents: eventsToRemove fromEntity: anEntity
 
]

{ #category : 'accessing' }
DroneSimulator >> isRunning [

	isRunning ifNil: [ self isRunning: false ].
	^ isRunning
]

{ #category : 'accessing' }
DroneSimulator >> isRunning: aBool [

	isRunning := aBool
]

{ #category : 'as yet unclassified' }
DroneSimulator >> markAsExecuted: anEvent [

self scheduler markAsExecuted: anEvent
]

{ #category : 'accessing' }
DroneSimulator >> model [

	^ model
]

{ #category : 'accessing' }
DroneSimulator >> model: anObject [

	model := anObject
]

{ #category : 'user interface' }
DroneSimulator >> open [

	| tmp |
	tmp := self model open.
	tmp simulator: self.

	^ tmp
]

{ #category : 'events' }
DroneSimulator >> removeAllEventsFor:target after: aTimestamp [

self scheduler removeAllEventsFor:target after: aTimestamp 
]

{ #category : 'removing' }
DroneSimulator >> removeEvents: events fromEntity: entity [
    | set |
    set := entityEventMap at: entity ifAbsent: [ Set new ].
    set := set difference: events asSet.
    entityEventMap at: entity put: set.
]

{ #category : 'events' }
DroneSimulator >> requeueEvent: anEvent delay: aDelay [
    | delayedEvent |
    delayedEvent := anEvent copy.
    delayedEvent timestamp: anEvent timestamp + aDelay.
    self addEvent: delayedEvent.
]

{ #category : 'dependencies' }
DroneSimulator >> scheduleEvent: anEvent [

 
	anEvent timestamp ifNil:[anEvent timestamp: self currentTime.].
	scheduler scheduleEvent: anEvent
]

{ #category : 'dependencies' }
DroneSimulator >> scheduleEvent: anEvent after: dependencyEvents [
    self scheduleEvent: anEvent.
 
    scheduler eventGraph addEvent: anEvent withDependencies: dependencyEvents.
]

{ #category : 'dependencies' }
DroneSimulator >> scheduleEvent: evt at: aDate [

	evt timestamp: aDate.
	^self scheduleEvent: evt.
]

{ #category : 'dependencies' }
DroneSimulator >> scheduleEvent: anEvent at: aTimestamp after: dependencyEvents [

	anEvent timestamp: aTimestamp.
	self scheduleEvent: anEvent.

	scheduler eventGraph
		addEvent: anEvent
		withDependencies: dependencyEvents
]

{ #category : 'accessing' }
DroneSimulator >> scheduler [

	^ scheduler
]

{ #category : 'accessing' }
DroneSimulator >> scheduler: anObject [

	scheduler := anObject
]

{ #category : 'scheduling' }
DroneSimulator >> step [

	| event |
	 
	self hasEvents ifFalse: [ "Stopping simulation is critic as the GUI loops over while the simulation isRunning"
			self isRunning: false.
			^ self ].
	self isRunning ifFalse: [ ^ self ].
	event := scheduler nextEvent.

	(entityEventMap isReady: event)
		ifTrue: [ "Met à jour le temps courant de la simulation"
				event timestamp ifNil: [ event timestamp: currentTime ].
				currentTime = event timestamp ifFalse: [ "Only refresh once when several events share timestamp"
						self model ifNotNil: [ self model hasChanged ]. "This should now be delegated in jump: method of UISimulator"
						currentTime := event timestamp ].

				event simulationState: self.

				"Exécute l'événement et le marque comme terminé"
				event executeOn: self.

				self markAsExecuted: event

				"Log optionnel"
				"				Transcript
					show:
						'[' , currentTime printString , '] Executed: '
						, event class name;
					space;
					show: event printString;
					cr" ]
		ifFalse: [ "Dépendances non satisfaites : on remet l'événement en file, légèrement décalé"
			scheduler requeueEvent: event delay: 0.1 ]
]

{ #category : 'accessing' }
DroneSimulator >> timeStep [

	^ timeStep
]

{ #category : 'accessing' }
DroneSimulator >> timeStep: anObject [

	timeStep := anObject
]
