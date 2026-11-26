"
Construit la lecture à partir d'un historique et d'une copie des réglages.
Les états intermédiaires alimentent la fraîcheur, et seule une partie des
images est affichée ou exportée. Le même calcul de durée sert à l'aperçu et
au fichier ffconcat.
"
Class {
	#name : 'SoSeAtelierLecture',
	#superclass : 'Object',
	#instVars : [ 'replay', 'history', 'settings', 'zone', 'mapOverlay', 'basemap', 'mapCredit' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierLecture class >> terrain: terrain history: steps tickSeconds: seconds display: display timing: timing [
	^ self new initializeTerrain: terrain history: steps tickSeconds: seconds display: display timing: timing
]

{ #category : 'initialization' }
SoSeAtelierLecture >> initializeTerrain: terrain history: steps tickSeconds: seconds display: display timing: timing [
	| bounds normal slow mode source |
	((display at: #transparentAfterSeconds) > (display at: #fadeAfterSeconds))
		ifFalse: [ self error: 'L’effacement doit intervenir après le blanchiment.' ].
	normal := timing at: #normalRate.
	slow := timing at: #slowRate.
	(slow > 0 and: [ slow <= normal ])
		ifFalse: [ self error: 'Règle des vitesses positives, avec le taux ralenti inférieur ou égal au taux normal.' ].
	settings := timing copy.
	replay := terrain newReplay.
	replay secondsPerTick: seconds; heightAboveGround: (display at: #height).
	replay displayOptions addAll: display.
	history := replay checkedHistory: steps every: (settings at: #stride).
	bounds := settings at: #hotspot.
	zone := bounds ifNotNil: [ terrain projectedBoundsFrom: bounds first to: bounds second ].
	mode := display at: #background ifAbsent: [ #hillshade ].
	source := SoSeAtelierBasemap sourceNamed: mode.
	source
		ifNil: [
			mode = #none ifFalse: [ mapOverlay := terrain mapOverlay ].
			mapOverlay ifNotNil: [ mapCredit := { mapOverlay value } ] ]
		ifNotNil: [
			replay displayOptions at: #background put: #none.
			basemap := SoSeAtelierBasemap formOf: source on: terrain.
			mapCredit := source at: 'credit' ]
]

{ #category : 'timing' }
SoSeAtelierLecture >> rateAt: step [
	((settings at: #interval) includes: step timeStep) ifTrue: [ ^ settings at: #slowRate ].
	(self isInHotspot: step) ifTrue: [ ^ settings at: #slowRate ].
	^ settings at: #normalRate
]

{ #category : 'timing' }
SoSeAtelierLecture >> isInHotspot: step [
	| id position |
	zone ifNil: [ ^ false ].
	id := settings at: #hotspotDrone.
	id ifNil: [
		^ step drones anySatisfy: [ :drone |
			zone containsPoint: (replay projectedPositionOfDrone: drone id in: step) ] ].
	position := replay projectedPositionOfDrone: id in: step.
	^ position notNil and: [ zone containsPoint: position ]
]

{ #category : 'timing' }
SoSeAtelierLecture >> frameIndicesFor: rates [
	| stride |
	stride := settings at: #stride.
	^ (1 to: history size) select: [ :index |
		((index - 1) rem: stride) = 0 or: [ index = history size or: [
			(rates at: index) ~= (rates at: index - 1) ] ] ]
]

{ #category : 'reading' }
SoSeAtelierLecture >> frameReader [
	| observe rates indices frameIndex nextStep |
	observe := replay newStepObserver.
	rates := history collect: [ :step | self rateAt: step ].
	indices := self frameIndicesFor: rates.
	frameIndex := nextStep := 1.
	^ [
		| stop step view duration |
		frameIndex > indices size
			ifTrue: [ nil ]
			ifFalse: [
				stop := indices at: frameIndex.
				nextStep to: stop do: [ :index | view := observe value: (history at: index) ].
				frameIndex = 1 ifTrue: [
					mapOverlay ifNotNil: [ view applyAtelierMapOverlay: mapOverlay key ].
					basemap ifNotNil: [ view useAtelierBasemap: basemap ] ].
				step := history at: stop.
				duration := frameIndex = indices size ifTrue: [ 1 ] ifFalse: [
					(history at: (indices at: frameIndex + 1)) timeStep - step timeStep ].
				duration := duration * replay secondsPerTick / (rates at: stop).
				frameIndex := frameIndex + 1.
				nextStep := stop + 1.
				{ self formOf: view. step timeStep. duration } ] ]
]

{ #category : 'drawing' }
SoSeAtelierLecture >> formOf: view [
	| corners color |
	(zone isNil and: [ mapCredit isNil ]) ifTrue: [ ^ view asForm ].
	view refresh.
	zone ifNotNil: [
		corners := { zone origin. zone right @ zone top. zone corner. zone left @ zone bottom }
			collect: [ :point | view screenPoint: point ].
		color := Color fromHexString: 'FFD27D'.
		1 to: 4 do: [ :index |
			view drawLineFrom: (corners at: index) to: (corners at: (index rem: 4) + 1) color: color ] ].
	mapCredit ifNotNil: [
		mapCredit doWithIndex: [ :credit :index |
			view label: credit at: 250 @ (14 * index - 6) size: 11
				color: (Color fromHexString: 'C0CEE0') ] ].
	^ view canvas asForm
]

{ #category : 'exporting' }
SoSeAtelierLecture >> exportImagesInto: directory [
	| nextFrame frame index file timeline |
	nextFrame := self frameReader.
	index := 0.
	timeline := directory / 'lecture.ffconcat'.
	timeline writeStreamDo: [ :stream |
		stream nextPutAll: 'ffconcat version 1.0'; lf.
		[ frame := nextFrame value. frame notNil ] whileTrue: [
			file := (index printString padLeftTo: 5 with: $0), '.png'.
			PNGReadWriter putForm: frame first onFileNamed: (directory / file) fullName.
			replay writeTimelineImage: file duration: frame third on: stream.
			index := index + 1 ].
		replay writeTimelineImage: file duration: nil on: stream ].
	^ timeline
]

{ #category : 'metrics' }
SoSeAtelierLecture class >> opticalMetricsOf: simulator terrain: terrain tickSeconds: seconds display: display zone: corners minimumFreshRatio: minimum [
	| replay extent contract report |
	replay := terrain newReplay.
	replay secondsPerTick: seconds; heightAboveGround: (display at: #height).
	replay displayOptions addAll: display.
	(SoSeAtelierBasemap sourceNamed: (display at: #background ifAbsent: [ #hillshade ])) ifNotNil: [
		replay displayOptions at: #background put: #none ].
	extent := corners
		ifNil: [ terrain projectedBounds ]
		ifNotNil: [ terrain projectedBoundsFrom: corners first to: corners second ].
	contract := replay freshnessContractFor: extent minimumFreshRatio: minimum.
	report := replay evaluateMetricsOf: simulator freshness: contract.
	(simulator isKindOf: MacroSimulatorWithFreshness) ifTrue: [
		report history with: simulator evaluateMetrics history do: [ :optical :passage |
			optical includePassageMetrics: passage ] ].
	^ report
]
