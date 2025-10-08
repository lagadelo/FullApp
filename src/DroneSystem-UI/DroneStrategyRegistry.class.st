Class {
	#name : 'DroneStrategyRegistry',
	#superclass : 'Object',
	#instVars : [
		'strategies'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'initialization' }
DroneStrategyRegistry >> availableStrategyClasses [
    ^ strategies
]

{ #category : 'initialization' }
DroneStrategyRegistry >> initialize [
    strategies := {
        (Smalltalk at: #SurveillanceCompositeStrategy ifAbsent: [ nil ]).
        (Smalltalk at: #AllInterceptStrategy ifAbsent: [ nil ]).
        (Smalltalk at: #ClosestDroneInterceptStrategy ifAbsent: [ nil ]).
        (Smalltalk at: #BestPerceptionStrategy ifAbsent: [ nil ]).
        (Smalltalk at: #HybridStrategy ifAbsent: [ nil ])
    } reject: [ :c | c isNil ].

]
