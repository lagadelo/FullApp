"
Perception des deux voisins sur la boucle. Pour le gisement, les secteurs
sont centrés sur la tangente avant et son opposée, selon le voisin recherché.
La portée, les pannes de capteurs et l’ambiguïté restent évaluées par le modèle macro.
"
Class {
	#name : 'SoSeAtelierNeighborPerception',
	#superclass : 'MacroSimulatorSelectablePerception',
	#instVars : [ 'halfAngle' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierNeighborPerception class >> mode: selector halfAngle: degrees [
	^ self new initializeMode: selector halfAngle: degrees
]

{ #category : 'initialization' }
SoSeAtelierNeighborPerception >> initializeMode: selector halfAngle: degrees [
	(#(distance bearing hybrid) includes: selector) ifFalse: [ self error: 'Mode de perception inconnu.' ].
	(degrees isNumber and: [ degrees between: 0 and: 180 ])
		ifFalse: [ self error: 'Le demi-angle de visibilité doit être compris entre 0 et 180°.' ].
	mode := selector.
	halfAngle := degrees
]

{ #category : 'observing' }
SoSeAtelierNeighborPerception >> allowsDistanceFor: drone [
	^ mode ~= #bearing and: [ drone distanceMeasurementAvailable ]
]

{ #category : 'observing' }
SoSeAtelierNeighborPerception >> allowsBearingFor: drone [
	^ mode ~= #distance and: [ drone visionAvailable ]
]

{ #category : 'observing' }
SoSeAtelierNeighborPerception >> observationOf: drone target: neighbor side: side in: step [
	| observation deviation |
	observation := super observationOf: drone target: neighbor side: side in: step.
	(halfAngle = 180 or: [ (self allowsBearingFor: drone) not or: [
		observation isDirect or: [ observation isOutOfRange ] ] ]) ifTrue: [ ^ observation ].
	deviation := observation bearingDegrees abs.
	side = #ahead ifFalse: [ deviation := 180 - deviation ].
	deviation <= halfAngle ifTrue: [ ^ observation ].
	^ MacroSimulatorPerceptionObservation status: #noVision
		trueGap: observation trueArcGap distance: observation euclideanDistance
		bearing: observation bearingDegrees estimatedGap: nil candidates: 0
]
