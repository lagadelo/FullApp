Class {
	#name : 'StochasticParam',
	#superclass : 'Object',
	#instVars : [
		'distType',
		'paramA',
		'paramB',
		'rng'
	],
	#category : 'DroneHandoff',
	#package : 'DroneHandoff'
}

{ #category : 'instance creation' }
StochasticParam class >> fixed: aValue [
	"Valeur déterministe — stddev 0"

	^ self normal: aValue stddev: 0
]

{ #category : 'instance creation' }
StochasticParam class >> normal: aMean stddev: aStddev [

	^ self new
		  distType: #normal;
		  paramA: aMean;
		  paramB: aStddev;
		  yourself
]

{ #category : 'instance creation' }
StochasticParam class >> uniform: aMin to: aMax [

	^ self new
		  distType: #uniform;
		  paramA: aMin;
		  paramB: aMax;
		  yourself
]

{ #category : 'accessing' }
StochasticParam >> distType [

	^ distType
]

{ #category : 'accessing' }
StochasticParam >> distType: anObject [

	distType := anObject
]

{ #category : 'initializing' }
StochasticParam >> initialize [ 

    rng := Random new
]

{ #category : 'initializing' }
StochasticParam >> initialize: aSeed [
	"Obligatoire pour replay deterministe"

	rng := Random new: aSeed
]

{ #category : 'accessing' }
StochasticParam >> paramA [

	^ paramA
]

{ #category : 'accessing' }
StochasticParam >> paramA: anObject [

	paramA := anObject
]

{ #category : 'accessing' }
StochasticParam >> paramB [

	^ paramB
]

{ #category : 'accessing' }
StochasticParam >> paramB: anObject [

	paramB := anObject
]

{ #category : 'accessing' }
StochasticParam >> rng [

	^ rng
]

{ #category : 'accessing' }
StochasticParam >> rng: anObject [

	rng := anObject
]

{ #category : 'sampling' }
StochasticParam >> sample [ 
    "Tire une valeur selon la distribution définie, jamais négative"
    | value |
    value := distType = #uniform
        ifTrue:  [ paramA + (rng next * (paramB - paramA)) ]
        ifFalse: [ self sampleNormal ].
    ^ value max: 0.0

]

{ #category : 'sampling' }
StochasticParam >> sampleNormal [
	"Box-Muller transform → N(paramA, paramB²)"

	| u1 u2 |
	paramB = 0 ifTrue: [ ^ paramA ].
	u1 := rng next max: 1e-12. "évite log(0)"
	u2 := rng next.
	^ paramA + (paramB * (-2.0 * u1 ln) sqrt * (2.0 * Float pi * u2) cos)
]
