Class {
	#name : 'MacroSimulatorPatrolSmokeTests',
	#superclass : 'Object',
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'tests' }
MacroSimulatorPatrolSmokeTests class >> run [
	| nominal degraded nominalMetrics degradedMetrics |
	nominal := MacroSimulatorPatrolExamples nominalDirect.
	degraded := MacroSimulatorPatrolExamples allDistanceLostThenRestored.
	nominalMetrics := nominal evaluateMetrics.
	degradedMetrics := degraded evaluateMetrics.
	self assert: nominalMetrics history notEmpty.
	self assert: degradedMetrics history notEmpty.
	self assert: ((nominalMetrics valuesOf: #directPerceptionRatio) max) > 0.0.
	self assert: (
		(((degradedMetrics valuesOf: #angularPerceptionRatio) max) > 0.0)
			or: [ ((degradedMetrics valuesOf: #unobservablePerceptionRatio) max) > 0.0 ]).
	^ true
]
