Class {
	#name : 'MacroSimulatorEventLaw',
	#superclass : 'Object',
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'sampling' }
MacroSimulatorEventLaw >> countAt: aTimeStep using: aRandom [
	self subclassResponsibility
]
