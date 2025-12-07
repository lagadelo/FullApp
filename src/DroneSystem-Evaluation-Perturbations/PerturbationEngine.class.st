Class {
	#name : 'PerturbationEngine',
	#superclass : 'Object',
	#instVars : [
		'scenario',
		'simulator',
		'executedEvents',
		'pendingEvents',
		'eventHandlers',
		'zoneFilters',
		'timingStrategy'
	],
	#category : 'DroneSystem-Evaluation-Perturbations',
	#package : 'DroneSystem-Evaluation-Perturbations'
}

{ #category : 'accessing' }
PerturbationEngine >> bindSimulator: aSimulator [
	simulator := aSimulator.
	^ self
]

{ #category : 'execution' }
PerturbationEngine >> executeEvent: event [
	| handler |
	handler := eventHandlers at: event eventType ifAbsent: [ nil ].
	handler notNil ifTrue: [ 
		handler value: event value: simulator
	]
]

{ #category : 'accessing' }
PerturbationEngine >> executedEvents [
	^ executedEvents
]

{ #category : 'handlers' }
PerturbationEngine >> handleCommLoss: event in: simulator [
	| drone startTime endTime |
	drone := simulator findDroneWithId: event droneId.
	drone notNil ifTrue: [
		startTime := simulator currentTime ifNil: [ 0 ].
		endTime := startTime + event duration.
		drone commLossUntil: endTime
	]
]

{ #category : 'handlers' }
PerturbationEngine >> handleDegradation: event in: simulator [
	| drone energyLoss |
	drone := simulator findDroneWithId: event droneId.
	drone notNil ifTrue: [
		energyLoss := drone energy * event degradationRate.
		drone energy: (drone energy - energyLoss) max: 0
	]
]

{ #category : 'handlers' }
PerturbationEngine >> handleDestruction: event in: simulator [
	| drone cluster |
	drone := simulator findDroneWithId: event droneId.
	drone notNil ifTrue: [
		cluster := drone cluster.
		cluster notNil ifTrue: [ cluster onDroneDestroyed: drone ].
		simulator removeDrone: drone
	]
]

{ #category : 'initialization' }
PerturbationEngine >> initialize [
	super initialize.
	scenario := nil.
	simulator := nil.
	executedEvents := OrderedCollection new.
	pendingEvents := SortedCollection new: [ :a :b | a timeStep < b timeStep ].
	eventHandlers := Dictionary new.
	zoneFilters := Dictionary new.
	timingStrategy := #uniform.
	self registerDefaultHandlers
]

{ #category : 'accessing' }
PerturbationEngine >> loadScenario: aPerturbationScenario [
	scenario := aPerturbationScenario.
	pendingEvents addAll: scenario events.
	pendingEvents sort.
	^ self
]

{ #category : 'accessing' }
PerturbationEngine >> pendingEvents [
	^ pendingEvents
]

{ #category : 'initialization' }
PerturbationEngine >> registerDefaultHandlers [
	eventHandlers at: #destruction put: [ :event :sim | self handleDestruction: event in: sim ].
	eventHandlers at: #degradation put: [ :event :sim | self handleDegradation: event in: sim ].
	eventHandlers at: #commLoss put: [ :event :sim | self handleCommLoss: event in: sim ]
]

{ #category : 'accessing' }
PerturbationEngine >> scenarioName [
	^ scenario name ifNil: [ 'Unknown' ]
]

{ #category : 'execution' }
PerturbationEngine >> step [
	"À chaque step du simulateur, vérifier et exécuter les événements pertinents"
	| currentTime eventsToExecute |
	currentTime := simulator currentTime ifNil: [ 0 ].
	
	eventsToExecute := pendingEvents select: [ :event | event timeStep = currentTime ].
	eventsToExecute do: [ :event | 
		self executeEvent: event.
		pendingEvents remove: event.
		executedEvents add: event.
	]
]
