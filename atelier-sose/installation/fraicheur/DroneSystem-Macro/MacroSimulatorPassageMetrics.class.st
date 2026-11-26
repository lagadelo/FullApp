"
Indicateurs de fraîcheur en plus des métriques legacy. Pour chaque drone,
on considère le prochain passage encore frais situé devant lui. Le rayon de
capture borne le périmètre local. La fraîcheur est le crédit de temps restant
à ce passage dans le périmètre (0 si aucun passage utile).
"
Class {
	#name : 'MacroSimulatorPassageMetrics',
	#superclass : 'MacroSimulatorMetrics',
	#instVars : [ 'minFreshness', 'maxFreshnessGap', 'freshnessRuptureCount' ],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorPassageMetrics class >> on: step passageWindow: window [
	^ (self on: step) computeFreshnessOn: step passageWindow: window
]

{ #category : 'exporting' }
MacroSimulatorPassageMetrics class >> exportFieldNames [
	^ (MacroSimulatorMetrics instanceVariables collect: #name),
		#(minFreshness maxFreshnessGap freshnessRuptureCount freshnessRupture)
]

{ #category : 'computing' }
MacroSimulatorPassageMetrics >> computeFreshnessOn: step passageWindow: window [
	minFreshness := Float infinity.
	maxFreshnessGap := 0.
	freshnessRuptureCount := 0.
	step drones ifEmpty: [
		minFreshness := 0.
		maxFreshnessGap := Float infinity ].
	step drones do: [ :drone |
		| passage gap freshness |
		passage := window firstPassageAheadOf: drone position.
		gap := passage
			ifNil: [ Float infinity ]
			ifNotNil: [ window distanceFrom: drone position to: passage ].
		freshness := (passage notNil and: [ gap <= drone captureRadius ])
			ifTrue: [ window freshnessOf: passage ]
			ifFalse: [ 0 ].
		minFreshness := minFreshness min: freshness.
		maxFreshnessGap := maxFreshnessGap max: gap.
		freshness <= 0 ifTrue: [ freshnessRuptureCount := freshnessRuptureCount + 1 ] ].
	^ self
]

{ #category : 'accessing' }
MacroSimulatorPassageMetrics >> minFreshness [
	^ minFreshness
]

{ #category : 'accessing' }
MacroSimulatorPassageMetrics >> maxFreshnessGap [
	^ maxFreshnessGap
]

{ #category : 'accessing' }
MacroSimulatorPassageMetrics >> freshnessRuptureCount [
	^ freshnessRuptureCount
]

{ #category : 'accessing' }
MacroSimulatorPassageMetrics >> freshnessRupture [
	^ minFreshness <= 0
]
