Class {
	#name : 'MacroSimulatorPerceptionModel',
	#superclass : 'Object',
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'observing' }
MacroSimulatorPerceptionModel >> gapAheadDrone: aDrone in: aStep [
	^ aStep gapAheadDrone: aDrone
]

{ #category : 'observing' }
MacroSimulatorPerceptionModel >> gapBackwardDrone: aDrone in: aStep [
	^ aStep gapBackwardDrone: aDrone
]

{ #category : 'observing - patrol v0.2' }
MacroSimulatorPerceptionModel >> observationAheadDrone: aDrone in: aStep [
	| gap |
	gap := aStep gapAheadDrone: aDrone.
	^ MacroSimulatorPerceptionObservation
		status: #direct trueGap: gap distance: gap bearing: 0.0 estimatedGap: gap candidates: 1
]

{ #category : 'observing - patrol v0.2' }
MacroSimulatorPerceptionModel >> observationBackwardDrone: aDrone in: aStep [
	| gap |
	gap := aStep gapBackwardDrone: aDrone.
	^ MacroSimulatorPerceptionObservation
		status: #direct trueGap: gap distance: gap bearing: 0.0 estimatedGap: gap candidates: 1
]
