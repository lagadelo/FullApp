Class {
	#name : 'SoSeAtelierRevisitPresenter',
	#superclass : 'SoSeAtelierFormPresenter',
	#instVars : [ 'estimateButton', 'estimateAction', 'estimateLabel', 'requiredSpeedLabel', 'curve',
		'measurements', 'currentCaption', 'previousCaption', 'currentRun', 'previousRun' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'initialization' }
SoSeAtelierRevisitPresenter >> initializePresenters [
	super initializePresenters.
	estimateAction := [ ].
	estimateButton := self newButton label: 'Estimer le réglage courant'; action: [ estimateAction value ]; yourself.
	estimateLabel := self newLabel yourself.
	requiredSpeedLabel := self newLabel yourself.
	curve := self newImage autoScale: true; yourself.
	self number: #evaluationDelay initial: 180.0 from: 0.01 to: 1000000.
	currentCaption := self newLabel label: 'Simule une mission pour évaluer son historique.'; yourself.
	previousCaption := self newLabel yourself.
	measurements := self newTable
		addColumn: (SpStringTableColumn title: 'Indicateur' evaluated: #first);
		addColumn: ((SpStringTableColumn title: 'Précédent' evaluated: #second) width: 88; yourself);
		addColumn: ((SpStringTableColumn title: 'Dernier' evaluated: #third) width: 88; yourself);
		yourself
]

{ #category : 'layout' }
SoSeAtelierRevisitPresenter >> defaultLayout [
	^ self column
		add: estimateButton height: 30;
		add: estimateLabel height: 20;
		add: requiredSpeedLabel height: 20;
		add: curve height: 190;
		add: (SpBoxLayout newLeftToRight spacing: 6;
			add: (self row: 'Délai évalué · s' field: #evaluationDelay);
			add: (self newButton label: 'Évaluer les historiques'; action: [ self updateMeasurements ]; yourself);
			yourself) height: 29;
		add: currentCaption height: 20;
		add: previousCaption height: 20;
		add: measurements;
		yourself
]

{ #category : 'actions' }
SoSeAtelierRevisitPresenter >> onEstimate: action [
	estimateAction := action
]

{ #category : 'actions' }
SoSeAtelierRevisitPresenter >> estimationEnabled: enabled [
	estimateButton enabled: enabled
]

{ #category : 'estimating' }
SoSeAtelierRevisitPresenter >> estimateFor: settings perimeter: metres [
	| gap speed target required |
	speed := settings at: #nominalSpeed.
	target := settings at: #revisitTargetSeconds.
	gap := metres / (settings at: #numberOfDrones).
	required := gap / target.
	estimateLabel label: ('Écart à l’équilibre ', (self printValue: gap), ' m · Délai à vitesse nominale ',
		(self printValue: gap / speed), ' s').
	requiredSpeedLabel label: ('Objectif ', (self printValue: target), ' s · Vitesse nécessaire ',
		(self printValue: required), ' m/s', (required > (settings at: #maxSpeed)
			ifTrue: [ ' · Dépasse le maximum' ] ifFalse: [ '' ])).
	curve image: (self commandChartFor: settings maximumGap: gap)
]

{ #category : 'drawing' }
SoSeAtelierRevisitPresenter >> commandChartFor: settings maximumGap: gap [
	| chart canvas drone behavior tick nominal target x descriptions legend palette |
	tick := settings at: #tickSeconds.
	nominal := (settings at: #nominalSpeed) * tick.
	target := settings at: #revisitTargetSeconds.
	drone := MacroSimulatorDrone new
		minSpeed: (settings at: #minSpeed) * tick;
		maxSpeed: (settings at: #maxSpeed) * tick;
		nominalSpeed: nominal;
		currentSpeed: nominal;
		revisitTargetSeconds: target;
		secondsPerTick: tick;
		yourself.
	behavior := MacroSimulatorBehavior new sensibility: 0.01; pacingRate: 0.9; yourself.
	canvas := RSCanvas new extent: 520 @ 235; color: Color white; yourself.
	chart := RSCompositeChart new container: canvas; extent: 430 @ 130;
		title: 'Consigne à vitesse nominale';
		xlabel: 'Déséquilibre relatif avant/arrière'; ylabel: 'Consigne · m/s'; yourself.
	legend := RSLegend new container: canvas; yourself.
	legend layout horizontal gapSize: 12.
	legend location offset: 8.
	x := (-60 to: 60) collect: [ :index | index / 2000.0 ].
	descriptions := settings at: #commandLaws ifAbsent: [ SoSeAtelierCommandLaw presets ].
	palette := #('BB510C' '3164B1' '16845F' '884AC0' 'AA3676' '4E7382').
	descriptions doWithIndex: [ :law :index |
		| y command color |
		command := law compileBlock.
		color := Color fromHexString: (palette atWrap: index).
		y := x collect: [ :error |
			| local speed |
			local := SoSeAtelierLocalInput of: drone ahead: gap * (1 + (error min: 0))
				behind: gap * (1 - (error max: 0)) behavior: behavior.
			local distanceWeight: (settings at: #distanceWeight ifAbsent: [ 2 ]).
			speed := command value: local.
			(speed isNumber and: [ speed asFloat isFinite ]) ifFalse: [
				self error: 'La loi « ', law label, ' » ne renvoie pas de consigne numérique finie.' ].
			((speed min: drone maxSpeed) max: drone minSpeed) / tick ].
		chart add: (RSLinePlot new x: x y: y; color: color; yourself).
		legend text: law label withBoxColor: color ].
	chart horizontalTick numberOfTicks: 7; asFloat: 2.
	chart verticalTick numberOfTicks: 4; asFloat: 1.
	chart build.
	legend build.
	canvas zoomToFit.
	^ canvas asForm
]

{ #category : 'comparison' }
SoSeAtelierRevisitPresenter >> clear [
	currentRun := previousRun := nil.
	estimateLabel label: ''.
	requiredSpeedLabel label: ''.
	curve image: (Form extent: 1 @ 1 depth: 32).
	currentCaption label: 'Simule une mission pour évaluer son historique.'.
	previousCaption label: ''.
	measurements items: #()
]

{ #category : 'comparison' }
SoSeAtelierRevisitPresenter >> addRun: report [
	previousRun := currentRun.
	currentRun := report.
	report target ifNotNil: [ :target | (self field: #evaluationDelay) number: target ].
	currentCaption label: 'Dernier · ', report caption.
	previousCaption label: (previousRun ifNil: [ '' ] ifNotNil: [ 'Précédent · ', previousRun caption ]).
	self updateMeasurements
]

{ #category : 'comparison' }
SoSeAtelierRevisitPresenter >> updateMeasurements [
	| labels target current previous |
	currentRun ifNil: [ ^ self ].
	labels := #('Objectif embarqué · s' 'Délai estimé au dernier tik · s' 'Pire délai estimé · s'
		'Tiks au-delà du délai évalué' 'Écart type final · m' 'Vitesse de commande finale · m/s'
		'Distance directe moyenne · %' 'Gisement exploitable moyen · %' 'Hors portée moyen · %' 'Indisponible moyen · %').
	target := (self field: #evaluationDelay) number.
	current := currentRun indicatorsFor: target.
	previous := previousRun ifNotNil: [ previousRun indicatorsFor: target ].
	measurements items: ((1 to: labels size) collect: [ :index |
		{ labels at: index. self printValue: (previous ifNotNil: [ previous at: index ]).
			self printValue: (current at: index) } ])
]

{ #category : 'formatting' }
SoSeAtelierRevisitPresenter >> printValue: value [
	value ifNil: [ ^ '—' ].
	value isInteger ifTrue: [ ^ value printString ].
	value isFinite ifFalse: [ ^ '∞' ].
	^ value printShowingDecimalPlaces: 1
]
