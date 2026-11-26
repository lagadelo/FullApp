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
		'ui',
		'behavior',
		'metrics',
		'parameters',
		'losses',
		'random',
		'seed',
		'incomers',
		'timeStep',
		'events',
		'randomStreams',
		'perceptionModel'
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

{ #category : 'events - patrol extensions' }
MacroSimulator >> destroyOneDroneAt: aTimeStep matching: aPredicate stream: aStreamName [
	^ self scheduleEvent: (MacroSimulatorEvent
		at: aTimeStep
		label: 'destroy present drone'
		do: [ :step :simulator |
			simulator
				destroyOneDroneInStep: step
				matching: aPredicate
				stream: aStreamName ])
]

{ #category : 'events - patrol extensions' }
MacroSimulator >> destroyOneDroneInStep: aStep matching: aPredicate stream: aStreamName [
	| candidates rnd index victim |
	candidates := aStep drones select: [ :drone | aPredicate value: drone ].
	candidates ifEmpty: [ ^ nil ].
	rnd := self randomFor: aStreamName.
	index := (rnd next * candidates size) floor + 1.
	victim := candidates at: index.
	aStep loseDrone: victim.
	^ victim
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

{ #category : 'accessing - patrol extensions' }
MacroSimulator >> events [
	events ifNil: [ events := OrderedDictionary new ].
	^ events
]

{ #category : 'accessing - patrol extensions' }
MacroSimulator >> events: aDictionary [
	events := aDictionary
]

{ #category : 'events - patrol extensions' }
MacroSimulator >> eventsAt: aTimeStep [
	^ self events at: aTimeStep ifAbsent: [ #() ]
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
	future := self current copy.
	future timeStep: t.

	"Legacy events first."
	(self lossesAt: t) do: [ :id | future loseDroneID: id ].
	(self incomersAt: t) do: [ :drone | future welcomeDrone: drone copy ].

	"Generic state-dependent events next."
	(self eventsAt: t) do: [ :event |
		event applyTo: future simulator: self ].
	^ future
]

{ #category : 'gui' }
MacroSimulator >> hasUI [

	^ ui isNil not
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
	self events: OrderedDictionary new.
	randomStreams := Dictionary new.
	self behavior: MacroSimulatorBehavior new.
	self perceptionModel: MacroSimulatorPerfectPerception new.
	self random: Random new
]

{ #category : 'initialization' }
MacroSimulator >> initializeSeed: aSeed [
	"Useful for exact replay. Named streams are deterministically derived from this seed."
	self seed ifNil: [
		self seed: aSeed.
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

{ #category : 'gui' }
MacroSimulator >> open [

ui := QuickGeoportailMap openOn: self 
]

{ #category : 'accessing' }
MacroSimulator >> parameters [

	^ parameters
]

{ #category : 'accessing' }
MacroSimulator >> parameters: anObject [

	parameters := anObject
]

{ #category : 'accessing - patrol extensions' }
MacroSimulator >> perceptionModel [
	perceptionModel ifNil: [ perceptionModel := MacroSimulatorPerfectPerception new ].
	^ perceptionModel
]

{ #category : 'accessing - patrol extensions' }
MacroSimulator >> perceptionModel: aModel [
	perceptionModel := aModel
]

{ #category : 'accessing' }
MacroSimulator >> random [

	^ random
]

{ #category : 'accessing' }
MacroSimulator >> random: anObject [

	random := anObject
]

{ #category : 'random - patrol extensions' }
MacroSimulator >> randomFor: aName [
	| baseSeed derivedSeed |
	baseSeed := self seed ifNil: [ 0 ].
	derivedSeed := baseSeed + (self stableOffsetFor: aName).
	^ self randomStreams
		at: aName asSymbol
		ifAbsentPut: [ Random seed: derivedSeed ]
]

{ #category : 'accessing - patrol extensions' }
MacroSimulator >> randomStreams [
	randomStreams ifNil: [ randomStreams := Dictionary new ].
	^ randomStreams
]

{ #category : 'positioning' }
MacroSimulator >> realPositionFrom: aPosition [

	^ self parameters realPositionFrom: aPosition
]

{ #category : 'stepping' }
MacroSimulator >> run: n [

	n timesRepeat: [ self step ]
]

{ #category : 'stepping - patrol extensions' }
MacroSimulator >> runSingleUpdate: n [
	n timesRepeat: [ self stepSingleUpdate ]
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

{ #category : 'events - sensing patrol v0.2' }
MacroSimulator >> scheduleAllDistanceMeasurementAvailable: aBoolean at: aTimeStep [
	^ self
		scheduleDistanceMeasurementAvailable: aBoolean
		at: aTimeStep
		matching: [ :drone | true ]
]

{ #category : 'events - sensing patrol v0.2' }
MacroSimulator >> scheduleDistanceMeasurementAvailable: aBoolean at: aTimeStep matching: aPredicate [
	^ self scheduleEvent: (MacroSimulatorEvent
		at: aTimeStep
		label: (aBoolean ifTrue: [ 'restore distance measurement' ] ifFalse: [ 'lose distance measurement' ])
		do: [ :step :simulator |
			simulator
				setDistanceMeasurementAvailable: aBoolean
				inStep: step
				matching: aPredicate ])
]

{ #category : 'events - patrol extensions' }
MacroSimulator >> scheduleEvent: anEvent [
	(self events
		at: anEvent timeStep
		ifAbsentPut: [ OrderedCollection new ]) add: anEvent.
	^ anEvent
]

{ #category : 'events - patrol extensions' }
MacroSimulator >> scheduleEventsFrom: firstTime to: lastTime using: anEventLaw stream: aStreamName label: aLabel do: anActionBlock [
	| rnd |
	rnd := self randomFor: aStreamName.
	firstTime to: lastTime do: [ :t |
		| count |
		count := anEventLaw countAt: t using: rnd.
		count timesRepeat: [
			self scheduleEvent: (MacroSimulatorEvent
				at: t
				label: aLabel
				do: anActionBlock) ] ]
]

{ #category : 'events - sensing patrol v0.2' }
MacroSimulator >> scheduleOneRandomDistanceLossAt: aTimeStep matching: aPredicate stream: aStreamName [
	^ self scheduleEvent: (MacroSimulatorEvent
		at: aTimeStep
		label: 'one random distance sensor loss'
		do: [ :step :simulator |
			| candidates rnd victim |
			candidates := step drones select: [ :drone |
				(aPredicate value: drone) and: [ drone distanceMeasurementAvailable ] ].
			candidates ifNotEmpty: [
				rnd := simulator randomFor: aStreamName.
				victim := candidates at: ((rnd next * candidates size) floor + 1).
				victim distanceMeasurementAvailable: false.
				victim id ] ])
]

{ #category : 'events - sensing patrol v0.2' }
MacroSimulator >> scheduleVisionAvailable: aBoolean at: aTimeStep matching: aPredicate [
	^ self scheduleEvent: (MacroSimulatorEvent
		at: aTimeStep
		label: (aBoolean ifTrue: [ 'restore vision' ] ifFalse: [ 'lose vision' ])
		do: [ :step :simulator |
			simulator setVisionAvailable: aBoolean inStep: step matching: aPredicate ])
]

{ #category : 'accessing' }
MacroSimulator >> seed [

	^ seed
]

{ #category : 'accessing' }
MacroSimulator >> seed: anObject [
	seed := anObject.
	randomStreams := Dictionary new
]

{ #category : 'events - sensing patrol v0.2' }
MacroSimulator >> setDistanceMeasurementAvailable: aBoolean inStep: aStep matching: aPredicate [
	| changed |
	changed := OrderedCollection new.
	aStep drones do: [ :drone |
		(aPredicate value: drone) ifTrue: [
			drone distanceMeasurementAvailable: aBoolean.
			changed add: drone id ] ].
	^ changed
]

{ #category : 'events - sensing patrol v0.2' }
MacroSimulator >> setVisionAvailable: aBoolean inStep: aStep matching: aPredicate [
	| changed |
	changed := OrderedCollection new.
	aStep drones do: [ :drone |
		(aPredicate value: drone) ifTrue: [
			drone visionAvailable: aBoolean.
			changed add: drone id ] ].
	^ changed
]

{ #category : 'random - patrol extensions' }
MacroSimulator >> stableOffsetFor: aName [
	| h |
	h := 0.
	aName asString do: [ :character |
		h := ((h * 31) + character asciiValue) \ 2147483647 ].
	^ h
]

{ #category : 'initialization' }
MacroSimulator >> startWith: aMacroSimulatorParameters [

	self parameters: aMacroSimulatorParameters.
	self history add:
		(MacroSimulatorStep new applyParameters: aMacroSimulatorParameters; simulator: self ; yourself).
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

{ #category : 'stepping - patrol extensions' }
MacroSimulator >> stepSingleUpdate [
	"Opt-in corrected stepping semantics: commands are computed, then positions advance exactly once.
	The legacy step method is deliberately left untouched for backward comparison."
	| future |
	future := self futureStep.
	self behavior computeCommandsFor: future.
	future update.
	self history add: future.
	^ self
]

{ #category : 'accessing' }
MacroSimulator >> timeStep [

	^ timeStep
]

{ #category : 'accessing' }
MacroSimulator >> timeStep: a [

	timeStep := a
]
