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
						   max: a nominalSpeed) ] ]
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
		  | sensibility |
		  sensibility := 0.1.



		  aStep drones do: [ :a |
				  | ga gb ratio |
				  ga := aStep gapAheadDrone: a.
				  gb := aStep gapBackwardDrone: a.
				  ratio := 1 + ((ga - gb) / (ga +gb)) asFloat.
				  a currentSpeed: ((((a currentSpeed   * ratio) roundUpTo: 0.1) min: a maxSpeed) max:0) ] ]
]
