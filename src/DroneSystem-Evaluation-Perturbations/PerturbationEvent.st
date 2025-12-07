Class {
	#name : 'PerturbationEvent',
	#superclass : 'Object',
	#instVars : [
		'timeStep',
		'droneId',
		'eventType',
		'parameters'
	],
	#category : 'DroneSystem-Evaluation-Perturbations',
	#package : 'DroneSystem-Evaluation-Perturbations'
}

{ #category : 'initialization' }
PerturbationEvent >> initialize [
	super initialize.
	timeStep := 0.
	droneId := nil.
	eventType := #unknown.
	parameters := Dictionary new
]

{ #category : 'accessing' }
PerturbationEvent >> at: aTimeStep [
	timeStep := aTimeStep.
	^ self
]

{ #category : 'accessing' }
PerturbationEvent >> forDroneId: anId [
	droneId := anId.
	^ self
]

{ #category : 'accessing' }
PerturbationEvent >> type: aSymbol [
	eventType := aSymbol.
	^ self
]

{ #category : 'accessing' }
PerturbationEvent >> param: key value: value [
	parameters at: key put: value.
	^ self
]

{ #category : 'accessing' }
PerturbationEvent >> timeStep [
	^ timeStep
]

{ #category : 'accessing' }
PerturbationEvent >> droneId [
	^ droneId
]

{ #category : 'accessing' }
PerturbationEvent >> eventType [
	^ eventType
]

{ #category : 'accessing' }
PerturbationEvent >> parameters [
	^ parameters
]

{ #category : 'printing' }
PerturbationEvent >> printOn: aStream [
	aStream nextPutAll: 'PerturbationEvent(';
		nextPutAll: eventType asString; nextPutAll: ', drone:';
		nextPutAll: droneId asString; nextPutAll: ', @t=';
		nextPutAll: timeStep asString; nextPut: $)
]
