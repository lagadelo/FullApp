"
Rend un instantané vectoriel. L'orientation suit la tangente locale.
Une pointe pleine est une catégorie de vitesse. Une flèche filaire
est une variation de vitesse dans le temps.
"
Class {
	#name : 'SoSeAtelierTikzMapFigure',
	#superclass : 'Object',
	#instVars : [ 'map', 'index', 'step', 'options', 'mode', 'height', 'bounds', 'scale', 'drones', 'output' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierTikzMapFigure class >> map: aMap index: position options: settings [
	^ self new initializeMap: aMap index: position options: settings
]

{ #category : 'initialization' }
SoSeAtelierTikzMapFigure >> initializeMap: aMap index: historyIndex options: settings [
	| width maxHeight ids focus |
	map := aMap.
	index := historyIndex.
	step := map stepAt: index.
	options := settings copy.
	mode := (options at: #mode ifAbsent: [ #state ]) asSymbol.
	(#(state speed acceleration) includes: mode)
		ifFalse: [ self error: 'Le mode TikZ doit être state, speed ou acceleration.' ].
	height := options at: #heightAboveGround ifAbsent: [ nil ].
	height ifNotNil: [
		self checkNumber: height positive: true name: 'hauteur au-dessus du sol'.
		map terrain ifNil: [ self error: 'Le dessin de l’empreinte exige un MNT.' ] ].
	bounds := height
		ifNil: [ Rectangle encompassing: map route ]
		ifNotNil: [ map terrain projectedBounds ].
	focus := options at: #focusDrone ifAbsent: [ nil ].
	focus ifNotNil: [ self focusOn: focus ].
	width := options at: #widthCm ifAbsent: [ 11 ].
	maxHeight := options at: #maxHeightCm ifAbsent: [ 15 ].
	self checkNumber: width positive: true name: 'largeur de la figure'.
	self checkNumber: maxHeight positive: true name: 'hauteur maximale de la figure'.
	scale := (width / (bounds width max: 1)) min: (maxHeight / (bounds height max: 1)).
	ids := (options at: #droneIds ifAbsent: [ nil ]) ifNotNil: [ :values |
		(values collect: #asString) asSet ].
	options at: #selectedIds put: ids.
	drones := step drones select: [ :drone | self includes: drone ]
]

{ #category : 'initialization' }
SoSeAtelierTikzMapFigure >> focusOn: identifier [
	| drone position radius extent |
	drone := step drones detect: [ :each | each id asString = identifier asString ]
		ifNone: [ self error: 'Le drone ciblé est absent du tik.' ].
	position := map positionOf: drone in: step.
	radius := options at: #focusRadiusMeters ifAbsent: [ 350 ].
	self checkNumber: radius positive: true name: 'rayon de zoom en mètres'.
	extent := radius @ radius.
	bounds := (position - extent) corner: (position + extent)
]

{ #category : 'validation' }
SoSeAtelierTikzMapFigure >> checkNumber: value positive: strict name: label [
	(value isNumber and: [ value asFloat isFinite and: [
		strict ifTrue: [ value > 0 ] ifFalse: [ value >= 0 ] ] ])
		ifFalse: [ self error: 'Valeur numérique invalide pour la ', label, '.' ]
]

{ #category : 'selection' }
SoSeAtelierTikzMapFigure >> includes: drone [
	| ids |
	ids := options at: #selectedIds.
	^ ids isNil or: [ ids includes: drone id asString ]
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> asTikz [
	^ String streamContents: [ :stream |
		output := stream.
		output nextPutAll: '% Instantane SoSe. Requiert \usepackage{tikz}.'; lf.
		output nextPutAll: '\begin{tikzpicture}[x=1cm,y=1cm,font=\small]'; lf.
		self writeBoundingBox.
		(options at: #focusDrone ifAbsent: [ nil ]) ifNotNil: [ self writeClip ].
		height ifNotNil: [ self writeFootprints ].
		(options at: #showRoute ifAbsent: [ true ]) ifTrue: [ self writeRoute ].
		self writeTrails.
		(options at: #showDrones ifAbsent: [ true ]) ifTrue: [
			drones do: [ :drone | self writeDrone: drone ] ].
		(options at: #showLosses ifAbsent: [ true ]) ifTrue: [ self writeLosses ].
		(options at: #focusDrone ifAbsent: [ nil ]) ifNotNil: [
			output nextPutAll: '\end{scope}'; lf.
			height ifNotNil: [
				(options at: #showTerrainBorder ifAbsent: [ true ]) ifTrue: [ self writeFocusBorder ] ] ].
		(options at: #showScale ifAbsent: [ true ]) ifTrue: [ self writeScale ].
		(options at: #showLegend ifAbsent: [ true ]) ifTrue: [ self writeLegend ].
		output nextPutAll: '\end{tikzpicture}'; lf ]
]

{ #category : 'geometry' }
SoSeAtelierTikzMapFigure >> coordinateOf: point [
	^ self canvasCoordinate: (point - bounds origin) * scale
]

{ #category : 'geometry' }
SoSeAtelierTikzMapFigure >> canvasCoordinate: point [
	^ '(', (self number: point x), ',', (self number: point y), ')'
]

{ #category : 'geometry' }
SoSeAtelierTikzMapFigure >> number: value [
	^ value asFloat printShowingDecimalPlaces: 5
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeBoundingBox [
	output nextPutAll: '\path (-0.20,-0.20) rectangle ';
		nextPutAll: (self canvasCoordinate: (bounds extent * scale + (0.20 @ 0.20)));
		nextPutAll: ';'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeFocusBorder [
	output nextPutAll: '\draw[black!35,line width=.35pt] (0,0) rectangle ';
		nextPutAll: (self canvasCoordinate: bounds extent * scale); nextPutAll: ';'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeClip [
	output nextPutAll: '\begin{scope}'; lf.
	output nextPutAll: '\clip (0,0) rectangle ';
		nextPutAll: (self canvasCoordinate: bounds extent * scale); nextPutAll: ';'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeRoute [
	output nextPutAll: '\draw[black!54,line width=.5pt,line join=round] '.
	map route do: [ :point |
		output nextPutAll: (self coordinateOf: point); nextPutAll: ' -- ' ].
	output nextPutAll: 'cycle;'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeTrails [
	| duration |
	duration := options at: #trailTicks ifAbsent: [ 0 ].
	(duration isInteger and: [ duration >= 0 ])
		ifFalse: [ self error: 'La longueur de traînée doit être un nombre entier de tiks positif ou nul.' ].
	duration = 0 ifTrue: [ ^ self ].
	drones do: [ :drone |
		| trail |
		trail := map trailOf: drone at: index lastTicks: duration.
		trail size > 1 ifTrue: [
			output nextPutAll: '\draw[black!65,densely dotted,line width=.65pt,line cap=round] '.
			trail
				do: [ :point | output nextPutAll: (self coordinateOf: point) ]
				separatedBy: [ output nextPutAll: ' -- ' ].
			output nextPutAll: ';'; lf ] ]
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeDrone: drone [
	| position mark named |
	position := self coordinateOf: (map positionOf: drone in: step).
	output nextPutAll: '\draw[black,fill=white,line width=.65pt] ';
		nextPutAll: position; nextPutAll: ' circle[radius=2.5pt];'; lf.
	named := options at: #showDroneNames ifAbsent: [ false ].
	mark := mode caseOf: {
		[ #state ] -> [ nil ].
		[ #speed ] -> [ self speedMarkFor: drone ].
		[ #acceleration ] -> [ self accelerationMarkFor: drone ] }.
	(mark isNil and: [ named not ]) ifTrue: [ ^ self ].
	output nextPutAll: '\begin{scope}[shift={'; nextPutAll: position;
		nextPutAll: '},rotate='; nextPutAll: (self number: (map headingOf: drone in: step));
		nextPutAll: ',x=1pt,y=1pt]'; lf.
	mark ifNotNil: [ self writeMark: mark ].
	self writeNameOf: drone at: '(0,8)'.
	output nextPutAll: '\end{scope}'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeNameOf: drone at: coordinate [
	(options at: #showDroneNames ifAbsent: [ false ]) ifTrue: [
		output nextPutAll: '\node[inner sep=.75pt,fill=white,font=\scriptsize] at ';
			nextPutAll: coordinate; nextPutAll: ' {';
			nextPutAll: (self texText: drone id asString); nextPutAll: '};'; lf ]
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeLosses [
	| duration |
	duration := options at: #lossMarkerSeconds ifAbsent: [ 30 ].
	duration ifNotNil: [ self checkNumber: duration positive: false name: 'durée d’affichage d’une perte' ].
	step lostDrones do: [ :drone |
		| age position |
		age := (step timeStep - (map lossTickOf: drone)) * map tickSeconds.
		((self includes: drone) and: [ duration isNil or: [ age <= duration ] ]) ifTrue: [
			position := self coordinateOf: (map positionOf: drone in: step).
			output nextPutAll: '\begin{scope}[shift={'; nextPutAll: position;
				nextPutAll: '},x=1pt,y=1pt]'; lf;
				nextPutAll: '\draw[white,line width=1.75pt] (-3,-3) -- (3,3) (-3,3) -- (3,-3);'; lf;
				nextPutAll: '\draw[black,line width=.8pt] (-3,-3) -- (3,3) (-3,3) -- (3,-3);'; lf.
			self writeNameOf: drone at: '(0,8)'.
			output nextPutAll: '\end{scope}'; lf ] ]
]

{ #category : 'classification' }
SoSeAtelierTikzMapFigure >> speedMarkFor: drone [
	| tolerance speed nominal minimum |
	tolerance := options at: #speedTolerance ifAbsent: [ 0.05 ].
	self checkNumber: tolerance positive: false name: 'tolérance de vitesse'.
	speed := drone currentSpeed / map tickSeconds.
	nominal := drone nominalSpeed / map tickSeconds.
	minimum := drone minSpeed / map tickSeconds.
	speed <= (minimum + tolerance) ifTrue: [ ^ #minimum ].
	(speed - nominal) abs <= tolerance ifTrue: [ ^ 2 ].
	^ speed < nominal ifTrue: [ 1 ] ifFalse: [ 3 ]
]

{ #category : 'classification' }
SoSeAtelierTikzMapFigure >> accelerationMarkFor: drone [
	| tolerance acceleration |
	acceleration := map accelerationOf: drone at: index.
	acceleration ifNil: [ ^ nil ].
	tolerance := options at: #accelerationThreshold ifAbsent: [ 0.05 ].
	self checkNumber: tolerance positive: false name: 'seuil d’accélération'.
	acceleration abs <= tolerance ifTrue: [ ^ #constant ].
	^ acceleration > 0 ifTrue: [ #accelerating ] ifFalse: [ #decelerating ]
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeMark: mark [
	mark isInteger ifTrue: [
		1 to: mark do: [ :indexOfTriangle |
			| x |
			x := 4 + (indexOfTriangle - 1 * 4).
			output nextPutAll: '\fill[black] '; nextPutAll: (self canvasCoordinate: x @ -1.7);
				nextPutAll: ' -- '; nextPutAll: (self canvasCoordinate: (x + 3.2) @ 0);
				nextPutAll: ' -- '; nextPutAll: (self canvasCoordinate: x @ 1.7);
				nextPutAll: ' -- cycle;'; lf ].
		^ self ].
	output nextPutAll: '\draw[black,line width=.7pt,line cap=round,line join=round] '.
	output nextPutAll: (mark caseOf: {
		[ #minimum ] -> [ '(6,-2.3) -- (6,2.3);' ].
		[ #constant ] -> [ '(4,0) -- (6,1.9) -- (8,0) -- (6,-1.9) -- cycle;' ].
		[ #accelerating ] -> [ '(4,0) -- (13,0) (10,-2.5) -- (13,0) -- (10,2.5);' ].
		[ #decelerating ] -> [ '(13,0) -- (4,0) (7,-2.5) -- (4,0) -- (7,2.5);' ] }); lf
]

{ #category : 'footprints' }
SoSeAtelierTikzMapFigure >> writeFootprints [
	| terrain adapter camera visible shadow |
	terrain := map terrain copy.
	adapter := PerceptionAdapter on: terrain.
	camera := options at: #camera ifAbsent: [ #(0.5 2000) ].
	adapter cameraHalfFieldTangent: camera first sensorSidePixels: camera second.
	visible := Set new.
	shadow := terrain collectShadowsDuring: [
		drones do: [ :drone |
			| pose |
			pose := PerceptionDronePose id: drone id position: (map positionOf: drone in: step)
				heightAboveGround: height.
			adapter observePose: pose do: [ :cell :gsd | visible add: cell ] ] ].
	(options at: #showMasked ifAbsent: [ false ]) ifTrue: [
		self writeCells: (shadow difference: visible) on: terrain style: 'fill=black!40' ].
	self writeCells: visible on: terrain style: 'fill=black!17'.
	(options at: #showTerrainBorder ifAbsent: [ true ]) ifTrue: [ self writeTerrainBorder ]
]

{ #category : 'footprints' }
SoSeAtelierTikzMapFigure >> writeTerrainBorder [
	| terrainBounds |
	terrainBounds := map terrain projectedBounds.
	output nextPutAll: '\draw[black!35,line width=.35pt] ';
		nextPutAll: (self coordinateOf: terrainBounds origin); nextPutAll: ' rectangle ';
		nextPutAll: (self coordinateOf: terrainBounds corner); nextPutAll: ';'; lf
]

{ #category : 'footprints' }
SoSeAtelierTikzMapFigure >> writeCells: cells on: terrain style: style [
	| sorted start last |
	cells ifEmpty: [ ^ self ].
	sorted := cells asSortedCollection: [ :a :b | a y = b y ifTrue: [ a x < b x ] ifFalse: [ a y < b y ] ].
	start := last := sorted first.
	sorted allButFirst do: [ :cell |
		(cell y ~= last y or: [ cell x ~= (last x + 1) ]) ifTrue: [
			self writeCellsFrom: start to: last on: terrain style: style.
			start := cell ].
		last := cell ].
	self writeCellsFrom: start to: last on: terrain style: style
]

{ #category : 'footprints' }
SoSeAtelierTikzMapFigure >> writeCellsFrom: first to: last on: terrain style: style [
	| spacing upperLeft lowerRight |
	spacing := terrain cellSize.
	upperLeft := terrain origin + (first x * spacing x @ (first y * spacing y) negated).
	lowerRight := upperLeft + ((last x - first x + 1) * spacing x @ spacing y negated).
	output nextPutAll: '\path['; nextPutAll: style; nextPutAll: '] ';
		nextPutAll: (self coordinateOf: upperLeft); nextPutAll: ' rectangle ';
		nextPutAll: (self coordinateOf: lowerRight); nextPutAll: ';'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeScale [
	| target factor length right label |
	target := (bounds width / 5) max: 0.00001.
	factor := 1.0.
	[ target < factor ] whileTrue: [ factor := factor / 10 ].
	[ target >= (factor * 10) ] whileTrue: [ factor := factor * 10 ].
	length := (#(5 2 1) detect: [ :multiple | multiple * factor <= target ]) * factor.
	right := self canvasCoordinate: length * scale @ -0.15.
	label := length >= 1000
		ifTrue: [ (length / 1000) rounded printString, ' km' ]
		ifFalse: [ (length printShowingDecimalPlaces: (length < 1 ifTrue: [ 3 ] ifFalse: [ 0 ])), ' m' ].
	output nextPutAll: '\draw[line width=.6pt] (0,-0.15) -- '; nextPutAll: right;
		nextPutAll: ' node[midway,below=1pt,inner sep=0pt,font=\scriptsize] {';
		nextPutAll: label; nextPutAll: '};'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> writeLegend [
	| entries title time width |
	time := step timeStep * map tickSeconds.
	title := 'Tik ', step timeStep printString, ' ($t=', (time asFloat printShowingDecimalPlaces: 2), '\,\mathrm{s}$)'.
	height ifNotNil: [
		title := title, ' $\cdot$ hauteur ', (height asFloat printShowingDecimalPlaces: 1), ' m AGL' ].
	entries := OrderedCollection with: title.
	(options at: #showDrones ifAbsent: [ true ]) ifTrue: [
		entries add: '$\circ$ drone actif'.
		mode = #speed ifTrue: [
			entries add: 'Barre au minimum. 1 / 2 / 3 pointes pour $v<v_\mathrm{nom}$ / $v=v_\mathrm{nom}$ / $v>v_\mathrm{nom}$.' ].
		mode = #acceleration ifTrue: [
			entries add: 'Flèche vers l’avant en accélération, vers l’arrière au freinage.'.
			entries add: 'Losange à vitesse constante.' ] ].
	(options at: #showLosses ifAbsent: [ true ]) ifTrue: [ entries add: '$\times$ perte' ].
	height ifNotNil: [
		entries add: ((options at: #showMasked ifAbsent: [ false ])
			ifTrue: [ 'Cellules visibles en gris clair, masquées en gris foncé.' ]
			ifFalse: [ 'Cellules visibles au tik en gris.' ]).
		entries add: 'Blanc hors champ ou terrain sans mesure.' ].
	width := (bounds width * scale) max: 3.
	output nextPutAll: '\node[anchor=north west,inner sep=0pt,font=\scriptsize,align=left,text width=';
		nextPutAll: (self number: width); nextPutAll: 'cm] at (0,-0.60) {';
		nextPutAll: ('\\' join: entries); nextPutAll: '};'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzMapFigure >> texText: text [
	| replacements |
	replacements := { $\ -> '\textbackslash{}'. (Character value: 123) -> '\{'.
		(Character value: 125) -> '\}'. $% -> '\%'. $& -> '\&'. $# -> '\#'. $_ -> '\_'. $$ -> '\$'.
		$~ -> '\textasciitilde{}'. $^ -> '\textasciicircum{}' } asDictionary.
	^ String streamContents: [ :stream |
		text do: [ :character |
			stream nextPutAll: (replacements at: character ifAbsent: [ character asString ]) ] ]
]
