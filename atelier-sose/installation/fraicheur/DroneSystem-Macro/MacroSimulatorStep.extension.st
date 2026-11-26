Extension { #name : 'MacroSimulatorStep' }

{ #category : '*DroneSystem-Macro' }
MacroSimulatorStep >> freshPassages [
	(self simulator respondsTo: #passageWindowAt:) ifFalse: [ ^ #() ].
	^ (self simulator passageWindowAt: self) passages
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorStep >> freshnessGapAheadOfDrone: drone [
	(self simulator respondsTo: #passageWindowAt:) ifFalse: [ ^ Float infinity ].
	^ (self simulator passageWindowAt: self) freshnessGapAheadOf: drone position
]
