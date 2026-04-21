"
has 6 instance variables as:
	- timeStep : current time, this can also serve as index
	- drones : alive drones
	- lostDrones : dead drones 
	- predecessors : a dictionary of drone -> drone, used to find the drone ahead of the key
	- successors : a dictionary of drone -> drone, used to find the drone behing   the key
	- maxID : used for setting up an incomer
	
is intented to represent the fleet's state at timeStep
"
Class {
	#name : 'MacroSimulatorStep',
	#superclass : 'Object',
	#instVars : [
		'timeStep',
		'drones',
		'maxID',
		'lostDrones',
		'range',
		'predecessors',
		'successors',
		'simulator'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'drones accessing' }
MacroSimulatorStep >> aheadOfPosition: p [

	| d |
	d := self drones first.

	self drones do: [ :a |
			a position - p % self range < (d position - p % self range)
				ifTrue: [ d := a ] ].
	^ d
]

{ #category : 'initialize' }
MacroSimulatorStep >> applyParameters: aMacroSimulatorParameters [

	self initialize.
	self drones addAll: aMacroSimulatorParameters generate.
	self maxID: self drones size.
	self range: aMacroSimulatorParameters totalDistance.
	self setupQueue
]

{ #category : 'copying' }
MacroSimulatorStep >> copy [

	| tmp |
	tmp := self class new.

	tmp drones: (self drones collect: [ :a | a copy ]).
	tmp lostDrones: (self lostDrones collect: [ :a | a copy ]).

	tmp range: self range.
	tmp simulator: self simulator.
	self predecessors keysAndValuesDo: [ :k :v |
			tmp predecessors
				at: (tmp drones at: (self drones indexOf: k))
				put: (tmp drones at: (self drones indexOf: v)) ].

	self successors keysAndValuesDo: [ :k :v |
			tmp successors
				at: (tmp drones at: (self drones indexOf: k))
				put: (tmp drones at: (self drones indexOf: v)) ].

	tmp maxID: self maxID.

	^ tmp
]

{ #category : 'drones accessing' }
MacroSimulatorStep >> droneWithID: anID [ 

	^ self drones detect: [ :a | a id = anID ] ifNone: [ nil ]
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

	^ MacroSimulatorMetrics on: self
]

{ #category : 'running' }
MacroSimulatorStep >> gapAheadDrone: aDrone [ 

	^ ( (self predecessorOf: aDrone) position - aDrone position   ) % self range
]

{ #category : 'running' }
MacroSimulatorStep >> gapBackwardDrone: aDrone [

	^ aDrone position - (self successorOf: aDrone) position % self range
]

{ #category : 'initialize' }
MacroSimulatorStep >> initialize [ 

	super initialize.
	self maxID: 0.
	self drones: OrderedCollection new.

	self successors: Dictionary new.
	self predecessors: Dictionary new.
	self timeStep: 0
]

{ #category : 'running' }
MacroSimulatorStep >> loseDrone: aDrone [
	"Update status"

	aDrone die.

	"Move from drones to lostDrones"
	self drones remove: aDrone.
	self lostDrones add: aDrone.


	"new follower's successor is our own successor"
	self
		register: (self predecessorOf: aDrone)
		asPredecessorOf: (self successorOf: aDrone).
	self
		register: (self successorOf: aDrone)
		asSuccessorOf: (self predecessorOf: aDrone).

	"Forget the lost drone in terms of following"
	self predecessors removeKey: aDrone.
	self successors removeKey: aDrone
]

{ #category : 'running' }
MacroSimulatorStep >> loseDroneID: anID [ 

	| aDrone |
	aDrone := self drones detect: [ :d | d id = anID ].
	self loseDrone: aDrone
]

{ #category : 'drones accessing' }
MacroSimulatorStep >> lostDroneWithID: anID [ 

	^ self lostDrones detect: [ :a | a id = anID ] ifNone: [ nil ]
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

{ #category : 'running' }
MacroSimulatorStep >> nextID [

	| id |
	id := self maxID.
	self maxID: self maxID + 1.
	^ id
]

{ #category : 'drones accessing' }
MacroSimulatorStep >> predecessorOf: aDrone [ 

	^ self predecessors at: aDrone
]

{ #category : 'accessing' }
MacroSimulatorStep >> predecessors [

	^ predecessors
]

{ #category : 'accessing' }
MacroSimulatorStep >> predecessors: anObject [

	predecessors := anObject
]

{ #category : 'accessing' }
MacroSimulatorStep >> range [

	^ range
]

{ #category : 'accessing' }
MacroSimulatorStep >> range: anObject [

	range := anObject
]

{ #category : 'positioning' }
MacroSimulatorStep >> realPositionFrom: aPosition [

	^ self simulator realPositionFrom: aPosition
]

{ #category : 'positioning' }
MacroSimulatorStep >> realPositionOfDrone: aDrone [

	^ self  realPositionFrom: aDrone position 
]

{ #category : 'positioning' }
MacroSimulatorStep >> realPositionsOfDrones [

	^ self drones collect: [ :aDrone | self realPositionOfDrone: aDrone ]
]

{ #category : 'running' }
MacroSimulatorStep >> register: aDrone after: anotherDrone [ 

	^ self
		  register: aDrone
		  between: anotherDrone
		  and: (self successorOf: anotherDrone)
]

{ #category : 'running' }
MacroSimulatorStep >> register: aDrone aheadOf: anotherDrone [ 

	^ self
		  register: aDrone
		  between: anotherDrone
		  and: (self successorOf: anotherDrone)
]

{ #category : 'private' }
MacroSimulatorStep >> register: aDrone asPredecessorOf: anotherDrone [ 

	self predecessors at: anotherDrone put: aDrone
]

{ #category : 'private' }
MacroSimulatorStep >> register: aDrone asSuccessorOf: anotherDrone [ 

	self successors at: anotherDrone put: aDrone
]

{ #category : 'running' }
MacroSimulatorStep >> register: aDrone between: aSecondDrone and: aThirdDrone [ 

	"Ensure consistency"
	(self successorOf: aSecondDrone) == aThirdDrone ifFalse: [
		^ self error: 'Incorrect call' ].
	self predecessors at: aDrone put: aSecondDrone.
	self successors at: aSecondDrone put: aDrone.

	self predecessors at: aThirdDrone put: aDrone.
	self successors at: aDrone put: aThirdDrone
]

{ #category : 'reporting' }
MacroSimulatorStep >> reportGaps [

	^ self drones collect: [ :d |
		  (self gapAheadDrone: d) @ (self gapBackwardDrone: d) ]
]

{ #category : 'reporting' }
MacroSimulatorStep >> reportSpeeds [

	^ self drones collect: [ :d | d currentSpeed ]
]

{ #category : 'private' }
MacroSimulatorStep >> setupQueue [
	"This relies on indexes; should only be used once, during initialization"

	1 to: self drones size do: [ :index |
			self
				register: (self drones at: index)
				asPredecessorOf: (self drones at: index % self drones size + 1).
			self
				register: (self drones at: index % self drones size + 1)
				asSuccessorOf: (self drones at: index) ]
]

{ #category : 'accessing' }
MacroSimulatorStep >> simulator [

	^ simulator
]

{ #category : 'accessing' }
MacroSimulatorStep >> simulator: aValue [

	simulator := aValue
]

{ #category : 'drones accessing' }
MacroSimulatorStep >> successorOf: aDrone [

	^ self successors at: aDrone
]

{ #category : 'accessing' }
MacroSimulatorStep >> successors [

	^ successors
]

{ #category : 'accessing' }
MacroSimulatorStep >> successors: anObject [

	successors := anObject
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

	self welcomeDrone: aDrone atPosition: (aDrone position
			 ifNil: [ " should not happen here" 0 ]
			 ifNotNil: [ aDrone position ])


	"We need to update the successors and followers here"
]

{ #category : 'running' }
MacroSimulatorStep >> welcomeDrone: aDrone atPosition: aPosition [ 
	"Fine tuning for spare insertion"

	| d |
	aDrone id ifNil:[aDrone id: self nextID].
	aDrone position: aPosition.
	d := (self aheadOfPosition: aPosition).
	self drones add: aDrone.
	self register: aDrone after: d. 
]
