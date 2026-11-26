"
Produit des figures TikZ et des séries CSV à partir d'historiques macro.
Les temps sont sélectionnés sur les états enregistrés. Les figures utilisent
une géométrie en mètres et des symboles en noir et blanc.
"
Class {
	#name : 'SoSeAtelierPublication',
	#superclass : 'Object',
	#instVars : [ 'runs', 'settings', 'tickSeconds', 'terrain' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'configuration' }
SoSeAtelierPublication class >> defaultOptions [
	^ { #ticks -> #(). #seconds -> #(). #dates -> #(). #origin -> nil.
		#droneIds -> #(). #mapDroneIds -> #(). #policies -> #(). #modes -> #(state).
		#overview -> #maps.
		#showRoute -> true. #showDrones -> true. #showDroneNames -> false. #showLosses -> true.
		#trailTicks -> 0. #lossMarkerSeconds -> 40. #showMasked -> false.
		#footprintHeights -> #(). #camera -> #(0.5 2000). #widthCm -> 11.
		#focusDrone -> nil. #focusRadiusMeters -> 350. #maxHeightCm -> 15.
		#showScale -> true. #showLegend -> true.
		#positionTolerance -> 0.01. #speedTolerance -> 0.05. #accelerationThreshold -> 0.05 } asDictionary
]

{ #category : 'initialization' }
SoSeAtelierPublication >> initialize [
	super initialize.
	runs := OrderedCollection new.
	settings := self class defaultOptions.
	tickSeconds := 1
]

{ #category : 'configuration' }
SoSeAtelierPublication >> options: options [
	settings := self class defaultOptions.
	options keysAndValuesDo: [ :key :value |
		| option |
		option := key asSymbol.
		(settings includesKey: option) ifFalse: [ self error: 'Réglage de publication inconnu ', key asString ].
		settings at: option put: value ]
]

{ #category : 'configuration' }
SoSeAtelierPublication >> tickSeconds: seconds [
	self requirePositive: seconds for: #tickSeconds.
	tickSeconds := seconds
]

{ #category : 'configuration' }
SoSeAtelierPublication >> terrain: aTerrain [
	terrain := aTerrain
]

{ #category : 'configuration' }
SoSeAtelierPublication >> addSimulation: simulator named: label [
	(label isString and: [ label trimBoth notEmpty ])
		ifFalse: [ self error: 'Donne un nom à la simulation.' ].
	(runs anySatisfy: [ :entry | entry key = label ])
		ifTrue: [ self error: 'Nom de simulation déjà utilisé ', label ].
	simulator history ifEmpty: [ self error: 'Historique vide pour ', label ].
	runs add: label -> simulator history
]

{ #category : 'validation' }
SoSeAtelierPublication >> requireNumber: value minimum: minimum for: key [
	(value isNumber and: [ value asFloat isFinite and: [ value >= minimum ] ])
		ifFalse: [ self error: 'Valeur numérique finie hors domaine pour ', key asString ]
]

{ #category : 'validation' }
SoSeAtelierPublication >> requirePositive: value for: key [
	self requireNumber: value minimum: 0 for: key.
	value = 0 ifTrue: [ self error: 'Une valeur strictement positive est attendue pour ', key asString ]
]

{ #category : 'validation' }
SoSeAtelierPublication >> validate [
	| modes camera |
	runs ifEmpty: [ self error: 'Ajoute au moins un historique à la publication.' ].
	(#(maps rings none) includes: self overview)
		ifFalse: [ self error: 'overview attend maps, rings ou none.' ].
	#(ticks seconds dates droneIds mapDroneIds modes footprintHeights camera) do: [ :key |
		| value |
		value := settings at: key.
		(value isSequenceable and: [ value isString not ])
			ifFalse: [ self error: 'Une liste est attendue pour ', key asString ] ].
	#(showRoute showDrones showDroneNames showLosses showMasked showScale showLegend) do: [ :key |
		(#(true false) includes: (settings at: key))
			ifFalse: [ self error: 'Un booléen est attendu pour ', key asString ] ].
	#(positionTolerance speedTolerance accelerationThreshold lossMarkerSeconds) do: [ :key |
		self requireNumber: (settings at: key) minimum: 0 for: key ].
	self requireNumber: (settings at: #widthCm) minimum: 1 for: #widthCm.
	self requirePositive: (settings at: #maxHeightCm) for: #maxHeightCm.
	self requirePositive: (settings at: #focusRadiusMeters) for: #focusRadiusMeters.
	camera := settings at: #camera.
	camera size = 2 ifFalse: [ self error: 'camera attend la tangente du demi-angle et le nombre de pixels par côté du capteur.' ].
	camera do: [ :value | self requirePositive: value for: #camera ].
	((settings at: #trailTicks) isInteger and: [ (settings at: #trailTicks) >= 0 ])
		ifFalse: [ self error: 'trailTicks doit être un nombre entier positif ou nul.' ].
	modes := self modes.
	(modes notEmpty and: [ modes allSatisfy: [ :mode | #(state speed acceleration) includes: mode ] ])
		ifFalse: [ self error: 'modes attend au moins une valeur parmi state, speed et acceleration.' ].
	(settings at: #footprintHeights) do: [ :height | self requirePositive: height for: #footprintHeights ].
	((settings at: #footprintHeights) notEmpty and: [ terrain isNil ])
		ifTrue: [ self error: 'Les empreintes exigent un MNT et un parcours cartographié.' ]
]

{ #category : 'time' }
SoSeAtelierPublication >> tickForSeconds: seconds [
	| fraction tick |
	self requireNumber: seconds minimum: 0 for: #seconds.
	fraction := seconds / tickSeconds.
	tick := fraction rounded.
	((tick * tickSeconds - seconds) abs <= (tickSeconds * 1.0e-8))
		ifFalse: [ self error: 'La date demandée tombe entre deux tiks. Utilise une date sur la grille temporelle.' ].
	^ tick
]

{ #category : 'time' }
SoSeAtelierPublication >> parseTimestamp: timestamp [
	(timestamp isKindOf: DateAndTime) ifTrue: [ ^ timestamp ].
	(timestamp isString and: [ timestamp includes: $T ])
		ifFalse: [ self error: 'Indique une date-heure ISO 8601 avec son fuseau.' ].
	((timestamp endsWith: 'Z') or: [
		(timestamp copyAfter: $T) includesAny: '+-' ])
		ifFalse: [ self error: 'Indique le fuseau dans la date ISO 8601.' ].
	^ DateAndTime fromString: timestamp
]

{ #category : 'time' }
SoSeAtelierPublication >> snapshotTicks [
	| ticks origin |
	ticks := (settings at: #ticks) asOrderedCollection.
	(ticks allSatisfy: [ :tick | tick isInteger and: [ tick >= 0 ] ])
		ifFalse: [ self error: 'Les tiks doivent être des entiers positifs ou nuls.' ].
	(settings at: #seconds) do: [ :seconds | ticks add: (self tickForSeconds: seconds) ].
	(settings at: #dates) ifNotEmpty: [ :dates |
		origin := self parseTimestamp: (settings at: #origin).
		dates do: [ :date |
			ticks add: (self tickForSeconds:
				((self parseTimestamp: date) - origin) asNanoSeconds / 1.0e9) ] ].
	ticks ifEmpty: [ ticks add: runs first value last timeStep ].
	ticks := ticks asSet asSortedCollection asArray.
	runs do: [ :entry |
		| available |
		available := (entry value collect: #timeStep) asSet.
		(ticks allSatisfy: [ :tick | available includes: tick ])
			ifFalse: [ self error: 'Au moins un tik est absent dans l’historique « ', entry key, ' ».' ] ].
	^ ticks
]

{ #category : 'configuration' }
SoSeAtelierPublication >> modes [
	^ (settings at: #modes) asOrderedCollection collect: #asSymbol
]

{ #category : 'configuration' }
SoSeAtelierPublication >> overview [
	^ (settings at: #overview) asSymbol
]

{ #category : 'configuration' }
SoSeAtelierPublication >> mapOptions [
	| options |
	options := Dictionary new.
	#(showRoute showDrones showDroneNames showLosses trailTicks lossMarkerSeconds showMasked
		camera widthCm maxHeightCm focusDrone focusRadiusMeters speedTolerance accelerationThreshold
		showScale showLegend)
		do: [ :key | options at: key put: (settings at: key) ].
	(settings at: #mapDroneIds) ifNotEmpty: [ :ids | options at: #droneIds put: ids ].
	^ options
]

{ #category : 'paths' }
SoSeAtelierPublication >> runDirectoryAt: index in: directory [
	^ directory / ('serie-', index printString)
]

{ #category : 'exporting' }
SoSeAtelierPublication >> writeInto: parent [
	| ticks output pages |
	self validate.
	ticks := self overview = #none ifTrue: [ #() ] ifFalse: [ self snapshotTicks ].
	output := (parent asFileReference / ('publication-', UUID new asString)) ensureCreateDirectory.
	pages := OrderedCollection new.
	runs withIndexDo: [ :entry :index |
		| destination |
		destination := (self runDirectoryAt: index in: output) ensureCreateDirectory.
		self overview = #maps ifTrue: [
			self writeSnapshotsOf: entry ticks: ticks into: destination pages: pages ] ].
	self overview = #rings ifTrue: [ self writeRingsAt: ticks into: output pages: pages ].
	self writeTracesInto: output pages: pages.
	self writeComparisonsInto: output pages: pages.
	self writeManifestInto: output ticks: ticks.
	self writePortfolioInto: output pages: pages.
	^ output
]

{ #category : 'exporting' }
SoSeAtelierPublication >> writeRingsAt: ticks into: directory pages: pages [
	| renderer options |
	renderer := SoSeAtelierTikzRings new.
	options := self mapOptions.
	ticks do: [ :tick |
		| file |
		file := directory / ('anneaux-tik-', tick printString, '.tex').
		renderer writeAtTick: tick runs: runs tickSeconds: tickSeconds options: options to: file.
		pages add: ('Répartition de la flotte / tik ', tick printString) -> file basename ]
]

{ #category : 'exporting' }
SoSeAtelierPublication >> writeSnapshotsOf: entry ticks: ticks into: destination pages: pages [
	| map options heights figureNumber |
	map := SoSeAtelierTikzMap history: entry value tickSeconds: tickSeconds terrain: terrain.
	options := self mapOptions.
	heights := (settings at: #footprintHeights) ifEmpty: [ { nil } ].
	figureNumber := 0.
	ticks do: [ :tick |
		self modes do: [ :mode |
			heights do: [ :height |
				| file caption figureOptions |
				figureNumber := figureNumber + 1.
				file := destination / ('figure-', figureNumber printString, '.tex').
				figureOptions := options copy at: #mode put: mode; yourself.
				height ifNotNil: [ figureOptions at: #heightAboveGround put: height ].
				map writeAtTick: tick options: figureOptions to: file.
				caption := entry key, ' / tik ', tick printString, ' / ', (self captionFor: mode).
				(settings at: #focusDrone) ifNotNil: [ :id | caption := caption, ' / drone ', id asString ].
				height ifNotNil: [ caption := caption, ' / ', height printString, ' m au-dessus du sol' ].
				pages add: caption -> (destination basename, '/', file basename) ] ] ]
]

{ #category : 'exporting' }
SoSeAtelierPublication >> captionFor: mode [
	^ { #state -> 'état'. #speed -> 'vitesse'. #acceleration -> 'accélération' } asDictionary at: mode
]

{ #category : 'exporting' }
SoSeAtelierPublication >> writeTracesInto: directory pages: pages [
	(settings at: #droneIds) withIndexDo: [ :id :index |
		| trace name |
		trace := SoSeAtelierTikzDroneTrace droneId: id.
		runs do: [ :entry | trace addHistory: entry value label: entry key tickSeconds: tickSeconds ].
		name := 'drone-', index printString.
		trace writeCSVTo: directory / (name, '.csv').
		trace writeTikzTo: directory / (name, '.tex').
		pages add: ('Drone ', id asString, ' / séries temporelles') -> (name, '.tex') ]
]

{ #category : 'exporting' }
SoSeAtelierPublication >> writeComparisonsInto: directory pages: pages [
	| baseline |
	baseline := runs first.
	2 to: runs size do: [ :index |
		| variant comparison folder |
		variant := runs at: index.
		comparison := SoSeAtelierPublicationComparison
			baseline: baseline value baselineLabel: baseline key
			variant: variant value variantLabel: variant key tickSeconds: tickSeconds
			positionTolerance: (settings at: #positionTolerance) speedTolerance: (settings at: #speedTolerance).
		folder := comparison writeInto: directory / ('comparaison-', index printString).
		pages add: (variant key, ' / écarts avec ', baseline key) ->
			(folder basename, '/comparaison-trajectoires.tex') ]
]

{ #category : 'exporting' }
SoSeAtelierPublication >> writeManifestInto: directory ticks: ticks [
	| document origin |
	origin := settings at: #origin.
	document := { 'format' -> 'sose-atelier-publication'. 'version' -> 1.
		'tickSeconds' -> tickSeconds. 'ticks' -> ticks.
		'seconds' -> (ticks collect: [ :tick | tick * tickSeconds ]).
		'origin' -> (origin ifNotNil: [ origin asString ]).
		'requestedDates' -> ((settings at: #dates) asArray collect: #asString).
		'droneIds' -> (settings at: #droneIds) asArray copy.
		'overview' -> self overview asString.
		'modes' -> (self modes asArray collect: #asString).
		'footprintHeights' -> (settings at: #footprintHeights) asArray copy.
		'series' -> ((1 to: runs size) collect: [ :index |
			{ 'directory' -> (self runDirectoryAt: index in: directory) basename.
				'label' -> (runs at: index) key } asDictionary ]) } asDictionary.
	SoSeAtelierMissionFile write: document to: directory / 'manifest.json'
]

{ #category : 'exporting' }
SoSeAtelierPublication >> writePortfolioInto: directory pages: pages [
	(directory / 'figures.tex') writeStreamDo: [ :stream |
		stream
			nextPutAll: '\documentclass[a4paper,10pt]{article}'; lf;
			nextPutAll: '\usepackage[T1]{fontenc}'; lf;
			nextPutAll: '\IfFileExists{lmodern.sty}{\usepackage{lmodern}}{}'; lf;
			nextPutAll: '\usepackage[margin=16mm]{geometry}'; lf;
			nextPutAll: '\usepackage{tikz,pgfplots}'; lf;
			nextPutAll: '\usetikzlibrary{arrows.meta,patterns,patterns.meta,calc}'; lf;
			nextPutAll: '\usepgfplotslibrary{fillbetween,groupplots}'; lf;
			nextPutAll: '\pgfplotsset{compat=1.18}'; lf;
			nextPutAll: '\begin{document}'; lf;
			nextPutAll: '\pagestyle{empty}'; lf.
		pages withIndexDo: [ :entry :index |
			index > 1 ifTrue: [ stream nextPutAll: '\clearpage'; lf ].
			stream nextPutAll: '\begin{center}'; lf;
				nextPutAll: '\textbf{'; nextPutAll: (self texText: entry key); nextPutAll: '}\par\medskip'; lf;
				nextPutAll: '\input{'; nextPutAll: entry value; nextPutAll: '}'; lf;
				nextPutAll: '\end{center}'; lf ].
		stream nextPutAll: '\end{document}'; lf ]
]

{ #category : 'exporting' }
SoSeAtelierPublication >> texText: label [
	| escapes |
	escapes := {
		$\ -> '\textbackslash{}'. ${ -> '\{'. $} -> '\}'. $$ -> '\$'.
		$& -> '\&'. $# -> '\#'. $_ -> '\_'. $% -> '\%'.
		$^ -> '\textasciicircum{}'. $~ -> '\textasciitilde{}' } asDictionary.
	^ String streamContents: [ :stream |
		label do: [ :character |
			stream nextPutAll: (escapes at: character ifAbsent: [ character asString ]) ] ]
]
