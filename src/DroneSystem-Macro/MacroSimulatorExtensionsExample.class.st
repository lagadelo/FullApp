Class {
	#name : 'MacroSimulatorExtensionsExample',
	#superclass : 'Object',
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'examples' }
MacroSimulatorExtensionsExample class >> extractorExample [
	| extractor simulator metrics |
	simulator := MacroSimulatorParameters example1 initializeSimulator.
	simulator loose: 1 at: 20.
	simulator run: 100.
	metrics := simulator evaluateMetrics history.
	extractor := MacroSimulatorExtractor longestDurationOf: #maxGap above: 120.
	^ extractor evaluateOn: metrics
]

{ #category : 'examples' }
MacroSimulatorExtensionsExample class >> poissonLossExample [
	"Poisson occurrence and victim selection use distinct deterministic random streams."
	| simulator law |
	simulator := MacroSimulatorParameters example1 initializeSimulator.
	law := MacroSimulatorPoissonEventLaw lambda: 0.01.
	simulator
		scheduleEventsFrom: 1
		to: 500
		using: law
		stream: #lossOccurrence
		label: 'stochastic drone loss'
		do: [ :step :sim |
			sim
				destroyOneDroneInStep: step
				matching: [ :drone | true ]
				stream: #lossTarget ].
	simulator run: 500.
	^ simulator
]

{ #category : 'examples' }
MacroSimulatorExtensionsExample class >> stateDependentLossExample [
	"The selected victim is chosen at event time among drones currently in the first quarter of the ring."
	| simulator quarter |
	simulator := MacroSimulatorParameters example1 initializeSimulator.
	quarter := simulator parameters totalDistance / 4.0.
	simulator
		destroyOneDroneAt: 20
		matching: [ :drone | (drone position \\ simulator parameters totalDistance) < quarter ]
		stream: #lossTarget.
	simulator run: 50.
	^ simulator
]

{ #category : 'examples' }
MacroSimulatorExtensionsExample class >> temporalViolationExample [
	"Returns the longest sequence during which maxGap exceeds 120."
	| simulator metricsHistory |
	simulator := MacroSimulatorParameters example1 initializeSimulator.
	simulator loose: 1 at: 20.
	simulator run: 100.
	metricsHistory := simulator evaluateMetrics.
	^ metricsHistory longestDurationOf: #maxGap where: [ :gap | gap > 120 ]
]
