Class {
	#name : 'MacroSimulatorStep',
	#superclass : 'Object',
	#instVars : [
		'timeStep',
		'drones',
		'maxID',
		'lostDrones',
		'range'
	],
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
}

{ #category : 'initialization' }
MacroSimulatorStep >> applyParameters: aMacroSimulatorParameters [

	self initialize.
	self drones addAll: aMacroSimulatorParameters generate.
	self maxID: self drones size.
	self range: aMacroSimulatorParameters totalDistance 
]

{ #category : 'copying' }
MacroSimulatorStep >> copy [ 
| tmp |
tmp := self class new.
tmp drones: (self drones collect:[:a| a copy]).
tmp lostDrones: (self lostDrones collect:[:a| a copy]).
tmp range: self range.
^tmp 
]

{ #category : 'accessing' }
MacroSimulatorStep >> drones [

	^ drones
]

{ #category : 'accessing' }
MacroSimulatorStep >> drones: anObject [

	drones := anObject
]

{ #category : 'reporting' }
MacroSimulatorStep >> evaluateMetrics [
^MacroSimulatorMetrics on: self 
]

{ #category : 'running' }
MacroSimulatorStep >> gapAheadDrone: aDrone [

	^ ((self predecessorOf: aDrone) position - aDrone position ) % self range
]

{ #category : 'running' }
MacroSimulatorStep >> gapBackwardDrone: aDrone [

	^ aDrone position - (self successorOf: aDrone) position % self range 
]

{ #category : 'initialization' }
MacroSimulatorStep >> initialize [ 
self maxID:0.
self drones: (SortedCollection sortBlock:[:a :b| b position > a position]).  
]

{ #category : 'running' }
MacroSimulatorStep >> loseDrone: aDrone [

	self drones remove: aDrone.
	self lostDrones add: aDrone
]

{ #category : 'running' }
MacroSimulatorStep >> loseDroneID: anID [

	| aDrone |
	aDrone := self drones detect: [ :d | d id = anID ].
	self loseDrone: aDrone
]

{ #category : 'accessing' }
MacroSimulatorStep >> lostDrones [

	lostDrones ifNil: [ self lostDrones: OrderedCollection new ].
	^ lostDrones
]

{ #category : 'accessing' }
MacroSimulatorStep >> lostDrones: anObject [

	lostDrones := anObject
]

{ #category : 'accessing' }
MacroSimulatorStep >> maxID [

	^ maxID
]

{ #category : 'accessing' }
MacroSimulatorStep >> maxID: anObject [

	maxID := anObject
]

{ #category : 'as yet unclassified' }
MacroSimulatorStep >> nextID [

	self maxID: self maxID + 1.
	^ self maxID  
]

{ #category : 'drones accessing' }
MacroSimulatorStep >> predecessorOf: aDrone [

	| i |
	i := self drones indexOf: aDrone.
	^ self drones at: i % self drones size + 1 " = self drones size iftrue:[1] iffalse:[ i +1 ]"
]

{ #category : 'accessing' }
MacroSimulatorStep >> range [

	^ range
]

{ #category : 'accessing' }
MacroSimulatorStep >> range: anObject [

	range := anObject
]

{ #category : 'reporting' }
MacroSimulatorStep >> reportGaps [

^self drones collect:[:d| (self gapAheadDrone: d) @ (self gapBackwardDrone: d)]
]

{ #category : 'reporting' }
MacroSimulatorStep >> reportSpeeds [

	^ self drones collect: [ :d | d currentSpeed ]
]

{ #category : 'drones accessing' }
MacroSimulatorStep >> successorOf: aDrone [

	| i |
	i := self drones indexOf: aDrone.
	^ i = 1
		  ifTrue: [ self drones last ]
		  ifFalse: [ self drones at: i - 1 ]
]

{ #category : 'accessing' }
MacroSimulatorStep >> timeStep [

	^ timeStep
]

{ #category : 'accessing' }
MacroSimulatorStep >> timeStep: anObject [

	timeStep := anObject
]

{ #category : 'running' }
MacroSimulatorStep >> update [

	"All changes have been applies (drones in/out, speed adjustments)"
	"It's now time to recompute state"
	self drones do: [ :a | a update ]
]

{ #category : 'running' }
MacroSimulatorStep >> welcomeDrone: aDrone [

	self welcomeDrone: aDrone atPosition: 0
]

{ #category : 'running' }
MacroSimulatorStep >> welcomeDrone: aDrone atPosition: aPosition [
	"Fine tuning for spare insertion"

	aDrone id: self nextID.
	aDrone position: aPosition.
	self drones add: aDrone
]
