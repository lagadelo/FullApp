"
has 6 instance variables as:
	- min  
	- max  
	- std deviation  
per each dimention : speed and gap
	
is intented to generate analysis over a MacroSimulationStep
"
Class {
	#name : 'MacroSimulatorMetrics',
	#superclass : 'Object',
	#instVars : [
		'minGap',
		'maxGap',
		'avgGap',
		'stdGap',
		'minSpeed',
		'maxSpeed',
		'avgSpeed',
		'stdSpeed',
		'fleetSize',
		'timeStep',
		'maxUncoveredGap',
		'avgUncoveredGap',
		'totalUncoveredLength',
		'coverageRatio',
		'directPerceptionRatio',
		'angularPerceptionRatio',
		'unobservablePerceptionRatio',
		'outOfRangePerceptionRatio',
		'avgGapEstimationError',
		'maxGapEstimationError'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorMetrics class >> on: aMacroSimulationStep [
	| tmp gaps uncovered speeds totalUncovered ratio range perception |
	tmp := self new.
	tmp timeStep: aMacroSimulationStep timeStep.
	tmp fleetSize: aMacroSimulationStep drones size.

	aMacroSimulationStep drones ifEmpty: [
		tmp
			minGap: 0.0; maxGap: 0.0; avgGap: 0.0; stdGap: 0.0;
			minSpeed: 0.0; maxSpeed: 0.0; avgSpeed: 0.0; stdSpeed: 0.0;
			maxUncoveredGap: aMacroSimulationStep range asFloat;
			avgUncoveredGap: aMacroSimulationStep range asFloat;
			totalUncoveredLength: aMacroSimulationStep range asFloat;
			coverageRatio: 0.0;
			directPerceptionRatio: 0.0;
			angularPerceptionRatio: 0.0;
			unobservablePerceptionRatio: 0.0;
			outOfRangePerceptionRatio: 0.0;
			avgGapEstimationError: 0.0;
			maxGapEstimationError: 0.0.
		^ tmp ].

	gaps := (aMacroSimulationStep drones collect: [ :d |
		(aMacroSimulationStep gapAheadDrone: d) asFloat ]) asSortedCollection.
	uncovered := aMacroSimulationStep drones collect: [ :d |
		| raw |
		raw := (aMacroSimulationStep gapAheadDrone: d)
			- d captureRadius
			- (aMacroSimulationStep successorOf: d) captureRadius.
		raw max: 0.0 ].
	speeds := (aMacroSimulationStep drones collect: [ :d | d currentSpeed asFloat ]) asSortedCollection.
	totalUncovered := uncovered inject: 0.0 into: [ :sum :each | sum + each ].
	range := aMacroSimulationStep range asFloat.
	ratio := range <= 0.0 ifTrue: [ 1.0 ] ifFalse: [ 1.0 - (totalUncovered / range) ].
	ratio := (ratio max: 0.0) min: 1.0.
	perception := self perceptionSummaryOn: aMacroSimulationStep.

	tmp
		maxSpeed: speeds last asFloat;
		minSpeed: speeds first asFloat;
		avgSpeed: speeds average asFloat;
		stdSpeed: (self standardDeviationOf: speeds);
		maxGap: gaps last asFloat;
		minGap: gaps first asFloat;
		avgGap: gaps average asFloat;
		stdGap: (self standardDeviationOf: gaps);
		maxUncoveredGap: (uncovered ifEmpty: [ 0.0 ] ifNotEmpty: [ uncovered max asFloat ]);
		avgUncoveredGap: (uncovered ifEmpty: [ 0.0 ] ifNotEmpty: [ uncovered average asFloat ]);
		totalUncoveredLength: totalUncovered asFloat;
		coverageRatio: ratio asFloat;
		directPerceptionRatio: (perception at: #directRatio);
		angularPerceptionRatio: (perception at: #angularRatio);
		unobservablePerceptionRatio: (perception at: #unobservableRatio);
		outOfRangePerceptionRatio: (perception at: #outOfRangeRatio);
		avgGapEstimationError: (perception at: #avgError);
		maxGapEstimationError: (perception at: #maxError).
	^ tmp
]

{ #category : 'private - perception patrol v0.2' }
MacroSimulatorMetrics class >> perceptionSummaryOn: aStep [
	| observations total direct angular unobservable outOfRange errors |
	observations := OrderedCollection new.
	aStep drones do: [ :drone |
		observations add: (aStep perceptionAheadOf: drone).
		observations add: (aStep perceptionBackwardOf: drone) ].
	total := observations size max: 1.
	direct := observations count: [ :o | o isDirect ].
	angular := observations count: [ :o | o isAngular ].
	unobservable := observations count: [ :o | o isUnobservable ].
	outOfRange := observations count: [ :o | o isOutOfRange ].
	errors := (observations collect: [ :o | o absoluteGapError ]) reject: [ :e | e isNil ].
	^ Dictionary new
		at: #directRatio put: direct asFloat / total;
		at: #angularRatio put: angular asFloat / total;
		at: #unobservableRatio put: unobservable asFloat / total;
		at: #outOfRangeRatio put: outOfRange asFloat / total;
		at: #avgError put: (errors ifEmpty: [ 0.0 ] ifNotEmpty: [ errors average asFloat ]);
		at: #maxError put: (errors ifEmpty: [ 0.0 ] ifNotEmpty: [ errors max asFloat ]);
		yourself
]

{ #category : 'private - patrol extensions' }
MacroSimulatorMetrics class >> standardDeviationOf: aCollection [
	^ aCollection size < 2
		ifTrue: [ 0.0 ]
		ifFalse: [ aCollection standardDeviation asFloat ]
]

{ #category : 'comparing' }
MacroSimulatorMetrics >> = aValue [

	self class = aValue class ifFalse: [ ^ false ].


	self class instanceVariableNamesDo: [ :a |
			(self perform: a asSymbol) = (aValue perform: a asSymbol) ifFalse: [
				^ false ] ].
	^ true
]

{ #category : 'visiting' }
MacroSimulatorMetrics >> accept: aVisitor [ 

	^ aVisitor visitMacroSimulatorMetrics: self
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> angularPerceptionRatio [
	^ angularPerceptionRatio ifNil: [ 0.0 ]
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> angularPerceptionRatio: aNumber [
	angularPerceptionRatio := aNumber
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> avgGap [

	^ avgGap
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> avgGap: anObject [

	avgGap := anObject
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> avgGapEstimationError [
	^ avgGapEstimationError ifNil: [ 0.0 ]
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> avgGapEstimationError: aNumber [
	avgGapEstimationError := aNumber
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> avgSpeed [

	^ avgSpeed
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> avgSpeed: anObject [

	avgSpeed := anObject
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> avgUncoveredGap [
	^ avgUncoveredGap
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> avgUncoveredGap: anObject [
	avgUncoveredGap := anObject
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> coverageRatio [
	^ coverageRatio
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> coverageRatio: anObject [
	coverageRatio := anObject
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> directPerceptionRatio [
	^ directPerceptionRatio ifNil: [ 0.0 ]
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> directPerceptionRatio: aNumber [
	directPerceptionRatio := aNumber
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> fleetSize [

	^ fleetSize
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> fleetSize: anObject [

	fleetSize := anObject
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> gapInfo [
	^ { self maxGap. self minGap. self avgGap. self stdGap }
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> maxGap [

	^ maxGap
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> maxGap: anObject [

	maxGap := anObject
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> maxGapEstimationError [
	^ maxGapEstimationError ifNil: [ 0.0 ]
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> maxGapEstimationError: aNumber [
	maxGapEstimationError := aNumber
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> maxSpeed [

	^ maxSpeed
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> maxSpeed: anObject [

	maxSpeed := anObject
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> maxUncoveredGap [
	^ maxUncoveredGap
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> maxUncoveredGap: anObject [
	maxUncoveredGap := anObject
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> minGap [

	^ minGap
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> minGap: anObject [

	minGap := anObject
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> minSpeed [

	^ minSpeed
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> minSpeed: anObject [

	minSpeed := anObject
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> outOfRangePerceptionRatio [
	^ outOfRangePerceptionRatio ifNil: [ 0.0 ]
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> outOfRangePerceptionRatio: aNumber [
	outOfRangePerceptionRatio := aNumber
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> stdGap [

	^ stdGap
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> stdGap: anObject [

	stdGap := anObject
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> stdSpeed [

	^ stdSpeed
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> stdSpeed: anObject [

	stdSpeed := anObject
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> timeStep [
	^ timeStep
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> timeStep: anObject [
	timeStep := anObject
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> totalUncoveredLength [
	^ totalUncoveredLength
]

{ #category : 'accessing - patrol extensions' }
MacroSimulatorMetrics >> totalUncoveredLength: anObject [
	totalUncoveredLength := anObject
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> unobservablePerceptionRatio [
	^ unobservablePerceptionRatio ifNil: [ 0.0 ]
]

{ #category : 'accessing - perception patrol v0.2' }
MacroSimulatorMetrics >> unobservablePerceptionRatio: aNumber [
	unobservablePerceptionRatio := aNumber
]
