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
		'index'
	],
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
}

{ #category : 'instance creation' }
MacroSimulatorMetrics class >> on: aMacroSimulationStep [

	| tmp gaps uncovered speeds |
	tmp := self new.  
	tmp fleetSize: aMacroSimulationStep drones size.
	tmp index: aMacroSimulationStep timeStep.

	gaps := (aMacroSimulationStep drones collect: [ :d |
		         (aMacroSimulationStep gapAheadDrone: d ) asFloat]) asSortedCollection.
	uncovered := aMacroSimulationStep drones collect: [ :d |
			           (  (aMacroSimulationStep gapAheadDrone: d)
			             - d sensingRadius
			             - (aMacroSimulationStep successorOf: d) sensingRadius) asFloat].
 
	speeds := (aMacroSimulationStep drones collect: [ :d |
		           d currentSpeed asFloat]) asSortedCollection.
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
MacroSimulatorMetrics >> index [

	^ index
]

{ #category : 'accessing' }
MacroSimulatorMetrics >> index: anObject [

	index := anObject
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
