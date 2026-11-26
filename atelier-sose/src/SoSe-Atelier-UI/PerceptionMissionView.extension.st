Extension { #name : 'PerceptionMissionView' }

{ #category : '*SoSe-Atelier-UI' }
PerceptionMissionView >> applyAtelierMapOverlay: overlay [
	| terrain base |
	terrain := adapter terrain.
	base := self reliefFor: terrain.
	overlay displayOn: base at: 0 @ 0 rule: Form blend
]

{ #category : '*SoSe-Atelier-UI' }
PerceptionMissionView >> useAtelierBasemap: form [
	background := form.
	backgroundTerrain := adapter terrain
]
