"
Compare deux historiques ordonnés d'une même boucle, avec le même repère
curviligne et la même durée du tik. L'identifiant actif d'un drone sert à
apparier ses états. La distance de position est le plus court arc sur la
boucle. La vitesse stockée est un déplacement par tik, converti en m/s.

Une divergence d'état apparaît si un tik manque, si les identifiants actifs
diffèrent ou si un écart dépasse strictement sa tolérance. Une divergence
au tik 0 décrit une différence initiale. L'absence de divergence est nil.

Les observations restent un diagnostic séparé. Chaque paire associe le même
observateur, le même côté et le même voisin. Les estimations sont lues avec le
modèle de perception attaché aux états. L'écart numérique est calculé lorsque
les deux estimations existent. Les statuts et disponibilités sont aussi suivis.
"
Class {
	#name : 'SoSeAtelierPublicationComparison',
	#superclass : 'Object',
	#instVars : [ 'baselineLabel', 'variantLabel', 'tickSeconds', 'positionTolerance', 'speedTolerance', 'perimeter', 'rows' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierPublicationComparison class >> baseline: baselineHistory baselineLabel: baselineName variant: variantHistory variantLabel: variantName tickSeconds: seconds positionTolerance: metres speedTolerance: metresPerSecond [
	^ self new initializeBaseline: baselineHistory baselineLabel: baselineName
		variant: variantHistory variantLabel: variantName tickSeconds: seconds
		positionTolerance: metres speedTolerance: metresPerSecond
]

