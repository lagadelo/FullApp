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
		'fleetSize'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorMetrics class >> on: aMacroSimulationStep [

	| tmp gaps uncovered speeds |
	tmp := self new.
	tmp fleetSize: aMacroSimulationStep drones size.
	"tmp index: aMacroSimulationStep timeStep."

	gaps := (aMacroSimulationStep drones collect: [ :d |
		         (aMacroSimulationStep gapAheadDrone: d) asFloat ])
		        asSortedCollection.
	uncovered := aMacroSimulationStep drones collect: [ :d |
			             ((aMacroSimulationStep gapAheadDrone: d)
			              - d sensingRadius
			              - (aMacroSimulationStep successorOf: d) sensingRadius)
				             asFloat ].

	speeds := (aMacroSimulationStep drones collect: [ :d |
		           d currentSpeed asFloat ]) asSortedCollection.
	tmp maxSpeed: speeds last asFloat.
	tmp minSpeed: speeds first asFloat.
	tmp avgSpeed: speeds average asFloat.
	tmp stdSpeed: speeds standardDeviation.
	tmp maxGap: gaps last asFloat.
	tmp minGap: gaps first asFloat.
	tmp avgGap: gaps average asFloat.
	tmp stdGap: gaps standardDeviation.
	^ tmp
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

{ #category : 'accessing' }
MacroSimulatorMetrics >> avgGap [

	^ avgGap
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> avgGap: anObject [

	avgGap := anObject
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> avgSpeed [

	^ avgSpeed
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> avgSpeed: anObject [

	avgSpeed := anObject
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

	^ self maxGap , self minGap , self avgGap , self stdGap
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> maxGap [

	^ maxGap
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> maxGap: anObject [

	maxGap := anObject
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> maxSpeed [

	^ maxSpeed
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> maxSpeed: anObject [

	maxSpeed := anObject
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
