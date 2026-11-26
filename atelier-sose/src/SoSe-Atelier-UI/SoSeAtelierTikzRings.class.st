"
Compare plusieurs historiques sur des anneaux concentriques en TikZ. Le
premier historique occupe l'anneau intérieur. Tous partagent une origine
à droite et un sens trigonométrique. Les angles proviennent de la position
curviligne divisée par la longueur du circuit. Les rayons servent à
espacer les historiques sur la page.

    SoSeAtelierTikzRings new
        writeAtTick: 40
        runs: { 'Révisé' -> simulationA history. 'Revisite' -> simulationB history }
        tickSeconds: 1
        options: Dictionary new
        to: 'comparaison-40.tex'.
"
Class {
	#name : 'SoSeAtelierTikzRings',
	#superclass : 'Object',
	#instVars : [ 'tick', 'tickSeconds', 'options', 'rings', 'perimeter', 'width', 'firstRadius', 'lastRadius', 'spacing', 'markerSize', 'textFormat' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'export' }
SoSeAtelierTikzRings >> writeAtTick: timeStep runs: histories tickSeconds: seconds options: settings to: aFile [
	| file contents |
	contents := self atTick: timeStep runs: histories tickSeconds: seconds options: settings.
	file := aFile asFileReference.
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream truncate; nextPutAll: contents ].
	^ file
]

