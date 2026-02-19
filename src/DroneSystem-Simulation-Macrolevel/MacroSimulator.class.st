Class {
	#name : 'MacroSimulator',
	#superclass : 'Object',
	#instVars : [
		'history',
		'behavior',
		'metrics',
		'parameters',
		'losses',
		'entrances'
	],
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
}

{ #category : 'instance creation' }
MacroSimulator class >> fromParameters: aMacroSimilatorParameters [

	^ self new
		  parameters: aMacroSimilatorParameters;
		  yourself
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

{ #category : 'accessing' }
MacroSimulator >> current [

^self history at: self history keys last
]

{ #category : 'fleet updates' }
MacroSimulator >> enter: aMacroSimulatorDrone at: aTimeStep [

	(self entrances at: aTimeStep ifAbsentPut: [ OrderedCollection new ])
		add: aMacroSimulatorDrone
]

{ #category : 'fleet updates' }
MacroSimulator >> enterancesAt: aTimeStep [

	^ self entrances at: aTimeStep ifAbsent: [ #(  ) ]
]

{ #category : 'fleet updates' }
MacroSimulator >> entrances [

	^ entrances
]

{ #category : 'fleet updates' }
MacroSimulator >> entrances: anObject [

	entrances := anObject
]

{ #category : 'accessing' }
MacroSimulator >> futureStep [

	| future t |
	t := self nextTimeStep.

	future := self current copy. "Now currentState"
	(self lossesAt: t) do: [ :id | future loseDroneID: id ].
	(self enterancesAt: t) do: [ :drone | future welcome: drone ].

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

{ #category : 'initialization' }
MacroSimulator >> initialize [

	self history: OrderedDictionary new.
	self entrances: OrderedDictionary new.
	self losses: OrderedDictionary new.
	self behavior: MacroSimulatorBehavior new
]

{ #category : 'fleet updates' }
MacroSimulator >> loose: id at: aTimeStep [

	(self losses at: aTimeStep ifAbsentPut: [ OrderedCollection new ])
		add: id
]

{ #category : 'fleet updates' }
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

{ #category : 'accessing' }
MacroSimulator >> nextTimeStep [

	^ self history keys last + 1
]

{ #category : 'accessing' }
MacroSimulator >> parameters [

	^ parameters
]

{ #category : 'accessing' }
MacroSimulator >> parameters: anObject [

	parameters := anObject
]

{ #category : 'stepping' }
MacroSimulator >> run: n [
n timesRepeat: [ self step] 
]

{ #category : 'as yet unclassified' }
MacroSimulator >> running [

	| current |
	self step. "Deepcopy of the previous state"
	current := self history last. "Now currentState"
	(self lossAt: current key) do: [ :id |
		current do: [ :elt | elt id = id ifTrue: [ elt die ] ] ]
]

{ #category : 'initialization' }
MacroSimulator >> start [ 
	| aMacroSimuklatorParameters |
	self parameters: aMacroSimuklatorParameters.
	self at:0 put: aMacroSimuklatorParameters generate.
	self behavior policy: aMacroSimuklatorParameters behavior
	
]

{ #category : 'initialization' }
MacroSimulator >> startWith: aMacroSimulatorParameters [

	self parameters: aMacroSimulatorParameters.
	self at: 0 put: (MacroSimulatorStep new applyParameters: aMacroSimulatorParameters  ).
	behavior policy: aMacroSimulatorParameters policy
]

{ #category : 'stepping' }
MacroSimulator >> step [

	| future |
	future := self futureStep.
	self behavior process:   future.
	future update.
	self at: self nextTimeStep put: future.
	self 
]
