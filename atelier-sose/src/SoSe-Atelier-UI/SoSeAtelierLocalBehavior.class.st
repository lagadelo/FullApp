Class {
	#name : 'SoSeAtelierLocalBehavior',
	#superclass : 'MacroSimulatorBehavior',
	#instVars : [ 'lawName', 'command', 'distanceWeight' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierLocalBehavior class >> using: law settingsOf: behavior [
	^ self new
		policy: law id;
		pacingRate: behavior pacingRate;
		sensibility: behavior sensibility;
		initializeLaw: law
]

{ #category : 'initialization' }
SoSeAtelierLocalBehavior >> initializeLaw: law [
	lawName := law label.
	command := law compileBlock
]

{ #category : 'accessing' }
SoSeAtelierLocalBehavior >> lawName [ ^ lawName ]

{ #category : 'accessing' }
SoSeAtelierLocalBehavior >> distanceWeight: value [ distanceWeight := value ]

{ #category : 'running' }
SoSeAtelierLocalBehavior >> computeCommandsFor: step [
	| commands |
	commands := step drones collect: [ :drone |
		| input speed |
		input := SoSeAtelierLocalInput of: drone
			ahead: (step observedGapAheadDrone: drone)
			behind: (step observedGapBackwardDrone: drone)
			behavior: self.
		input distanceWeight: (distanceWeight ifNil: [ 2 ]).
		speed := command value: input.
		(speed isNumber and: [ speed asFloat isFinite ]) ifFalse: [
			self error: 'La loi « ', lawName, ' » doit renvoyer un déplacement fini en mètres par tik.' ].
		drone -> speed ].
	commands do: [ :each | each key currentSpeed: (each value max: each key minSpeed) ]
]
