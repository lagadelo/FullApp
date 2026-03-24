"
MacroSimulator is the simulator.

This class has 
- behavior : a MacroSimulatorBehavior
- metrics : a MacroSimulatorMetrics
- history : a collection of MacroSimulatorStep
- timeStep

- random : this is used to get a common seed on demand when replaying some scenarios

- incomers and losses that describe events at a given timeStep

"
Class {
	#name : 'MacroSimulator',
	#superclass : 'Object',
	#instVars : [
		'history',
		'behavior',
		'metrics',
		'parameters',
		'losses',
		'random',
		'seed',
		'incomers',
		'timeStep'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'inst' }
MacroSimulator class >> fromParameters: aMacroSimilatorParameters [

	^ self new
		  parameters: aMacroSimilatorParameters;
		  yourself
]

{ #category : 'visiting' }
MacroSimulator >> accept: aVisitor [

	^ aVisitor visitMacroSimulator: self
]

{ #category : 'initialization' }
MacroSimulator >> at: aTimeStep [

	^ self historyAt: aTimeStep
]

{ #category : 'initialization' }
MacroSimulator >> at: aTimeStep put: aState [

	^ self history at: aTimeStep put: aState
]

{ #category : 'accessing' }
MacroSimulator >> behavior [

	^ behavior
]

{ #category : 'accessing' }
MacroSimulator >> behavior: anObject [

	behavior := anObject
]

{ #category : 'time accessing' }
MacroSimulator >> current [

	^ self history last
]

{ #category : 'fleet updates' }
MacroSimulator >> enter: aMacroSimulatorDrone at: aTimeStep [

	(self incomers at: aTimeStep ifAbsentPut: [ OrderedCollection new ])
		add: aMacroSimulatorDrone
]

{ #category : 'reporting' }
MacroSimulator >> evaluateMetrics [

	^ MacroSimulatorMetricsHistory from:
		  (history collect: [ :aMacroSimulaotStep |
			   aMacroSimulaotStep evaluateMetrics ])
]

{ #category : 'reporting' }
MacroSimulator >> export [ 

	self error:'Legacy code to be removed'
	"^ self export:
		  #( minGap maxGap avgGap stdGap minSpeed maxSpeed avgSpeed stdSpeed )"
]

{ #category : 'reporting' }
MacroSimulator >> export: fields [

	| fn dir data s b |
	"dir := UIManager default
    chooseDirectory: 'Select directory of the collection'.

 fn := ((UIManager default
    chooseDirectory: 'Select directory of the collection' ) fullName , '/', 'loic') asFileReference  ."
	fn := (self behavior exportName , '.csv') asFileReference.
	data := self evaluateMetrics.

	fn exists ifTrue: [ fn delete ].
	fn createFile.
	s := self random seed.
	b := self behavior export.

	fn writeStreamDo: [ :stream |
			| nw |
			nw := NeoCSVWriter on: stream.
			nw nextPut: {
					#seed.
					s } , b. "Simulation Context"
			nw
				nextPut: fields;
				"First line = column labels"addRawFields: fields. "accessors over lines"
			nw nextPutAll: data ]
]

{ #category : 'time accessing' }
MacroSimulator >> futureStep [

	| future t |
	t := self nextTimeStep.

	future := self current copy. "Now currentState"
	future timeStep: t.
	(self lossesAt: t) do: [ :id | future loseDroneID: id ].
	(self incomersAt: t) do: [ :drone | future welcomeDrone: drone copy ].

	^ future
]

{ #category : 'accessing' }
MacroSimulator >> history [

	^ history
]

{ #category : 'accessing' }
MacroSimulator >> history: anObject [

	history := anObject
]

{ #category : 'accessing' }
MacroSimulator >> incomers [

	^ incomers
]

{ #category : 'accessing' }
MacroSimulator >> incomers: anObject [

	incomers := anObject
]

{ #category : 'fleet updates' }
MacroSimulator >> incomersAt: aTimeStep [

	^ self incomers at: aTimeStep ifAbsent: [ #(  ) ]
]

{ #category : 'initialization' }
MacroSimulator >> initialize [

	super initialize.
	self timeStep: 0.
	self history: OrderedCollection new.
	self incomers: OrderedDictionary new.
	self losses: OrderedDictionary new.
	self behavior: MacroSimulatorBehavior new.
	self random: Random new
]

{ #category : 'initialization' }
MacroSimulator >> initializeSeed: aSeed [
	"Usefull for exact replay - ignore nil seed"

	seed ifNil: [
			seed := aSeed.
			self random: (Random seed: aSeed) ]
]

{ #category : 'fleet updates' }
MacroSimulator >> loose: id at: aTimeStep [ 

	(self losses at: aTimeStep ifAbsentPut: [ OrderedCollection new ])
		add: id
]

{ #category : 'accessing' }
MacroSimulator >> losses [

	^ losses
]

{ #category : 'fleet updates' }
MacroSimulator >> losses: anObject [ 

	losses := anObject

]

{ #category : 'fleet updates' }
MacroSimulator >> lossesAt: aTimeStep [

	^ self losses at: aTimeStep ifAbsent: [ #(  ) ]
]

{ #category : 'accessing' }
MacroSimulator >> metrics [

	^ metrics
]

{ #category : 'accessing' }
MacroSimulator >> metrics: anObject [

	metrics := anObject
]

{ #category : 'fleet updates' }
MacroSimulator >> newIncomerAt: aTimeStamp [

	| newDrone |
	newDrone := self parameters generateDrone.
	newDrone id: self current nextID.
	newDrone position: self random next * parameters totalDistance.
	self enter: newDrone at: aTimeStamp.
	^newDrone id
]

{ #category : 'time accessing' }
MacroSimulator >> nextTimeStep [

	^ self history last timeStep + 1
]

{ #category : 'accessing' }
MacroSimulator >> parameters [

	^ parameters
]

{ #category : 'accessing' }
MacroSimulator >> parameters: anObject [

	parameters := anObject
]

{ #category : 'accessing' }
MacroSimulator >> random [

	^ random
]

{ #category : 'accessing' }
MacroSimulator >> random: anObject [

	random := anObject
]

{ #category : 'stepping' }
MacroSimulator >> run: n [

	n timesRepeat: [ self step ]
]

{ #category : 'stepping' }
MacroSimulator >> running [ 

	| current |
	self step. "Deepcopy of the previous state"
	current := self history last. "Now currentState"
	(self lossesAt: current key) do: [ :id |
		current do: [ :elt | elt id = id ifTrue: [ elt die ] ] ]
]

{ #category : 'fleet updates' }
MacroSimulator >> scenario [

	| dates events tmp |
	events := OrderedCollection new.
	dates := Set new.
	dates addAll: self losses keys , self incomers keys.

	dates asSortedCollection do: [ :a |
			| currentEvents timestampedEvents |
			timestampedEvents := OrderedCollection new.
			currentEvents := OrderedCollection new.

			(self lossesAt: a) do: [ :event |
					| tmp |
					currentEvents add:
						((self history at: a + 1) lostDroneWithID: event) ].
			(self incomersAt: a) do: [ :event | currentEvents add: event ].

			timestampedEvents add: a.
			timestampedEvents add: currentEvents.
			events add: timestampedEvents ].

	^ events
]

{ #category : 'accessing' }
MacroSimulator >> seed [

	^ seed
]

{ #category : 'accessing' }
MacroSimulator >> seed: anObject [

	seed := anObject
]

{ #category : 'initialization' }
MacroSimulator >> startWith: aMacroSimulatorParameters [

	self parameters: aMacroSimulatorParameters.
	self history add:
		(MacroSimulatorStep new applyParameters: aMacroSimulatorParameters).
	behavior policy: aMacroSimulatorParameters policy.
	self initializeSeed: self parameters seed
]

{ #category : 'stepping' }
MacroSimulator >> step [

	| future |
	future := self futureStep.
	self behavior process: future.
	future update.
	self history add: future.
	self
]

{ #category : 'accessing' }
MacroSimulator >> timeStep [

	^ timeStep
]

{ #category : 'accessing' }
MacroSimulator >> timeStep: a [

	timeStep := a
]
