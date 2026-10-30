Class {
	#name : 'MacroSimulatorPatrolExamples',
	#superclass : 'Object',
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'scenarios' }
MacroSimulatorPatrolExamples class >> allDistanceLostThenRestored [
	| simulator |
	simulator := (self parametersWithDrones: 8) initializeSimulator.
	simulator perceptionModel: MacroSimulatorHybridPerception new.
	simulator scheduleAllDistanceMeasurementAvailable: false at: 25.
	simulator scheduleAllDistanceMeasurementAvailable: true at: 85.
	simulator runSingleUpdate: 140.
	^ simulator
]

{ #category : 'scenarios' }
MacroSimulatorPatrolExamples class >> nominalDirect [
	| simulator |
	simulator := (self parametersWithDrones: 8) initializeSimulator.
	simulator perceptionModel: MacroSimulatorHybridPerception new.
	simulator runSingleUpdate: 120.
	^ simulator
]

{ #category : 'scenarios' }
MacroSimulatorPatrolExamples class >> oneDroneDestroyedInArcZone [
	| simulator start stop |
	simulator := (self parametersWithDrones: 10) initializeSimulator.
	simulator perceptionModel: MacroSimulatorHybridPerception new.
	start := simulator parameters totalDistance * 0.20.
	stop := simulator parameters totalDistance * 0.35.
	simulator
		destroyOneDroneAt: 50
		matching: [ :drone | | s | s := drone position \ simulator parameters totalDistance. s >= start and: [ s <= stop ] ]
		stream: #lossTarget.
	simulator runSingleUpdate: 140.
	^ simulator
]

{ #category : 'route' }
MacroSimulatorPatrolExamples class >> parametersWithDrones: droneCount [
	| p |
	p := MacroSimulatorParameters new.
	p
		seed: 424242;
		numberOfDrones: droneCount;
		nominalSpeed: 0.02;
		minSpeed: 0.01;
		maxSpeed: 0.03;
		sensingRadius: 3.0;
		captureRadius: 0.8;
		policy: #revisedCapingPolicy;
		wayPoints: self smallHull.
	^ p
]

{ #category : 'analysis' }
MacroSimulatorPatrolExamples class >> playAndExportTo: aDirectoryName [
	"Creates four replayable scenarios and exports CSV + SVG + TikZ for the most useful fields."
	| exporter scenarios results |
	exporter := MacroSimulatorResultExporter directoryName: aDirectoryName.
	scenarios := {
		#nominal -> self nominalDirect.
		#degraded -> self allDistanceLostThenRestored.
		#destroyed -> self oneDroneDestroyedInArcZone.
		#probabilistic -> self probabilisticDistanceLosses }.
	results := OrderedCollection new.
	scenarios do: [ :association |
		| simulator base |
		base := association key asString.
		simulator := association value.
		results add: association key -> (self summaryOf: simulator).
		exporter
			exportRun: simulator
			named: base
			fields: #( maxGap coverageRatio angularPerceptionRatio unobservablePerceptionRatio maxGapEstimationError ) ].
	^ results
]

{ #category : 'scenarios' }
MacroSimulatorPatrolExamples class >> probabilisticDistanceLosses [
	| simulator law |
	simulator := (self parametersWithDrones: 12) initializeSimulator.
	simulator perceptionModel: MacroSimulatorHybridPerception new.
	law := MacroSimulatorBernoulliEventLaw probability: 0.08.
	20 to: 100 do: [ :t |
		(law countAt: t using: (simulator randomFor: #distanceLossOccurrence)) > 0 ifTrue: [
			simulator scheduleOneRandomDistanceLossAt: t matching: [ :drone | true ] stream: #distanceLossTarget ] ].
	simulator runSingleUpdate: 150.
	^ simulator
]

{ #category : 'analysis' }
MacroSimulatorPatrolExamples class >> quickInspect [
	"Evaluate this after file-in."
	^ self summaryOf: self allDistanceLostThenRestored
]

{ #category : 'route' }
MacroSimulatorPatrolExamples class >> smallHull [
	"A small non-collinear closed hull around Brest-like coordinates."
	^ {
		GeoPoint latitude: 48.390 longitude: -4.500 altitude: 0.
		GeoPoint latitude: 48.390 longitude: -4.470 altitude: 0.
		GeoPoint latitude: 48.405 longitude: -4.455 altitude: 0.
		GeoPoint latitude: 48.420 longitude: -4.470 altitude: 0.
		GeoPoint latitude: 48.420 longitude: -4.500 altitude: 0.
		GeoPoint latitude: 48.405 longitude: -4.515 altitude: 0 }
]

{ #category : 'analysis' }
MacroSimulatorPatrolExamples class >> summaryOf: aSimulator [
	| history |
	history := aSimulator evaluateMetrics.
	^ Dictionary new
		at: #maxGap put: ((history valuesOf: #maxGap) max);
		at: #longestUnobservable put: (history longestDurationOf: #unobservablePerceptionRatio where: [ :v | v > 0.0 ]);
		at: #meanAngularRatio put: ((history valuesOf: #angularPerceptionRatio) average);
		at: #maxGapEstimationError put: ((history valuesOf: #maxGapEstimationError) max);
		yourself
]
