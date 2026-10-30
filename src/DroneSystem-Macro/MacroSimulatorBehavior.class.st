"
This class describes the evolution of the system. Keep in mind, this is a fully distributed architecture. Each drone only perceives its two neighbours.

MacroSimulatorBehavior has 3 instance variables:
- the policy : which is a symbol, this message returns a bloc to be process to compute the evolution
- sensibility : which is intended to limit oscillation by accepting some non optimal values as correct ones
- pacing rate : which is used to push current speed to nominal speed is the drone is well balanced versus its two neighbours.
"
Class {
	#name : 'MacroSimulatorBehavior',
	#superclass : 'Object',
	#instVars : [
		'policy',
		'sensibility',
		'pacingRate'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance' }
MacroSimulatorBehavior class >> from: anExportFormat [
	"self from:{#policy . #capingPolicy . #sensibility . 0.005 . #pacingRate . 0.95}"

	| tmp |
	tmp := self new.
	1 to: anExportFormat size by: 2 do: [ :index |
			tmp
				perform: ((anExportFormat at: index) , ':') asSymbol
				with: (anExportFormat at: index + 1) ].
	^ tmp
]

{ #category : 'visiting' }
MacroSimulatorBehavior >> accept: aVisitor [ 

	^ aVisitor visitMacroSimulatorBehavior: self
]

{ #category : 'policies' }
MacroSimulatorBehavior >> binaryPolicy [
	^ [ :aStep |
		| localSensibility |
		localSensibility := 0.1.
		aStep drones do: [ :a |
			self withObservedGapsOf: a in: aStep do: [ :ga :gb |
				ga > gb ifTrue: [ a currentSpeed: a maxSpeed ].
				ga < gb ifTrue: [ a currentSpeed: 0 ].
				ga = 0 ifFalse: [
					(ga - gb) abs / ga < localSensibility
						ifTrue: [ a currentSpeed: a nominalSpeed ] ] ] ] ]
]

{ #category : 'policies' }
MacroSimulatorBehavior >> capingPolicy [
	^ [ :aStep |
		aStep drones do: [ :a |
			self withObservedGapsOf: a in: aStep do: [ :ga :gb |
				| weight ratio denominator |
				denominator := ga max: gb.
				weight := denominator = 0
					ifTrue: [ 0.0 ]
					ifFalse: [ ((ga - gb) / denominator) asFloat ].
				ratio := weight abs < self sensibility
					ifTrue: [ self pacingRate ]
					ifFalse: [ weight * 2 + 1 ].
				a currentSpeed:
					(((a currentSpeed * ratio roundUpTo: 0.1) min: a maxSpeed)
						max: a minSpeed) ] ] ]
]

{ #category : 'running - patrol extensions' }
MacroSimulatorBehavior >> computeCommandsFor: aStep [
	"Compute speed commands without advancing positions."
	(self perform: self policy) value: aStep
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> default [ 

	^ self perform: self defaultLabel
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> defaultLabel [

	^ #binaryPolicy
]

{ #category : 'export' }
MacroSimulatorBehavior >> export [
	"Behavior description. Usefull for simulation export
	cf. from: class method"

	^ {
		  #policy.
		  policy.
		  #sensibility.
		  sensibility.
		  #pacingRate.
		  pacingRate }
]

{ #category : 'export' }
MacroSimulatorBehavior >> exportName [

	^ self policy , '_' , self sensibility printString , '_'
	  , self pacingRate printString
]

{ #category : 'initialization' }
MacroSimulatorBehavior >> initialize [

	super initialize.
	sensibility := 0.005.
	pacingRate := 0.95
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> pacingRate [

	^ pacingRate
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> pacingRate: anObject [

	pacingRate := anObject
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> policy [

	^ policy
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> policy: anObject [

	policy := anObject
]

{ #category : 'running' }
MacroSimulatorBehavior >> process: aStep [
	"Legacy-compatible behavior: compute commands and advance the step once.
	MacroSimulator>>step currently advances once again afterwards.
	Use MacroSimulator>>stepSingleUpdate for the corrected one-movement semantics."
	self computeCommandsFor: aStep.
	aStep update
]

{ #category : 'policies' }
MacroSimulatorBehavior >> revisedCapingPolicy [
	^ [ :aStep |
		aStep drones do: [ :a |
			self withObservedGapsOf: a in: aStep do: [ :ga :gb |
				| weight newSpeed denominator |
				denominator := ga max: gb.
				weight := denominator = 0
					ifTrue: [ 0.0 ]
					ifFalse: [ ((ga - gb) / denominator) asFloat ].
				newSpeed := weight abs < self sensibility
					ifTrue: [
						a currentSpeed
							+ ((a nominalSpeed - a currentSpeed) * self pacingRate) ]
					ifFalse: [
						((a currentSpeed * (weight * 2 + 1) roundUpTo: 0.1)
							min: a maxSpeed) max: a minSpeed ].
				a currentSpeed: newSpeed ] ] ]
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> sensibility [

	^ sensibility
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> sensibility: anObject [

	sensibility := anObject
]

{ #category : 'policies' }
MacroSimulatorBehavior >> weightedPolicy [
	^ [ :aStep |
		sensibility := 0.1.
		aStep drones do: [ :a |
			self withObservedGapsOf: a in: aStep do: [ :ga :gb |
				| ratio denominator |
				denominator := ga + gb.
				ratio := denominator = 0
					ifTrue: [ 1.0 ]
					ifFalse: [ 1 + ((ga - gb) / denominator) asFloat ].
				a currentSpeed:
					(((a currentSpeed * ratio roundUpTo: 0.1) min: a maxSpeed) max: 0) ] ] ]
]

{ #category : 'private - patrol v0.2' }
MacroSimulatorBehavior >> withObservedGapsOf: aDrone in: aStep do: aTwoArgumentBlock [
	| ga gb |
	ga := aStep observedGapAheadDrone: aDrone.
	gb := aStep observedGapBackwardDrone: aDrone.
	(ga isNil or: [ gb isNil ]) ifTrue: [ ^ false ].
	aTwoArgumentBlock value: ga value: gb.
	^ true
]
