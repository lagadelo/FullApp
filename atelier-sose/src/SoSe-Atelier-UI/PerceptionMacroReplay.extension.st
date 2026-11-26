Extension { #name : 'PerceptionMacroReplay' }

{ #category : '*SoSe-Atelier-UI' }
PerceptionMacroReplay >> terrain [
	^ scene terrain
]

{ #category : '*SoSe-Atelier-UI' }
PerceptionMacroReplay >> projectedPositionOf: drone in: step [
	^ scene positionOf: drone in: step
]
