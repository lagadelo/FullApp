Class {
	#name : 'PerturbationScenario',
	#superclass : 'Object',
	#instVars : [
		'name',
		'events',
		'description'
	],
	#category : 'DroneSystem-Evaluation-Perturbations',
	#package : 'DroneSystem-Evaluation-Perturbations'
}

{ #category : 'adding' }
PerturbationScenario >> addEvent: aPerturbationEvent [
	events add: aPerturbationEvent.
	^ self
]

{ #category : 'accessing' }
PerturbationScenario >> description: aString [
	description := aString.
	^ self
]

{ #category : 'accessing' }
PerturbationScenario >> events [
	^ events
]

{ #category : 'initialization' }
PerturbationScenario >> initialize [
	super initialize.
	name := 'UnnamedScenario'.
	events := OrderedCollection new.
	description := ''
]

{ #category : 'accessing' }
PerturbationScenario >> name [
	^ name
]

{ #category : 'accessing' }
PerturbationScenario >> named: aString [
	name := aString.
	^ self
]

{ #category : 'printing' }
PerturbationScenario >> printOn: aStream [
	aStream nextPutAll: 'PerturbationScenario('; nextPutAll: name; nextPut: $)
]
