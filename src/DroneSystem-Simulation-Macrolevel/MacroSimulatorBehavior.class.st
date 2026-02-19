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
MacroSimulatorBehavior >> binaryProcess [ 


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
MacroSimulatorBehavior >> default [

	^ self perform: self defaultLabel
]

{ #category : 'accessing' }
MacroSimulatorBehavior >> defaultLabel [

	^ #'binaryProcess'
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
MacroSimulatorBehavior >> weightedProcess [

	^ [ :aStep | "aStep comes from a former deepCopy. This copy has been pre updated with losses and addons"
		  | sensibility |
		  sensibility := 0.1.



		  aStep drones do: [ :a |
				  | ga gb ratio |
				  ga := aStep gapAhead: a.
				  gb := aStep gapBackwardDrone: a.
				  ratio := ga - gb / ga.
				  a currentSpeed: a nominalSpeed speed * ratio ] ]
]
