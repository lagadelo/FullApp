Class {
	#name : 'MissionMetrics',
	#superclass : 'Object',
	#instVars : [
		'missionName',
		'snapshots',
		'scenario',
		'successCriterion',
		'missionSuccessful',
		'finalCoverage',
		'totalTime',
		'totalEnergyConsumed',
		'averageResilienceScore',
		'minResilienceScore',
		'droneDestructionCount'
	],
	#category : 'DroneSystem-Evaluation-Metrics',
	#package : 'DroneSystem-Evaluation-Metrics'
}

{ #category : 'adding' }
MissionMetrics >> addSnapshot: aSnapshot [
	snapshots add: aSnapshot.
	^ self
]

{ #category : 'accessing' }
MissionMetrics >> averageResilienceScore [
	^ averageResilienceScore
]

{ #category : 'accessing' }
MissionMetrics >> droneDestructionCount [
	^ droneDestructionCount
]

{ #category : 'accessing' }
MissionMetrics >> finalCoverage [
	^ finalCoverage
]

{ #category : 'finalization' }
MissionMetrics >> finalize [
	"Calcule les agrégats une fois la mission terminée"
	snapshots isEmpty ifTrue: [ ^ self ].
	
	| lastSnapshot allResilienceScores |
	lastSnapshot := snapshots last.
	totalTime := lastSnapshot timeStep.
	finalCoverage := lastSnapshot coveragePercentage.
	totalEnergyConsumed := snapshots inject: 0 into: [ :sum :snap | sum + snap energyConsumption ].
	
	"Calcul des scores de résilience"
	allResilienceScores := snapshots collect: [ :snap | snap resilienceScore ].
	averageResilienceScore := (allResilienceScores sum / allResilienceScores size) asFloat.
	minResilienceScore := allResilienceScores min.
	
	"Critère de succès"
	missionSuccessful := finalCoverage >= successCriterion
]

{ #category : 'initialization' }
MissionMetrics >> initialize [
	super initialize.
	missionName := 'Unknown'.
	snapshots := OrderedCollection new.
	scenario := nil.
	successCriterion := 80.0.
	missionSuccessful := false.
	finalCoverage := 0.0.
	totalTime := 0.
	totalEnergyConsumed := 0.0.
	averageResilienceScore := 0.0.
	minResilienceScore := 1.0.
	droneDestructionCount := 0
]

{ #category : 'accessing' }
MissionMetrics >> minResilienceScore [
	^ minResilienceScore
]

{ #category : 'accessing' }
MissionMetrics >> missionName: aString [
	missionName := aString.
	^ self
]

{ #category : 'accessing' }
MissionMetrics >> missionSuccessful [
	^ missionSuccessful
]

{ #category : 'printing' }
MissionMetrics >> printOn: aStream [
	aStream nextPutAll: 'MissionMetrics('; 
		nextPutAll: missionName; 
		nextPutAll: ', success='; 
		nextPutAll: missionSuccessful asString;
		nextPutAll: ', coverage='; 
		nextPutAll: finalCoverage asString;
		nextPutAll: '%, resilience=';
		nextPutAll: averageResilienceScore asString; nextPut: $)
]

{ #category : 'accessing' }
MissionMetrics >> scenario: aPerturbationScenario [
	scenario := aPerturbationScenario.
	^ self
]

{ #category : 'accessing' }
MissionMetrics >> snapshots [
	^ snapshots
]

{ #category : 'accessing' }
MissionMetrics >> successCriterion: aFloat [
	successCriterion := aFloat.
	^ self
]

{ #category : 'accessing' }
MissionMetrics >> totalEnergyConsumed [
	^ totalEnergyConsumed
]

{ #category : 'accessing' }
MissionMetrics >> totalTime [
	^ totalTime
]
