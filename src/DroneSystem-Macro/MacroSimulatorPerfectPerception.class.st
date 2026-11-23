Class {
	#name : 'MacroSimulatorPerfectPerception',
	#superclass : 'MacroSimulatorPerceptionModel',
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'observing' }
MacroSimulatorPerfectPerception >> gapAheadDrone: aDrone in: aStep [
	^ aStep gapAheadDrone: aDrone
]

{ #category : 'observing' }
MacroSimulatorPerfectPerception >> gapBackwardDrone: aDrone in: aStep [
	^ aStep gapBackwardDrone: aDrone
]

{ #category : 'observing - patrol v0.2' }
MacroSimulatorPerfectPerception >> observationAheadDrone: aDrone in: aStep [
	^ super observationAheadDrone: aDrone in: aStep
]

{ #category : 'observing - patrol v0.2' }
MacroSimulatorPerfectPerception >> observationBackwardDrone: aDrone in: aStep [
	^ super observationBackwardDrone: aDrone in: aStep
]
