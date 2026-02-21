Class {
	#name : 'MacroSimulatorBehavior',
	#superclass : 'Object',
	#instVars : [
		'policy'
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
		  | sensibility pacingRate weight |
		  sensibility := 0.01.
		  pacingRate := 0.95.



		  aStep drones do: [ :a |
				  | ga gb ratio |
				  ga := aStep gapAheadDrone: a.
				  gb := aStep gapBackwardDrone: a.

				  weight := (ga - gb / (ga + gb)) asFloat.
				  ratio := weight abs < sensibility
					           ifTrue: [ pacingRate ]
					           ifFalse: [ 1 + weight ].
				  a currentSpeed:
					  (((a currentSpeed * ratio roundUpTo: 0.1) min: a maxSpeed)
						   max: a nominalSpeed * 0.5) ] ]
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> default [

	^ self perform: self defaultLabel
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> defaultLabel [

	^ #'binaryolicy'
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
