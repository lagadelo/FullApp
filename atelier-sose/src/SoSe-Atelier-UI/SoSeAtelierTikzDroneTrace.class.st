"
Construit une figure PGFPlots et un CSV pour un même drone dans un ou
plusieurs historiques. Le CSV conserve l'écart brut et le statut de chaque
observation. Sur la figure, une observation indisponible ramène l’aire à
zéro et porte un marqueur. L’absence du drone interrompt les courbes et
l’accélération reprend après deux états présents consécutifs.

    trace := SoSeAtelierTikzDroneTrace droneId: 1.
    trace addHistory: simulator history label: 'Capping' tickSeconds: 1.
    trace writeCSVTo: FileLocator workingDirectory / 'drone-1.csv'.
    trace writeTikzTo: FileLocator workingDirectory / 'drone-1.tex'.
"
Class {
	#name : 'SoSeAtelierTikzDroneTrace',
	#superclass : 'Object',
	#instVars : [ 'droneId', 'runs' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierTikzDroneTrace class >> droneId: anId [
	^ self new initializeDroneId: anId
]

{ #category : 'initialization' }
SoSeAtelierTikzDroneTrace >> initializeDroneId: anId [
	droneId := anId.
	runs := OrderedCollection new
]

{ #category : 'data' }
SoSeAtelierTikzDroneTrace >> addHistory: history label: aLabel tickSeconds: seconds [
	| label samples previousTick previousSpeed |
	label := aLabel asString.
	(history isEmpty or: [ label trimBoth isEmpty ])
		ifTrue: [ self error: 'Indique un historique et un libellé de loi.' ].
	(runs anySatisfy: [ :run | run key = label ])
		ifTrue: [ self error: 'Chaque historique doit avoir son propre libellé.' ].
	(seconds isNumber and: [ seconds asFloat isFinite and: [ seconds > 0 ] ])
		ifFalse: [ self error: 'La durée d’un tik doit être positive et finie.' ].
	samples := history collect: [ :step |
		| tick time drone speed acceleration ahead behind sample |
		tick := step timeStep.
		(previousTick notNil and: [ tick <= previousTick ])
			ifTrue: [ self error: 'Les tiks de l’historique doivent être strictement croissants.' ].
		time := (tick * seconds) asFloat.
		drone := step drones detect: [ :each | each id = droneId ] ifNone: [ nil ].
		drone ifNotNil: [
			speed := (drone currentSpeed / seconds) asFloat.
			previousSpeed ifNotNil: [
				acceleration := (speed - previousSpeed) / ((tick - previousTick) * seconds) ].
			ahead := self readingsOf: (step perceptionAheadOf: drone).
			behind := self readingsOf: (step perceptionBackwardOf: drone) ].
		sample := { #tick -> tick. #time -> time. #present -> drone notNil.
			#speed -> speed. #acceleration -> acceleration.
			#ahead -> ahead. #behind -> behind } asDictionary.
		previousTick := tick.
		previousSpeed := speed.
		sample ].
	runs add: label -> samples asArray
]

{ #category : 'data' }
SoSeAtelierTikzDroneTrace >> readingsOf: observation [
	| gap |
	gap := observation estimatedGap.
	(observation isUsable and: [ gap isNumber and: [ gap asFloat isFinite ] ])
		ifTrue: [ ^ { gap asFloat. observation status } ].
	^ { nil. observation status }
]

{ #category : 'data' }
SoSeAtelierTikzDroneTrace >> plotGapIn: sample side: side [
	| reading gap |
	reading := sample at: side.
	reading ifNil: [ ^ nil ].
	gap := reading first ifNil: [ 0 ].
	^ side = #behind ifTrue: [ gap negated ] ifFalse: [ gap ]
]

{ #category : 'export' }
SoSeAtelierTikzDroneTrace >> writeCSVTo: target [
	| file |
	self requireRuns.
	file := target asFileReference.
	file writeStreamDo: [ :stream |
		stream nextPutAll: 'law,drone_id,tick,time_s,present,speed_m_s,acceleration_m_s2,ahead_gap_m,ahead_status,ahead_plot_m,behind_gap_m,behind_status,behind_plot_m'; lf.
		runs do: [ :run |
			run value do: [ :sample |
				| ahead behind fields |
				ahead := (sample at: #ahead) ifNil: [ #(nil droneAbsent) ].
				behind := (sample at: #behind) ifNil: [ #(nil droneAbsent) ].
				fields := { run key. droneId. sample at: #tick. sample at: #time.
					sample at: #present. sample at: #speed. sample at: #acceleration.
					ahead first. ahead second. self plotGapIn: sample side: #ahead.
					behind first. behind second. self plotGapIn: sample side: #behind }.
				stream nextPutAll: (',' join: (fields collect: [ :field |
					self csvField: field ])); lf ] ] ].
	^ file
]

{ #category : 'export' }
SoSeAtelierTikzDroneTrace >> csvField: value [
	value ifNil: [ ^ '' ].
	value isNumber ifTrue: [ ^ value printString ].
	^ '"', (value asString copyReplaceAll: '"' with: '""'), '"'
]

{ #category : 'export' }
SoSeAtelierTikzDroneTrace >> requireRuns [
	runs ifEmpty: [ self error: 'Ajoute un historique avant l’export.' ]
]

{ #category : 'export' }
SoSeAtelierTikzDroneTrace >> writeTikzTo: target [
	"
	Produit un fragment LaTeX à insérer avec \input.
	Préambule : \usepackage{pgfplots}, \usepgfplotslibrary{groupplots},
	\pgfplotsset{compat=1.18}.
	"
	| file |
	self requireRuns.
	file := target asFileReference.
	file writeStreamDo: [ :stream | self writePictureOn: stream ].
	^ file
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writePictureOn: stream [
	| firstTime lastTime count |
	firstTime := (runs collect: [ :run | run value first at: #time ]) min.
	lastTime := (runs collect: [ :run | run value last at: #time ]) max.
	firstTime = lastTime ifTrue: [ lastTime := lastTime + 1 ].
	count := runs size.
	stream
		nextPutAll: '\begin{tikzpicture}'; lf;
		nextPutAll: '\begin{groupplot}[group style={group size=1 by 3,x descriptions at=edge bottom,vertical sep=';
		print: (1.15 + (count * 0.4));
		nextPutAll: 'cm},scale only axis,width=0.76\linewidth,height=2.2cm,';
		nextPutAll: 'unbounded coords=jump,grid=major,grid style={black!14},';
		nextPutAll: 'tick label style={font=\small},label style={font=\small},';
		nextPutAll: 'legend columns=1,legend cell align=left,';
		nextPutAll: 'legend style={at={(0.5,-0.15)},anchor=north,font=\footnotesize},';
		nextPutAll: 'xmin='; print: firstTime; nextPutAll: ',xmax='; print: lastTime; nextPutAll: ']'; lf;
		nextPutAll: '\nextgroupplot[title={Drone '; nextPutAll: (self escapeTeX: droneId asString);
		nextPutAll: '},ylabel={Vitesse (m/s)}]'; lf.
	self writeTimeCurves: #speed withLegend: true on: stream.
	stream nextPutAll: '\nextgroupplot[ylabel={Accélération (m/s$^2$)}]'; lf.
	self writeTimeCurves: #acceleration withLegend: false on: stream.
	stream nextPutAll: '\nextgroupplot[title={Avant (+) et arrière ($-$)},xlabel={Temps simulé (s)},';
		nextPutAll: 'ylabel={Écart observé (m)},legend columns=2,';
		nextPutAll: 'legend style={at={(0.5,-0.45)}}]'; lf.
	self writeGapCurvesFrom: firstTime to: lastTime on: stream.
	stream nextPutAll: '\end{groupplot}'; lf; nextPutAll: '\end{tikzpicture}'; lf
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writeTimeCurves: key withLegend: showLegend on: stream [
	runs withIndexDo: [ :run :index |
		| values |
		values := [ :sample | sample at: key ].
		self writeCurveOf: run value style: (self styleFor: index), ',semithick,mark=none'
			keepLegend: showLegend value: values on: stream.
		showLegend ifTrue: [
			stream nextPutAll: '\addlegendentry{\parbox[t]{0.62\linewidth}{\raggedright ';
				nextPutAll: (self escapeTeX: run key); nextPutAll: '}}'; lf ].
		self writeIsolatedOf: run value value: values on: stream ]
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writeGapCurvesFrom: firstTime to: lastTime on: stream [
	| sides markers |
	sides := #(ahead behind).
	runs withIndexDo: [ :run :index |
		sides do: [ :side |
			self writeGapAreasOf: run value side: side
				style: ('draw=none,fill=black!', (index odd ifTrue: [ '22' ] ifFalse: [ '12' ]), ',fill opacity=0.55')
				on: stream ] ].
	stream nextPutAll: '\addplot[black!50,thin,forget plot] coordinates {'.
	self writePointAt: firstTime value: 0 on: stream.
	self writePointAt: lastTime value: 0 on: stream.
	stream nextPutAll: '};'; lf.
	runs withIndexDo: [ :run :index |
		sides do: [ :side |
			self writeCurveOf: run value style: (self styleFor: index), ',thin,mark=none'
				keepLegend: false value: [ :sample | self plotGapIn: sample side: side ] on: stream ] ].
	markers := {
		'mark=o' -> 'Estimation par gisement'.
		'mark=x' -> 'NA avant'.
		'mark=+' -> 'NA arrière'.
		'mark=*' -> 'Mesure directe nulle' }.
	runs do: [ :run |
		sides do: [ :side |
			self writeMarkersOf: run value side: side style: markers first key
				when: [ :reading | reading second = #angular and: [ reading first notNil ] ] on: stream.
			self writeMarkersOf: run value side: side
				style: (markers at: (side = #ahead ifTrue: [ 2 ] ifFalse: [ 3 ])) key
				when: [ :reading | reading first isNil ] on: stream.
			self writeMarkersOf: run value side: side style: markers fourth key
				when: [ :reading | reading second = #direct and: [ reading first = 0 ] ] on: stream ] ].
	markers do: [ :entry |
		stream nextPutAll: '\addlegendimage{black,only marks,'; nextPutAll: entry key; nextPutAll: '}'; lf.
		self writeLegend: entry value on: stream ]
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writeGapAreasOf: samples side: side style: style on: stream [
	| segment |
	segment := OrderedCollection new.
	samples do: [ :sample |
		(sample at: #present)
			ifTrue: [ segment add: sample ]
			ifFalse: [
				self writeGapArea: segment side: side style: style on: stream.
				segment removeAll ] ].
	self writeGapArea: segment side: side style: style on: stream
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writeGapArea: segment side: side style: style on: stream [
	segment ifEmpty: [ ^ self ].
	segment size = 1 ifTrue: [
		| reading |
		reading := segment first at: side.
		(reading second = #direct and: [ reading first notNil and: [ reading first ~= 0 ] ])
			ifTrue: [
				self writeCurveOf: segment style: 'black,only marks,mark=*,mark size=0.9pt'
					keepLegend: false value: [ :sample | self plotGapIn: sample side: side ] on: stream ].
		^ self ].
	stream nextPutAll: '\addplot['; nextPutAll: style; nextPutAll: ',forget plot] coordinates {'; lf.
	self writePointAt: (segment first at: #time) value: 0 on: stream.
	segment do: [ :sample |
		self writePointAt: (sample at: #time) value: (self plotGapIn: sample side: side) on: stream ].
	self writePointAt: (segment last at: #time) value: 0 on: stream.
	stream nextPutAll: '}\closedcycle;'; lf
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writeMarkersOf: samples side: side style: style when: predicate on: stream [
	| matches |
	matches := samples select: [ :sample |
		(sample at: side) ifNil: [ false ] ifNotNil: predicate ].
	matches ifEmpty: [ ^ self ].
	self writeCurveOf: matches style: 'black,only marks,mark size=1.3pt,', style
		keepLegend: false value: [ :sample | self plotGapIn: sample side: side ] on: stream
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writeIsolatedOf: samples value: valueBlock on: stream [
	| isolated |
	isolated := OrderedCollection new.
	samples withIndexDo: [ :sample :index |
		((valueBlock value: sample) notNil and: [
			(index = 1 or: [ (valueBlock value: (samples at: index - 1)) isNil ]) and: [
				index = samples size or: [ (valueBlock value: (samples at: index + 1)) isNil ] ] ])
			ifTrue: [ isolated add: sample ] ].
	isolated ifNotEmpty: [
		self writeCurveOf: isolated style: 'black,only marks,mark=*,mark size=0.9pt'
			keepLegend: false value: valueBlock on: stream ]
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writeCurveOf: samples style: style keepLegend: showLegend value: valueBlock on: stream [
	stream nextPutAll: '\addplot['; nextPutAll: style.
	showLegend ifFalse: [ stream nextPutAll: ',forget plot' ].
	stream nextPutAll: '] coordinates {'; lf.
	samples do: [ :sample |
		self writePointAt: (sample at: #time) value: (valueBlock value: sample) on: stream ].
	stream nextPutAll: '};'; lf
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writePointAt: time value: value on: stream [
	stream nextPut: $(; print: time; nextPut: $,.
	value ifNil: [ stream nextPutAll: 'nan' ] ifNotNil: [ stream print: value ].
	stream nextPut: $); lf
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> writeLegend: label on: stream [
	stream nextPutAll: '\addlegendentry{'; nextPutAll: (self escapeTeX: label); nextPut: $}; lf
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> styleFor: index [
	| styles |
	styles := #('solid' 'densely dashed' 'densely dotted' 'dashdotted' 'loosely dashed' 'loosely dashdotted').
	^ 'black,', (styles at: (index - 1 \\ styles size) + 1)
]

{ #category : 'tikz' }
SoSeAtelierTikzDroneTrace >> escapeTeX: value [
	| escapes |
	escapes := { $\ -> '\textbackslash{}'. (Character value: 123) -> '\{'. $} -> '\}'. $# -> '\#'.
		$$ -> '\$'. $% -> '\%'. $& -> '\&'. $_ -> '\_'. $^ -> '\textasciicircum{}'.
		$~ -> '\textasciitilde{}'. Character cr -> ' '. Character lf -> ' ' } asDictionary.
	^ String streamContents: [ :stream |
		value do: [ :character |
			stream nextPutAll: (escapes at: character ifAbsent: [ character asString ]) ] ]
]