{ #category : 'initialization' }
SoSeAtelierPublicationComparison >> initializeBaseline: baselineHistory baselineLabel: baselineName variant: variantHistory variantLabel: variantName tickSeconds: seconds positionTolerance: metres speedTolerance: metresPerSecond [
	| baselineByTick variantByTick baselineRoute variantRoute ticks |
	((self finite: seconds) and: [ seconds > 0 ])
		ifFalse: [ self error: 'La durée du tik doit être positive et finie.' ].
	((self finite: metres) and: [ metres >= 0 and: [ (self finite: metresPerSecond) and: [ metresPerSecond >= 0 ] ] ])
		ifFalse: [ self error: 'Les tolérances doivent être positives ou nulles et finies.' ].
	(baselineHistory isEmpty or: [ variantHistory isEmpty ])
		ifTrue: [ self error: 'La comparaison demande deux historiques non vides.' ].
	perimeter := baselineHistory first range.
	((self finite: perimeter) and: [ perimeter > 0 ])
		ifFalse: [ self error: 'Le périmètre doit être positif et fini.' ].
	baselineRoute := self routeOf: baselineHistory first.
	variantRoute := self routeOf: variantHistory first.
	(baselineRoute notNil and: [ variantRoute notNil and: [ baselineRoute ~= variantRoute ] ])
		ifTrue: [ self error: 'Les parcours doivent avoir les mêmes points dans le même ordre.' ].
	baselineLabel := baselineName asString.
	variantLabel := variantName asString.
	tickSeconds := seconds asFloat.
	positionTolerance := metres asFloat.
	speedTolerance := metresPerSecond asFloat.
	baselineByTick := self indexHistory: baselineHistory.
	variantByTick := self indexHistory: variantHistory.
	ticks := (baselineByTick keys asSet addAll: variantByTick keys; yourself) asSortedCollection.
	rows := ticks asArray collect: [ :tick |
		self rowAt: tick baseline: (baselineByTick at: tick ifAbsent: [ nil ])
			variant: (variantByTick at: tick ifAbsent: [ nil ]) ]
]

{ #category : 'validation' }
SoSeAtelierPublicationComparison >> finite: value [
	^ value isNumber and: [ value asFloat isFinite ]
]

{ #category : 'validation' }
SoSeAtelierPublicationComparison >> indexHistory: history [
	| byTick previous |
	byTick := Dictionary new: history size.
	previous := -1.
	history do: [ :step |
		| tick |
		tick := step timeStep.
		(tick isInteger and: [ tick > previous ])
			ifFalse: [ self error: 'Les tiks d’un historique doivent être entiers, uniques et croissants.' ].
		step range = perimeter ifFalse: [ self error: 'Tous les états doivent avoir le même périmètre.' ].
		byTick at: tick put: step.
		previous := tick ].
	^ byTick
]

{ #category : 'validation' }
SoSeAtelierPublicationComparison >> routeOf: step [
	^ step simulator ifNotNil: [ :simulator |
		simulator parameters ifNotNil: [ :parameters | parameters wayPoints ifNotNil: #asArray ] ]
]

{ #category : 'comparing' }
SoSeAtelierPublicationComparison >> rowAt: tick baseline: baselineStep variant: variantStep [
	| row baselineDrones variantDrones |
	baselineDrones := baselineStep ifNotNil: [ self dronesById: baselineStep ].
	variantDrones := variantStep ifNotNil: [ self dronesById: variantStep ].
	row := { 'baselineLabel' -> baselineLabel. 'variantLabel' -> variantLabel.
		'tick' -> tick. 'simulatedSeconds' -> (tick * tickSeconds).
		'baselinePresent' -> baselineStep notNil. 'variantPresent' -> variantStep notNil.
		'baselineFleetSize' -> (baselineDrones ifNotNil: #size).
		'variantFleetSize' -> (variantDrones ifNotNil: #size).
		'baselineIds' -> (baselineDrones ifNotNil: [ self sortedIds: baselineDrones keys ]).
		'variantIds' -> (variantDrones ifNotNil: [ self sortedIds: variantDrones keys ]) } asDictionary.
	(baselineStep isNil or: [ variantStep isNil ]) ifTrue: [
		row at: 'reasons' put: #('missingTick').
		^ row ].
	self compareDrones: baselineDrones with: variantDrones in: row
		baselineStep: baselineStep variantStep: variantStep.
	^ row
]

{ #category : 'comparing' }
SoSeAtelierPublicationComparison >> dronesById: step [
	| index |
	index := Dictionary new: step drones size.
	step drones do: [ :drone |
		(index includesKey: drone id) ifTrue: [ self error: 'Identifiant de drone actif dupliqué.' ].
		index at: drone id put: drone ].
	^ index
]

{ #category : 'comparing' }
SoSeAtelierPublicationComparison >> sortedIds: ids [
	^ (ids collect: #asString) sorted asArray
]

{ #category : 'comparing' }
SoSeAtelierPublicationComparison >> compareDrones: baselineDrones with: variantDrones in: row baselineStep: baselineStep variantStep: variantStep [
	| baselineIds variantIds shared baselineOnly variantOnly reasons deltas largestArc largestSpeed |
	baselineIds := baselineDrones keys asSet.
	variantIds := variantDrones keys asSet.
	shared := (baselineIds intersection: variantIds) asArray sorted: [ :left :right | left asString <= right asString ].
	baselineOnly := baselineIds difference: variantIds.
	variantOnly := variantIds difference: baselineIds.
	row at: 'commonDroneCount' put: shared size.
	row at: 'baselineOnlyIds' put: (self sortedIds: baselineOnly asArray).
	row at: 'variantOnlyIds' put: (self sortedIds: variantOnly asArray).
	reasons := OrderedCollection new.
	(baselineOnly notEmpty or: [ variantOnly notEmpty ]) ifTrue: [ reasons add: 'fleetIds' ].
	deltas := shared collect: [ :id | self deltasFrom: (baselineDrones at: id) to: (variantDrones at: id) ].
	deltas ifNotEmpty: [
		largestArc := deltas detectMax: #second.
		largestSpeed := deltas detectMax: #third.
		row at: 'maxArcDeltaM' put: largestArc second.
		row at: 'maxArcDeltaDroneId' put: largestArc first.
		row at: 'meanArcDeltaM' put: (deltas collect: #second) average.
		row at: 'maxSpeedDeltaMps' put: largestSpeed third.
		row at: 'maxSpeedDeltaDroneId' put: largestSpeed first.
		row at: 'meanSpeedDeltaMps' put: (deltas collect: #third) average.
		largestArc second > positionTolerance ifTrue: [ reasons add: 'position' ].
		largestSpeed third > speedTolerance ifTrue: [ reasons add: 'speed' ] ].
	row at: 'reasons' put: reasons asArray.
	self compareObservationsOf: shared baseline: baselineStep drones: baselineDrones
		variant: variantStep drones: variantDrones in: row
]

{ #category : 'comparing' }
SoSeAtelierPublicationComparison >> deltasFrom: baselineDrone to: variantDrone [
	| arc speed |
	arc := (baselineDrone position - variantDrone position) abs \\ perimeter.
	speed := (baselineDrone currentSpeed - variantDrone currentSpeed) abs / tickSeconds.
	^ { baselineDrone id asString. (arc min: perimeter - arc) asFloat. speed asFloat }
]

{ #category : 'observations' }
SoSeAtelierPublicationComparison >> compareObservationsOf: shared baseline: baselineStep drones: baselineDrones variant: variantStep drones: variantDrones in: row [
	| matched unmatched observations reasons statusChanges availabilityChanges gaps |
	matched := 0.
	unmatched := 0.
	observations := OrderedCollection new.
	shared do: [ :id |
		| baselineDrone variantDrone |
		baselineDrone := baselineDrones at: id.
		variantDrone := variantDrones at: id.
		#((predecessors perceptionAheadOf:) (successors perceptionBackwardOf:)) do: [ :side |
			| baselineNeighbor variantNeighbor |
			baselineNeighbor := self neighborOf: baselineDrone in: baselineStep using: side first.
			variantNeighbor := self neighborOf: variantDrone in: variantStep using: side first.
			(baselineNeighbor notNil or: [ variantNeighbor notNil ]) ifTrue: [
				(baselineNeighbor notNil and: [ variantNeighbor notNil and: [ baselineNeighbor id = variantNeighbor id ] ])
					ifTrue: [
						matched := matched + 1.
						observations add: { baselineStep perform: side second with: baselineDrone.
							variantStep perform: side second with: variantDrone } ]
					ifFalse: [ unmatched := unmatched + 1 ] ] ] ].
	statusChanges := observations count: [ :pair | pair first status ~= pair second status ].
	availabilityChanges := observations count: [ :pair | pair first estimatedGap isNil ~= pair second estimatedGap isNil ].
	gaps := observations select: [ :pair | pair first estimatedGap notNil and: [ pair second estimatedGap notNil ] ]
		thenCollect: [ :pair | (pair first estimatedGap - pair second estimatedGap) abs asFloat ].
	row at: 'matchedNeighborCount' put: matched.
	row at: 'unmatchedNeighborCount' put: unmatched.
	row at: 'observationStatusChanges' put: statusChanges.
	row at: 'observationAvailabilityChanges' put: availabilityChanges.
	row at: 'comparedGapCount' put: gaps size.
	row at: 'maxObservedGapDeltaM' put: (gaps ifEmpty: [ nil ] ifNotEmpty: [ gaps max ]).
	reasons := OrderedCollection new.
	statusChanges > 0 ifTrue: [ reasons add: 'status' ].
	availabilityChanges > 0 ifTrue: [ reasons add: 'availability' ].
	(gaps anySatisfy: [ :gap | gap > positionTolerance ]) ifTrue: [ reasons add: 'estimatedGap' ].
	row at: 'observationReasons' put: reasons asArray
]

{ #category : 'observations' }
SoSeAtelierPublicationComparison >> neighborOf: drone in: step using: selector [
	| neighbor |
	neighbor := (step perform: selector) at: drone ifAbsent: [ nil ].
	^ neighbor == drone ifTrue: [ nil ] ifFalse: [ neighbor ]
]

{ #category : 'accessing' }
SoSeAtelierPublicationComparison >> rows [
	^ rows
]

{ #category : 'accessing' }
SoSeAtelierPublicationComparison >> firstDivergence [
	^ rows detect: [ :row | (row at: 'reasons') notEmpty ] ifNone: [ nil ]
]

{ #category : 'accessing' }
SoSeAtelierPublicationComparison >> summary [
	| firstDivergence firstObservationDivergence finalCommon |
	firstDivergence := self firstDivergence.
	firstObservationDivergence := rows detect: [ :row |
		(row at: 'observationReasons' ifAbsent: [ #() ]) notEmpty ] ifNone: [ nil ].
	finalCommon := rows reversed detect: [ :row |
		(row at: 'baselinePresent') and: [ row at: 'variantPresent' ] ] ifNone: [ nil ].
	^ { 'format' -> 'sose-publication-comparison'. 'version' -> 1.
		'baselineLabel' -> baselineLabel. 'variantLabel' -> variantLabel.
		'perimeterM' -> perimeter asFloat. 'tickSeconds' -> tickSeconds.
		'positionToleranceM' -> positionTolerance. 'speedToleranceMps' -> speedTolerance.
		'firstDivergence' -> (self copySummaryRow: firstDivergence).
		'firstDivergenceAtZero' -> (firstDivergence notNil and: [ (firstDivergence at: 'tick') = 0 ]).
		'firstObservationDivergence' -> (self copySummaryRow: firstObservationDivergence).
		'final' -> (self copySummaryRow: rows last). 'finalCommon' -> (self copySummaryRow: finalCommon).
		'notes' -> #('Comparer des exécutions sur la même boucle et avec la même origine curviligne.'
			'Les maxima et moyennes portent sur les identifiants actifs communs.'
			'La position est comparée par le plus court arc et la vitesse de commande est convertie en m/s.'
			'Une divergence au tik 0 relève des conditions initiales.'
			'Une valeur absente indique une mesure non applicable.'
			'Les écarts observés sur le même lien orienté sont un diagnostic séparé.') } asDictionary
]

{ #category : 'accessing' }
SoSeAtelierPublicationComparison >> copySummaryRow: row [
	^ row ifNotNil: [ row collect: [ :value | value isArray ifTrue: [ value copy ] ifFalse: [ value ] ] ]
]

{ #category : 'exporting' }
SoSeAtelierPublicationComparison >> writeInto: directory [
	| output |
	output := directory asFileReference ensureCreateDirectory.
	self writeCSVTo: output / 'comparaison-trajectoires.csv'.
	SoSeAtelierMissionFile write: self summary to: output / 'divergence.json'.
	self writeTikzTo: output / 'comparaison-trajectoires.tex'.
	^ output
]

{ #category : 'exporting' }
SoSeAtelierPublicationComparison >> writeCSVTo: target [
	| columns |
	columns := #('baselineLabel' 'variantLabel' 'tick' 'simulatedSeconds' 'baselinePresent' 'variantPresent'
		'baselineFleetSize' 'variantFleetSize' 'baselineIds' 'variantIds' 'commonDroneCount'
		'baselineOnlyIds' 'variantOnlyIds' 'maxArcDeltaM' 'maxArcDeltaDroneId' 'meanArcDeltaM'
		'maxSpeedDeltaMps' 'maxSpeedDeltaDroneId' 'meanSpeedDeltaMps' 'reasons' 'matchedNeighborCount'
		'unmatchedNeighborCount' 'observationStatusChanges' 'observationAvailabilityChanges'
		'comparedGapCount' 'maxObservedGapDeltaM' 'observationReasons').
	self writeFile: target using: [ :stream |
		| writer |
		writer := NeoCSVWriter on: stream.
		writer writeHeader: columns.
		rows do: [ :row |
			writer nextPut: (columns collect: [ :field |
				| value |
				value := row at: field ifAbsent: [ nil ].
				value isArray ifTrue: [ STONJSON toString: value ] ifFalse: [ value ] ]) ] ]
]

{ #category : 'exporting' }
SoSeAtelierPublicationComparison >> writeFile: file using: aBlock [
	| target temporary |
	target := file asFileReference.
	temporary := target parent / ('.comparaison-', UUID new asString, '.tmp').
	[ temporary writeStreamDo: aBlock.
		(File rename: (File encodePathString: temporary fullName) to: (File encodePathString: target fullName))
			ifNil: [ self error: 'Impossible d’enregistrer ', target fullName ] ]
		ensure: [ temporary exists ifTrue: [ temporary delete ] ].
	^ target
]

{ #category : 'exporting' }
SoSeAtelierPublicationComparison >> writeTikzTo: target [
	"Fragment à inclure avec pgfplots et la bibliothèque groupplots."
	^ self writeFile: target using: [ :stream | self writeComparisonPictureOn: stream ]
]

{ #category : 'tikz' }
SoSeAtelierPublicationComparison >> writeComparisonPictureOn: stream [
	| firstTime lastTime divergence |
	firstTime := rows first at: 'simulatedSeconds'.
	lastTime := rows last at: 'simulatedSeconds'.
	firstTime = lastTime ifTrue: [ lastTime := lastTime + tickSeconds ].
	divergence := self firstDivergence.
	stream
		nextPutAll: '\begin{tikzpicture}'; lf;
		nextPutAll: '\begin{groupplot}[group style={group size=1 by 2,x descriptions at=edge bottom,vertical sep=1.3cm},'; lf;
		nextPutAll: 'scale only axis,width=0.76\linewidth,height=2.6cm,unbounded coords=jump,';
		nextPutAll: 'grid=major,grid style={black!14},axis line style={black!50},'; lf;
		nextPutAll: 'tick label style={font=\small},label style={font=\small},';
		nextPutAll: 'legend style={at={(0.5,1.02)},anchor=south,draw=none,font=\scriptsize},'; lf;
		nextPutAll: 'xmin='; print: firstTime; nextPutAll: ',xmax='; print: lastTime;
		nextPutAll: ',enlarge x limits=0.035,ymin=0]'; lf.
	self writePlotOf: 'maxArcDeltaM' options: 'ylabel={Écart d''arc max. (m)}'
		divergence: divergence withLegend: true on: stream.
	self writePlotOf: 'maxSpeedDeltaMps' options: 'ylabel={Écart de vitesse max. (m/s)},xlabel={Temps simulé (s)}'
		divergence: divergence withLegend: false on: stream.
	stream nextPutAll: '\end{groupplot}'; lf; nextPutAll: '\end{tikzpicture}'; lf
]

{ #category : 'tikz' }
SoSeAtelierPublicationComparison >> writePlotOf: field options: options divergence: divergence withLegend: showLegend on: stream [
	| values available max upper |
	values := rows collect: [ :row | row at: field ifAbsent: [ nil ] ].
	available := values reject: #isNil.
	max := available ifEmpty: [ 0 ] ifNotEmpty: [ available max ].
	upper := max = 0 ifTrue: [ 1 ] ifFalse: [ max * 1.12 ].
	stream nextPutAll: '\nextgroupplot['; nextPutAll: options; nextPutAll: ',ymax='; print: upper;
		nextPutAll: ']'; lf.
	available ifEmpty: [
		stream nextPutAll: '\node[font=\small] at (rel axis cs:0.5,0.5) {Mesures comparables indisponibles};'; lf
	] ifNotEmpty: [
		stream nextPutAll: '\addplot[black,semithick,mark=*,mark size=0.5pt,forget plot] coordinates {'; lf.
		values withIndexDo: [ :value :index |
			stream nextPut: $(; print: ((rows at: index) at: 'simulatedSeconds'); nextPut: $,.
			value ifNil: [ stream nextPutAll: 'nan' ] ifNotNil: [ stream print: value ].
			stream nextPut: $); lf ].
		stream nextPutAll: '};'; lf ].
	divergence ifNotNil: [
		self writeDivergence: divergence upper: upper withLegend: showLegend on: stream ]
]

{ #category : 'tikz' }
SoSeAtelierPublicationComparison >> writeDivergence: divergence upper: upper withLegend: showLegend on: stream [
	| time |
	time := divergence at: 'simulatedSeconds'.
	stream nextPutAll: '\addplot[black,densely dashed,thin,mark=none'.
	showLegend ifFalse: [ stream nextPutAll: ',forget plot' ].
	stream nextPutAll: '] coordinates {('; print: time; nextPutAll: ',0) ('; print: time;
		nextPut: $,; print: upper; nextPutAll: ')};'; lf.
	showLegend ifTrue: [ stream
		nextPutAll: '\addlegendentry{Premier écart au tik '; print: (divergence at: 'tick');
		nextPutAll: ' ('; print: time; nextPutAll: '\,s)}'; lf ]
]
