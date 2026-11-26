Class {
	#name : 'MacroSimulatorBernoulliEventLaw',
	#superclass : 'MacroSimulatorEventLaw',
	#instVars : [
		'probability'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorBernoulliEventLaw class >> probability: aNumber [
	^ self new probability: aNumber; yourself
]

{ #category : 'sampling' }
MacroSimulatorBernoulliEventLaw >> countAt: aTimeStep using: aRandom [
	^ aRandom next < self probability ifTrue: [ 1 ] ifFalse: [ 0 ]
]

{ #category : 'accessing' }
MacroSimulatorBernoulliEventLaw >> probability [
	^ probability
]

{ #category : 'accessing' }
MacroSimulatorBernoulliEventLaw >> probability: aNumber [
	probability := (aNumber max: 0.0) min: 1.0
]
