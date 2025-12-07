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
DroneSimulator >> handleEvent: aSimulationEvent [
    aSimulationEvent executeOn: self.
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
				"Transcript show: event printString;cr." event executeOn: self.

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

{ #category : 'initialization' }
DroneSimulator >> synchonizeAllEvents: kindOfEvent after: aTimestamp [

^self scheduler synchonizeAllEvents: kindOfEvent after: aTimestamp
]

{ #category : 'accessing' }
DroneSimulator >> synchronize [

	self scheduler synchonizeAllEvents:  WayPointReachedEvent after: self currentTime
]

{ #category : 'accessing' }
DroneSimulator >> timeStep [

	^ timeStep
]

{ #category : 'accessing' }
DroneSimulator >> timeStep: anObject [

	timeStep := anObject
]
