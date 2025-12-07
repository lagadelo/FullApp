Class {
	#name : 'ScenarioBuilder',
	#superclass : 'Object',
	#instVars : [
		'scenario',
		'timingMode',
		'spatialZones'
	],
	#category : 'DroneSystem-Evaluation-Perturbations',
	#package : 'DroneSystem-Evaluation-Perturbations'
}

{ #category : 'initialization' }
ScenarioBuilder >> initialize [
	super initialize.
	scenario := PerturbationScenario new.
	timingMode := #uniform.
	spatialZones := Dictionary new
]

{ #category : 'building' }
ScenarioBuilder >> named: aString [
	scenario named: aString.
	^ self
]

{ #category : 'building' }
ScenarioBuilder >> description: aString [
	scenario description: aString.
	^ self
]

{ #category : 'building' }
ScenarioBuilder >> timingMode: aSymbol [
	"Options: #uniform, #concentrated (début), #phased (par phase mission)"
	timingMode := aSymbol.
	^ self
]

{ #category : 'building' }
ScenarioBuilder >> destroyDroneId: anId at: aTimeStep [
	| event |
	event := DroneDestructionEvent new
		forDroneId: anId;
		at: aTimeStep.
	scenario addEvent: event.
	^ self
]

{ #category : 'building' }
ScenarioBuilder >> degradeDroneId: anId at: aTimeStep byRate: aRate [
	| event |
	event := DroneDegradationEvent new
		forDroneId: anId;
		at: aTimeStep;
		degradationRate: aRate.
	scenario addEvent: event.
	^ self
]

{ #category : 'building' }
ScenarioBuilder >> loseCommDroneId: anId at: aTimeStep forDuration: aDuration [
	| event |
	event := CommunicationLossEvent new
		forDroneId: anId;
		at: aTimeStep;
		duration: aDuration.
	scenario addEvent: event.
	^ self
]

{ #category : 'building' }
ScenarioBuilder >> build [
	^ scenario
]
