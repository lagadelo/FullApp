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
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
}

{ #category : 'instance creation' }
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

{ #category : 'accessing' }
MacroSimulatorBehavior >> binaryPolicy [


^[:aStep |
"aStep comes from a former deepCopy. This copy has been pre updated with losses and addons"
	| sensibility |
	sensibility := 0.1.



	aStep drones do: [ :a |
			| ga gb |
			ga := aStep gapAheadDrone: a.
			gb := aStep gapBackwardDrone: a.
			ga > gb ifTrue: [ a currentSpeed: a maxSpeed ].
			ga < gb ifTrue: [ a currentSpeed: 0 ].
			(ga - gb) abs / ga < sensibility ifTrue: [ a currentSpeed: a nominalSpeed ] ]]
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> capingPolicy [

	^ [ :aStep | "aStep comes from a former deepCopy. This copy has been pre updated with losses and addons"
		  | weight |
		  aStep drones do: [ :a |
				  | ga gb ratio |
				  ga := aStep gapAheadDrone: a.
				  gb := aStep gapBackwardDrone: a.

				  weight := (ga - gb / (ga max: gb)) asFloat.
				  "	weight <0 ifTrue:[self halt] ."
				  ratio := weight abs < self sensibility
					           ifTrue: [ self pacingRate ]
					           ifFalse: [ weight * 2 + 1 ].
				  a currentSpeed:
					  (((a currentSpeed * ratio roundUpTo: 0.1) min: a maxSpeed)
						   max: a minSpeed) ] ]
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> default [

	^ self perform: self defaultLabel
]

{ #category : 'initialize-release' }
MacroSimulatorBehavior >> defaultLabel [

	^ #'binaryPolicy'
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

{ #category : 'initialize-release' }
MacroSimulatorBehavior >> initialize [ 

		  sensibility := 0.005.
		  pacingRate := 0.95.
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

{ #category : 'accessing' }
MacroSimulatorBehavior >> process: aStep [  
	  (self perform: self policy) value: aStep.
	aStep update
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> revisedCapingPolicy [

	^ [ :aStep | "aStep comes from a former deepCopy. This copy has been pre updated with losses and addons"
		  | weight |
		  aStep drones do: [ :a |
				  | ga gb ratio newSpeed |
				  ga := aStep gapAheadDrone: a.
				  gb := aStep gapBackwardDrone: a.

				  weight := (ga - gb / (ga max: gb)) asFloat.
				  "	weight <0 ifTrue:[self halt] ."
				  newSpeed := weight abs < self sensibility
					              ifTrue: [ "smooth adaptation"
						              a currentSpeed
						              +
						              (a nominalSpeed - a currentSpeed * self pacingRate) ]
					              ifFalse: [  
							              ((a currentSpeed * (weight * 2 + 1) roundUpTo:
								                0.1) min: a maxSpeed) max: a minSpeed ].


				  a currentSpeed: newSpeed ] ]
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> sensibility [

	^ sensibility
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> sensibility: anObject [

	sensibility := anObject
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> weightedPolicy [

	^ [ :aStep | "aStep comes from a former deepCopy. This copy has been pre updated with losses and addons"
		 
		  sensibility := 0.1.



		  aStep drones do: [ :a |
				  | ga gb ratio |
				  ga := aStep gapAheadDrone: a.
				  gb := aStep gapBackwardDrone: a.
				  ratio := 1 + ((ga - gb) / (ga +gb)) asFloat.
				  a currentSpeed: ((((a currentSpeed   * ratio) roundUpTo: 0.1) min: a maxSpeed) max:0) ] ]
]
