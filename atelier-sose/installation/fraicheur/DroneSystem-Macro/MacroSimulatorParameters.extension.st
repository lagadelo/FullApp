Extension { #name : 'MacroSimulatorParameters' }

{ #category : '*DroneSystem-Macro' }
MacroSimulatorParameters >> maxDate [
	^ maxDate
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorParameters >> maxDate: duration [
	(duration isNil or: [
		duration isNumber and: [ duration asFloat isFinite and: [ duration >= 0 ] ] ])
		ifFalse: [ self error: 'maxDate attend un âge maximal fini et positif ou nul, en secondes.' ].
	maxDate := duration
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorParameters >> initializeSimulator [
	maxDate ifNotNil: [ ^ MacroSimulatorWithFreshness new startWith: self ].
	MacroSimulatorFreshnessScope value ifNotNil: [ :limit |
		^ MacroSimulatorWithFreshness new startWith: (self copy maxDate: limit; yourself) ].
	^ MacroSimulator new startWith: self
]
