Class {
	#name : 'MissionEvaluationScenario',
	#superclass : 'Object',
	#instVars : [
		'scenarioName',
		'perturbationScenario',
		'resiliencyPolicy',
		'codeDeployments',
		'successCriteria',
		'numberOfRuns',
		'randomSeed'
	],
	#category : 'DroneSystem-Evaluation-Framework',
	#package : 'DroneSystem-Evaluation-Framework'
}

{ #category : 'adding' }
MissionEvaluationScenario >> addCodeDeployment: aCodeVersion [
	codeDeployments add: aCodeVersion.
	^ self
]

{ #category : 'accessing' }
MissionEvaluationScenario >> codeDeployments [
	^ codeDeployments
]

{ #category : 'initialization' }
MissionEvaluationScenario >> initialize [
	super initialize.
	scenarioName := 'UnnamedEvaluation'.
	perturbationScenario := nil.
	resiliencyPolicy := nil.
	codeDeployments := OrderedCollection new.
	successCriteria := 80.0.
	numberOfRuns := 1.
	randomSeed := nil
]

{ #category : 'accessing' }
MissionEvaluationScenario >> numberOfRuns [
	^ numberOfRuns
]

{ #category : 'accessing' }
MissionEvaluationScenario >> numberOfRuns: anInteger [
	numberOfRuns := anInteger.
	^ self
]

{ #category : 'accessing' }
MissionEvaluationScenario >> perturbationScenario [
	^ perturbationScenario
]

{ #category : 'accessing' }
MissionEvaluationScenario >> perturbationScenario: aPerturbationScenario [
	perturbationScenario := aPerturbationScenario.
	^ self
]

{ #category : 'printing' }
MissionEvaluationScenario >> printOn: aStream [
	aStream nextPutAll: 'MissionEvaluationScenario(';
		nextPutAll: scenarioName;
		nextPutAll: ', runs=';
		nextPutAll: numberOfRuns asString;
		nextPutAll: ', policy=';
		nextPutAll: (resiliencyPolicy notNil ifTrue: [ resiliencyPolicy policyName ] ifFalse: [ 'None' ]);
		nextPut: $)
]

{ #category : 'accessing' }
MissionEvaluationScenario >> randomSeed [
	^ randomSeed
]

{ #category : 'accessing' }
MissionEvaluationScenario >> randomSeed: anInteger [
	randomSeed := anInteger.
	^ self
]

{ #category : 'accessing' }
MissionEvaluationScenario >> resiliencyPolicy [
	^ resiliencyPolicy
]

{ #category : 'accessing' }
MissionEvaluationScenario >> resiliencyPolicy: aResiliencyPolicy [
	resiliencyPolicy := aResiliencyPolicy.
	^ self
]

{ #category : 'accessing' }
MissionEvaluationScenario >> scenarioName [
	^ scenarioName
]

{ #category : 'accessing' }
MissionEvaluationScenario >> scenarioName: aString [
	scenarioName := aString.
	^ self
]

{ #category : 'accessing' }
MissionEvaluationScenario >> successCriteria [
	^ successCriteria
]

{ #category : 'accessing' }
MissionEvaluationScenario >> successCriteria: aFloat [
	successCriteria := aFloat.
	^ self
]
