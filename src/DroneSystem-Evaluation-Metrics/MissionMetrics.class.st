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