{ #category : 'export' }
SoSeAtelierTikzRings >> atTick: timeStep runs: histories tickSeconds: seconds options: settings [
	^ self class new
		initializeTick: timeStep runs: histories tickSeconds: seconds options: settings;
		asTikz
]

{ #category : 'initialization' }
SoSeAtelierTikzRings >> initializeTick: timeStep runs: histories tickSeconds: seconds options: settings [
	| steps labels |
	histories ifEmpty: [ self error: 'Choisis au moins un historique pour le diagramme en anneaux.' ].
	self checkNumber: seconds above: 0 label: 'La durée du tik'.
	tick := timeStep.
	tickSeconds := seconds.
	options := settings copy.
	labels := histories collect: [ :entry | entry key asString ].
	labels asSet size = labels size ifFalse: [
		self error: 'Chaque anneau doit avoir un nom de loi différent.' ].
	steps := histories collect: [ :entry |
		entry value detect: [ :step | step timeStep = tick ] ifNone: [
			self error: 'Le tik ', tick asString, ' est absent de ', entry key asString, '.' ] ].
	perimeter := steps first range.
	self checkNumber: perimeter above: 0 label: 'Le périmètre commun'.
	steps do: [ :step |
		self checkNumber: step range above: 0 label: 'Le périmètre de chaque historique'.
		((step range - perimeter) abs <= (perimeter * 1.0e-9)) ifFalse: [
			self error: 'Les historiques doivent utiliser le même périmètre pour comparer les abscisses.' ] ].
	rings := histories with: steps collect: [ :entry :step | self ringFor: entry step: step ].
	width := options at: #widthCm ifAbsent: [ 11 ].
	self checkNumber: width above: 0 label: 'La largeur de la figure'.
	lastRadius := width * 0.45.
	firstRadius := rings size = 1 ifTrue: [ lastRadius ] ifFalse: [ lastRadius * 0.35 ].
	spacing := rings size = 1 ifTrue: [ lastRadius / 3 ] ifFalse: [
		(lastRadius - firstRadius) / (rings size - 1) ].
	markerSize := 2.15 min: (spacing * 8).
	textFormat := SoSeAtelierTikzMapFigure new
]

{ #category : 'validation' }
SoSeAtelierTikzRings >> checkNumber: value above: lowerBound label: label [
	(value isNumber and: [ value asFloat isFinite and: [ value > lowerBound ] ])
		ifFalse: [ self error: label, ' doit être finie et supérieure à ', lowerBound asString, '.' ]
]

{ #category : 'samples' }
SoSeAtelierTikzRings >> ringFor: labeledHistory step: step [
	| active positions |
	active := step drones.
	positions := (active collect: [ :drone | drone position \\ perimeter ]) asSortedCollection.
	^ { labeledHistory key asString. active. self maximumGapFor: positions.
		self lossesIn: labeledHistory value at: step }
]

{ #category : 'samples' }
SoSeAtelierTikzRings >> maximumGapFor: positions [
	"Return the start, length, and number of ties. The sorted positions use metres."
	| firstStart gap ties tolerance |
	positions ifEmpty: [ ^ nil ].
	firstStart := positions first.
	gap := -1.
	ties := 0.
	tolerance := perimeter * 1.0e-9.
	positions doWithIndex: [ :position :index |
		| next length |
		next := index = positions size
			ifTrue: [ positions first + perimeter ]
			ifFalse: [ positions at: index + 1 ].
		length := next - position.
		length > (gap + tolerance)
			ifTrue: [ firstStart := position. gap := length. ties := 1 ]
			ifFalse: [ (length - gap) abs <= tolerance ifTrue: [
				gap := gap max: length.
				ties := ties + 1 ] ] ].
	^ { firstStart. gap. ties }
]

{ #category : 'samples' }
SoSeAtelierTikzRings >> lossesIn: history at: step [
	| duration lossTicks |
	(options at: #showLosses ifAbsent: [ true ]) ifFalse: [ ^ #() ].
	duration := options at: #lossMarkerSeconds ifAbsent: [ 30 ].
	duration ifNil: [ ^ step lostDrones ].
	(duration isNumber and: [ duration asFloat isFinite and: [ duration >= 0 ] ])
		ifFalse: [ self error: 'La durée d’affichage des pertes doit être positive ou nulle.' ].
	step lostDrones ifEmpty: [ ^ #() ].
	lossTicks := Dictionary new.
	history do: [ :sample |
		sample timeStep <= tick ifTrue: [
			sample lostDrones do: [ :drone |
				lossTicks at: drone id ifAbsentPut: [ sample timeStep ] ] ] ].
	^ step lostDrones select: [ :drone |
		(tick - (lossTicks at: drone id)) * tickSeconds <= duration ]
]

{ #category : 'rendering' }
SoSeAtelierTikzRings >> asTikz [
	^ String streamContents: [ :stream |
		stream nextPutAll: '% Anneaux SoSe. Requiert \usepackage{tikz}.'; lf;
			nextPutAll: '\begin{tikzpicture}[x=1cm,y=1cm,font=\small]'; lf.
		self writeOriginOn: stream.
		rings doWithIndex: [ :ring :index |
			self writeRing: ring index: index on: stream ].
		(options at: #showLegend ifAbsent: [ true ]) ifTrue: [ self writeLegendOn: stream ].
		stream nextPutAll: '\end{tikzpicture}'; lf ]
]

{ #category : 'geometry' }
SoSeAtelierTikzRings >> angleOf: position [
	^ (position \\ perimeter) / perimeter * 360
]

{ #category : 'geometry' }
SoSeAtelierTikzRings >> polarAt: angle radius: radius [
	^ '(', (self number: angle), ':', (self number: radius), 'cm)'
]

{ #category : 'formatting' }
SoSeAtelierTikzRings >> number: value [
	^ value asFloat printShowingDecimalPlaces: 4
]

{ #category : 'rendering' }
SoSeAtelierTikzRings >> writeOriginOn: stream [
	| radius |
	radius := lastRadius + 0.22.
	stream nextPutAll: '\draw[black!45,densely dashed,line width=.35pt] (0,0) -- ';
		nextPutAll: (self polarAt: 0 radius: radius); nextPutAll: ';'; lf.
	stream nextPutAll: '\node[anchor=north west,inner sep=1pt,font=\scriptsize] at (0,0) {Origine};'; lf.
	stream nextPutAll: '\draw[black!70,->,line width=.55pt] ';
		nextPutAll: (self polarAt: 3 radius: radius);
		nextPutAll: ' arc[start angle=3,end angle=23,radius=';
		nextPutAll: (self number: radius); nextPutAll: 'cm];'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzRings >> writeRing: ring index: index on: stream [
	| radius activeStyle |
	radius := firstRadius + ((index - 1) * spacing).
	activeStyle := ring second ifEmpty: [ ',densely dashed' ] ifNotEmpty: [ '' ].
	stream nextPutAll: '\draw[black!45,line width=.40pt'; nextPutAll: activeStyle;
		nextPutAll: '] (0,0) circle[radius='; nextPutAll: (self number: radius);
		nextPutAll: 'cm];'; lf.
	ring third ifNotNil: [ :gap | self writeGap: gap at: radius on: stream ].
	ring second do: [ :drone | self writeDrone: drone at: radius on: stream ].
	ring fourth do: [ :drone | self writeLoss: drone at: radius on: stream ].
	(options at: #showLegend ifAbsent: [ true ]) ifTrue: [
		stream nextPutAll: '\node[font=\scriptsize,inner sep=.4pt,fill=white] at ';
			nextPutAll: (self polarAt: 243 radius: radius + (spacing * 0.32));
			nextPutAll: ' {'; print: index; nextPutAll: '};'; lf ]
]

{ #category : 'rendering' }
SoSeAtelierTikzRings >> writeGap: gap at: radius on: stream [
	| start end |
	gap second / perimeter >= (1 - 1.0e-9) ifTrue: [
		stream nextPutAll: '\draw[black,line width=1.15pt] (0,0) circle[radius=';
			nextPutAll: (self number: radius); nextPutAll: 'cm];'; lf.
		^ self ].
	start := self angleOf: gap first.
	end := start + (gap second / perimeter * 360).
	stream nextPutAll: '\draw[black,line width=1.15pt,line cap=round] ';
		nextPutAll: (self polarAt: start radius: radius); nextPutAll: ' arc[start angle=';
		nextPutAll: (self number: start); nextPutAll: ',end angle='; nextPutAll: (self number: end);
		nextPutAll: ',radius='; nextPutAll: (self number: radius); nextPutAll: 'cm];'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzRings >> writeDrone: drone at: radius on: stream [
	| angle |
	angle := self angleOf: drone position.
	stream nextPutAll: '\draw[black,fill=white,line width=.55pt] ';
		nextPutAll: (self polarAt: angle radius: radius); nextPutAll: ' circle[radius=';
		nextPutAll: (self number: markerSize); nextPutAll: 'pt];'; lf.
	(options at: #showDroneNames ifAbsent: [ false ]) ifTrue: [
		stream nextPutAll: '\node[font=\scriptsize,inner sep=.4pt,fill=white] at ';
			nextPutAll: (self polarAt: angle radius: radius - (spacing * 0.33)); nextPutAll: ' {';
			nextPutAll: (textFormat texText: drone id asString); nextPutAll: '};'; lf ]
]

{ #category : 'rendering' }
SoSeAtelierTikzRings >> writeLoss: drone at: radius on: stream [
	| angle markRadius |
	angle := self angleOf: drone position.
	markRadius := radius + ((spacing * 0.30) min: 0.16).
	stream nextPutAll: '\draw[black!45,line width=.35pt] '; nextPutAll: (self polarAt: angle radius: radius);
		nextPutAll: ' -- '; nextPutAll: (self polarAt: angle radius: markRadius); nextPutAll: ';'; lf.
	stream nextPutAll: '\node[font=\scriptsize,inner sep=0pt] at ';
		nextPutAll: (self polarAt: angle radius: markRadius); nextPutAll: ' {$\times$};'; lf
]

{ #category : 'rendering' }
SoSeAtelierTikzRings >> writeLegendOn: stream [
	| date legendWidth |
	date := (tick * tickSeconds) asFloat printShowingDecimalPlaces: 2.
	legendWidth := width max: 5.5.
	stream nextPutAll: '\node[anchor=north,align=left,inner sep=0pt,font=\footnotesize,text width=';
		nextPutAll: (self number: legendWidth); nextPutAll: 'cm] at (0,';
		nextPutAll: (self number: (lastRadius + 0.5) negated); nextPutAll: ') {'; lf.
	stream nextPutAll: 'Tik '; print: tick; nextPutAll: ' ($t='; nextPutAll: date;
		nextPutAll: '\,\mathrm{s}$)\\'; lf.
	stream nextPutAll: '$\circ$ drone actif \quad $\times$ perte \quad trait épais pour le plus grand écart\\'; lf.
	stream nextPutAll: '\begin{tabular}{@{}r@{\quad}p{';
		nextPutAll: (self number: (legendWidth - 4.2)); nextPutAll: 'cm}@{\quad}r@{}}';
		nextPutAll: 'Anneau & Loi & Écart max. (m)\\\hline'; lf.
	rings doWithIndex: [ :ring :index |
		| label gap |
		label := textFormat texText: ring first.
		gap := ring third.
		stream print: index; nextPutAll: ' & '; nextPutAll: label.
		ring second size = 0 ifTrue: [ stream nextPutAll: ' (aucun drone)' ].
		ring second size = 1 ifTrue: [ stream nextPutAll: ' (un drone)' ].
		stream nextPutAll: ' & '.
		gap ifNil: [ stream nextPutAll: '\textemdash{}' ]
			ifNotNil: [ stream nextPutAll: (gap second asFloat printShowingDecimalPlaces: 1) ].
		stream nextPutAll: '\\'; lf ].
	stream nextPutAll: '\end{tabular}'.
	(rings anySatisfy: [ :ring | ring third notNil and: [ ring third third > 1 ] ]) ifTrue: [
		stream nextPutAll: '\\En cas d’égalité, l’arc épaissi est le premier depuis l’origine.' ].
	stream nextPutAll: '};'; lf
]
