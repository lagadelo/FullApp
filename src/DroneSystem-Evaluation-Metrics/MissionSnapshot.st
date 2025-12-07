Class {
	#name : 'MissionSnapshot',
	#superclass : 'Object',
	#instVars : [
		'timeStep',
		'activeDroneCount',
		'totalDroneCount',
		'coveragePercentage',
		'energyConsumption',
		'dronePositions',
		'missionPhase',
		'wayPointsCovered',
		'perturbationEventsCount'
	],
	#category : 'DroneSystem-Evaluation-Metrics',
	#package : 'DroneSystem-Evaluation-Metrics'
}

{ #category : 'initialization' }
MissionSnapshot >> initialize [
	super initialize.
	timeStep := 0.
	activeDroneCount := 0.
	totalDroneCount := 0.
	coveragePercentage := 0.0.
	energyConsumption := 0.0.
	dronePositions := OrderedCollection new.
	missionPhase := #unknown.
	wayPointsCovered := 0.
	perturbationEventsCount := 0
]

{ #category : 'accessing' }
MissionSnapshot >> timeStep: anInteger [
	timeStep := anInteger.
	^ self
]

{ #category : 'accessing' }
MissionSnapshot >> activeDroneCount: anInteger [
	activeDroneCount := anInteger.
	^ self
]

{ #category : 'accessing' }
MissionSnapshot >> totalDroneCount: anInteger [
	totalDroneCount := anInteger.
	^ self
]

{ #category : 'accessing' }
MissionSnapshot >> coveragePercentage: aFloat [
	coveragePercentage := aFloat.
	^ self
]

{ #category : 'accessing' }
MissionSnapshot >> energyConsumption: aFloat [
	energyConsumption := aFloat.
	^ self
]

{ #category : 'accessing' }
MissionSnapshot >> dronePositions: aCollection [
	dronePositions := aCollection.
	^ self
]

{ #category : 'accessing' }
MissionSnapshot >> missionPhase: aSymbol [
	missionPhase := aSymbol.
	^ self
]

{ #category : 'accessing' }
MissionSnapshot >> wayPointsCovered: anInteger [
	wayPointsCovered := anInteger.
	^ self
]

{ #category : 'accessing' }
MissionSnapshot >> perturbationEventsCount: anInteger [
	perturbationEventsCount := anInteger.
	^ self
]

{ #category : 'computing' }
MissionSnapshot >> resilienceScore [
	"Ratio: drones actifs / drones initiaux"
	totalDroneCount = 0 ifTrue: [ ^ 0.0 ].
	^ (activeDroneCount / totalDroneCount) asFloat
]

{ #category : 'printing' }
MissionSnapshot >> printOn: aStream [
	aStream nextPutAll: 'MissionSnapshot(t='; 
		nextPutAll: timeStep asString; 
		nextPutAll: ', coverage='; 
		nextPutAll: coveragePercentage asString;
		nextPutAll: '%, resilience=';
		nextPutAll: self resilienceScore asString; nextPut: $)
]
