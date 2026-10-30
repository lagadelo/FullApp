Class {
	#name : 'MacroSimulatorPoissonEventLaw',
	#superclass : 'MacroSimulatorEventLaw',
	#instVars : [
		'lambda'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorPoissonEventLaw class >> lambda: aNumberOrBlock [
	^ self new lambda: aNumberOrBlock; yourself
]

{ #category : 'sampling' }
MacroSimulatorPoissonEventLaw >> countAt: aTimeStep using: aRandom [
	"Knuth sampler. Intended here for rare-event rates per discrete simulation step."
	| currentLambda limit product k |
	currentLambda := self lambdaAt: aTimeStep.
	currentLambda = 0 ifTrue: [ ^ 0 ].
	limit := currentLambda negated exp.
	product := 1.0.
	k := 0.
	[ product > limit ] whileTrue: [
		k := k + 1.
		product := product * aRandom next ].
	^ k - 1
]

{ #category : 'accessing' }
MacroSimulatorPoissonEventLaw >> lambda [
	^ lambda
]

{ #category : 'accessing' }
MacroSimulatorPoissonEventLaw >> lambda: aNumberOrBlock [
	lambda := aNumberOrBlock
]

{ #category : 'sampling' }
MacroSimulatorPoissonEventLaw >> lambdaAt: aTimeStep [
	| value |
	value := (self lambda isKindOf: BlockClosure)
		ifTrue: [ self lambda value: aTimeStep ]
		ifFalse: [ self lambda ].
	^ value max: 0.0
]
