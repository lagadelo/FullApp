Class {
	#name : 'MetricsCollector',
	#superclass : 'Object',
	#instVars : [
		'simulator',
		'runs',
		'currentMetrics',
		'perturbationEngine'
	],
	#category : 'DroneSystem-Evaluation-Metrics',
	#package : 'DroneSystem-Evaluation-Metrics'
}

{ #category : 'accessing' }
MetricsCollector >> bindPerturbationEngine: aPerturbationEngine [
	perturbationEngine := aPerturbationEngine.
	^ self
]

{ #category : 'accessing' }
MetricsCollector >> bindSimulator: aSimulator [
	simulator := aSimulator.
	^ self
]

{ #category : 'collection' }
MetricsCollector >> captureSnapshot [
	| snapshot coverage energyConsumed activeDrones totalDrones dronePositions |
	simulator notNil ifTrue: [
		activeDrones := simulator activeDroneCount ifNil: [ 0 ].
		totalDrones := simulator totalDroneCount ifNil: [ 1 ].
		coverage := simulator currentCoverage ifNil: [ 0.0 ].
		energyConsumed := simulator energyConsumedThisStep ifNil: [ 0.0 ].
		dronePositions := simulator captureAllDronePositions ifNil: [ OrderedCollection new ].
		
		snapshot := MissionSnapshot new
			timeStep: (simulator currentTime ifNil: [ 0 ]);
			activeDroneCount: activeDrones;
			totalDroneCount: totalDrones;
			coveragePercentage: coverage;
			energyConsumption: energyConsumed;
			dronePositions: dronePositions;
			missionPhase: (simulator currentPhase ifNil: [ #unknown ]);
			perturbationEventsCount: (perturbationEngine notNil 
				ifTrue: [ perturbationEngine executedEvents size ] 
				ifFalse: [ 0 ]).
		
		currentMetrics addSnapshot: snapshot
	].
	^ self
]

{ #category : 'execution' }
MetricsCollector >> endRun [
	currentMetrics notNil ifTrue: [
		currentMetrics finalize.
		runs add: currentMetrics
	].
	currentMetrics := nil.
	^ self
]

{ #category : 'initialization' }
MetricsCollector >> initialize [
	super initialize.
	simulator := nil.
	runs := OrderedCollection new.
	currentMetrics := nil.
	perturbationEngine := nil
]

{ #category : 'accessing' }
MetricsCollector >> runs [
	^ runs
]

{ #category : 'accessing' }
MetricsCollector >> runs: aCollection [
	runs := aCollection.
	^ self
]

{ #category : 'execution' }
MetricsCollector >> startRun: missionName withScenario: scenario successCriteria: criterion [
	currentMetrics := MissionMetrics new
		missionName: missionName;
		scenario: scenario;
		successCriterion: criterion.
	^ self
]
