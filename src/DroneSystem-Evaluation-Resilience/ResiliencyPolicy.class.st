Class {
	#name : 'ResiliencyPolicy',
	#superclass : 'Object',
	#instVars : [
		'policyName',
		'spareDroneActivationMode',
		'failureThreshold',
		'rebalancingStrategy',
		'rollbackOnFailure',
		'description',
		'parameters'
	],
	#category : 'DroneSystem-Evaluation-Resilience',
	#package : 'DroneSystem-Evaluation-Resilience'
}

{ #category : 'accessing' }
ResiliencyPolicy >> description: aString [
	description := aString.
	^ self
]

{ #category : 'accessing' }
ResiliencyPolicy >> failureThreshold [
	^ failureThreshold
]

{ #category : 'accessing' }
ResiliencyPolicy >> failureThreshold: aFloat [
	"Ratio d'actifs/total sous lequel la mission est compromise (0.0-1.0)"
	failureThreshold := aFloat.
	^ self
]

{ #category : 'initialization' }
ResiliencyPolicy >> initialize [
	super initialize.
	policyName := 'DefaultPolicy'.
	spareDroneActivationMode := #immediate.
	failureThreshold := 0.5.
	rebalancingStrategy := #redistribute.
	rollbackOnFailure := false.
	description := ''.
	parameters := Dictionary new
]

{ #category : 'accessing' }
ResiliencyPolicy >> param: key value: value [
	parameters at: key put: value.
	^ self
]

{ #category : 'accessing' }
ResiliencyPolicy >> policyName [
	^ policyName
]

{ #category : 'accessing' }
ResiliencyPolicy >> policyName: aString [
	policyName := aString.
	^ self
]

{ #category : 'printing' }
ResiliencyPolicy >> printOn: aStream [
	aStream nextPutAll: 'ResiliencyPolicy(';
		nextPutAll: policyName;
		nextPutAll: ', spare_mode=';
		nextPutAll: spareDroneActivationMode asString;
		nextPutAll: ', threshold=';
		nextPutAll: failureThreshold asString; nextPut: $)
]

{ #category : 'accessing' }
ResiliencyPolicy >> rebalancingStrategy [
	^ rebalancingStrategy
]

{ #category : 'accessing' }
ResiliencyPolicy >> rebalancingStrategy: aSymbol [
	"Options: #redistribute (recalc waypoints), #sequential (rotation), #none"
	rebalancingStrategy := aSymbol.
	^ self
]

{ #category : 'accessing' }
ResiliencyPolicy >> rollbackOnFailure [
	^ rollbackOnFailure
]

{ #category : 'accessing' }
ResiliencyPolicy >> rollbackOnFailure: aBoolean [
	rollbackOnFailure := aBoolean.
	^ self
]

{ #category : 'testing' }
ResiliencyPolicy >> shouldActivateSpare: resilienceRatio [
	spareDroneActivationMode = #immediate ifTrue: [ ^ true ].
	spareDroneActivationMode = #lazy ifTrue: [ ^ resilienceRatio <= failureThreshold ].
	^ false
]

{ #category : 'testing' }
ResiliencyPolicy >> shouldContinueMission: resilienceRatio [
	^ resilienceRatio > failureThreshold
]

{ #category : 'accessing' }
ResiliencyPolicy >> spareDroneActivationMode [
	^ spareDroneActivationMode
]

{ #category : 'accessing' }
ResiliencyPolicy >> spareDroneActivationMode: aSymbol [
	"Options: #immediate, #lazy (when needed), #never"
	spareDroneActivationMode := aSymbol.
	^ self
]
