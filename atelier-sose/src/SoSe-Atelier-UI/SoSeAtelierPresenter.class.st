"
Atelier natif pour préparer, simuler et filmer une mission. L'image et les
services du profil SoSe-Atelier fournissent le moteur et les dépendances.
"
Class {
	#name : 'SoSeAtelierPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'mission', 'options', 'revisit', 'laws', 'mapServer', 'scenarioList', 'notebook', 'editor', 'sourceView',
		'mapView', 'metricsView', 'status', 'runButton', 'playButton', 'stopButton', 'csvButton', 'videoButton',
		'renderButton', 'renderServer',
		'openMissionButton', 'saveMissionButton',
		'simulator', 'metrics', 'runTerrain', 'runSeconds', 'playToken', 'busy', 'closed', 'drafts', 'scenario'
	],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'initialization' }
SoSeAtelierPresenter >> initializePresenters [
	busy := closed := false.
	drafts := Dictionary new.
	mission := self instantiate: SoSeAtelierMissionPresenter.
	options := self instantiate: SoSeAtelierOptionsPresenter.
	revisit := self instantiate: SoSeAtelierRevisitPresenter.
	laws := self instantiate: SoSeAtelierLawPresenter.
	laws onChoice: [ :entries :key | mission commandChoices: entries selecting: key ].
	mapServer := SoSeAtelierMapServer new.
	mission onGenerate: [ self generateTerrain ].
	mission onMap: [ [ self openMap ] on: Error do: [ :error | self signalFailure: error messageText ] ].
	revisit onEstimate: [ [ self estimateRevisit ] on: Error do: [ :error | self signalFailure: error messageText ] ].
	scenarioList := self newDropList display: [ :entry | entry value ]; items: SoSeAtelierSimulation scenarios; selectFirst; yourself.
	editor := self newCode beForScripting; lineNumbers: true; yourself.
	sourceView := self newCode lineNumbers: true; beNotEditable; yourself.
	mapView := self newImage autoScale: true; yourself.
	metricsView := self newTable
		addColumn: (SpStringTableColumn title: 'Indicateur' evaluated: [ :each | each key ]);
		addColumn: (SpStringTableColumn title: 'Dernier tik' evaluated: [ :each | each value ]);
		yourself.
	notebook := self newNotebook
		addPageTitle: 'Code du scénario' provider: [ editor ];
		addPageTitle: 'Carte' provider: [ mapView ];
		addPageTitle: 'Métriques' provider: [ metricsView ];
		addPageTitle: 'Revisite' provider: [ revisit ];
		addPageTitle: 'Commande' provider: [ laws ];
		addPageTitle: 'Source d’origine' provider: [ sourceView ];
		yourself.
	status := self newLabel label: 'Choisis un scénario, règle la mission et lance la simulation.'; yourself.
	self initializeButtons.
	scenarioList whenSelectedItemChangedDo: [ :item | item ifNotNil: [ self selectScenario: item key ] ].
	self selectScenario: scenarioList selectedItem key.
	self refreshActions
]

{ #category : 'initialization' }
SoSeAtelierPresenter >> initializeButtons [
	openMissionButton := self button: 'Ouvrir mission…' action: [ self chooseMissionToOpen ].
	saveMissionButton := self button: 'Enregistrer…' action: [ self chooseMissionToSave ].
	runButton := self button: 'Simuler' action: [ self runSimulation ].
	playButton := self button: 'Lire la carte' action: [ self play ].
	renderButton := self button: 'Rejouer en 3D' action: [ self openReplay3D ].
	stopButton := self button: 'Arrêter' action: [ self stop ].
	csvButton := self button: 'Exporter CSV…' action: [ self exportMetrics ].
	videoButton := self button: 'Exporter MP4…' action: [ self exportVideo ]
]

{ #category : 'initialization' }
SoSeAtelierPresenter >> button: title action: action [
	^ self newButton
		label: title;
		action: [ [ action value ] on: Error do: [ :error | self signalFailure: error messageText ] ];
		yourself
]

{ #category : 'initialization' }
SoSeAtelierPresenter >> initializeWindow: window [
	window title: 'Atelier SoSe'; initialExtent: 1320 @ 780;
		whenClosedDo: [
			closed := true.
			playToken := nil.
			mapServer stop.
			renderServer ifNotNil: [ renderServer stop ] ]
]

{ #category : 'layout' }
SoSeAtelierPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		borderWidth: 10;
		spacing: 8;
		add: self scenarioLayout height: 30;
		add: self toolbarLayout height: 30;
		add: (SpPanedLayout newLeftToRight positionOfSlider: 25 percent;
			add: mission;
			add: (SpPanedLayout newLeftToRight positionOfSlider: 65 percent;
				add: notebook;
				add: options;
				yourself);
			yourself);
		add: status height: 27;
		yourself
]

{ #category : 'layout' }
SoSeAtelierPresenter >> scenarioLayout [
	^ SpBoxLayout newLeftToRight spacing: 7;
		add: (self newLabel label: 'Scénario'; yourself) width: 68;
		add: scenarioList expand: true;
		add: openMissionButton expand: false;
		add: saveMissionButton expand: false;
		yourself
]

{ #category : 'layout' }
SoSeAtelierPresenter >> toolbarLayout [
	^ SpBoxLayout newLeftToRight spacing: 7;
		add: runButton;
		add: playButton;
		add: renderButton;
		add: stopButton;
		add: csvButton;
		add: videoButton;
		yourself
]

{ #category : 'scenarios' }
SoSeAtelierPresenter >> selectScenario: selector [
	| original |
	scenario ifNotNil: [ drafts at: scenario put: editor text asString ].
	scenario := selector.
	editor text: (drafts at: selector ifAbsent: [ SoSeAtelierSimulation sourceFor: selector ]).
	original := selector caseOf: {
		[ #vercors ] -> [ SoSeVercorsExample >> #simulate ].
		[ #geographic ] -> [ SoSeAtelierSimulation >> #simulateurSurParcours ].
		[ #sose ] -> [ FullAppMacroReplay class >> #soSe ].
		[ #soseLegacy ] -> [ FullAppMacroReplay class >> #soSe ].
		[ #isse ] -> [ MacroSimulatorExample class >> #generateScenario:withThreshold: ] }
		otherwise: [ MacroSimulatorExample class >> selector ].
	sourceView text: original sourceCode.
	mission useScenario: selector.
	options useScenario: selector.
	notebook selectPageIndex: 1.
	self refreshActions
]

{ #category : 'actions' }
SoSeAtelierPresenter >> estimateRevisit [
	| settings recipe example |
	settings := mission simulationSettings.
	settings at: #commandLaws put: laws snapshot.
	recipe := SoSeAtelierSimulation terrain: mission terrain settings: settings.
	example := scenario.
	self performWork: [
		recipe configurer: MacroSimulatorParameters new.
		recipe longueurPour: example ]
		status: 'Calcul de la revisite à l’équilibre…'
		then: [ :perimeter |
			revisit estimateFor: settings perimeter: perimeter.
			status label: 'Estimation à l’équilibre · ', perimeter rounded printString, ' m de parcours.' ]
]

{ #category : 'actions' }
SoSeAtelierPresenter >> runSimulation [
	| terrain settings source recipe |
	terrain := mission terrain.
	settings := mission simulationSettings.
	settings at: #maxDate put: (options passageMaxDateFor: scenario).
	(#(vercors geographic sose) includes: scenario) ifTrue: [
		settings at: #commandLaw put: (laws lawWithId: (settings at: #policy)) ].
	source := editor text asString.
	recipe := SoSeAtelierSimulation terrain: terrain settings: settings.
	self performWork: [
		| result metricsHistory analysis |
		result := recipe runSource: source.
		(result isKindOf: MacroSimulator) ifTrue: [
			metricsHistory := result evaluateMetrics.
			analysis := SoSeAtelierRevisitRun on: result metrics: metricsHistory tickSeconds: recipe secondesParTik ].
		{ result. metricsHistory. analysis } ]
		status: 'Simulation en cours…'
		then: [ :result | self acceptSimulation: result terrain: terrain seconds: recipe secondesParTik ]
]

{ #category : 'actions' }
SoSeAtelierPresenter >> acceptSimulation: result terrain: terrain seconds: seconds [
	| ids |
	(result first isKindOf: MacroSimulator) ifFalse: [
		simulator := metrics := runTerrain := runSeconds := nil.
		metricsView items: #().
		mapView image: (Form extent: 1 @ 1 depth: 32).
		options setDroneIds: #().
		status label: 'Exemple exécuté · résultat ', result first class name asString.
		^ self ].
	simulator := result first.
	metrics := result second.
	runTerrain := terrain.
	runSeconds := seconds.
	ids := Set new.
	simulator history do: [ :step | step drones do: [ :drone | ids add: drone id ] ].
	options setDroneIds: ids.
	self showMetrics: metrics fields: options metricFields.
	revisit addRun: result third.
	status label: simulator history size printString, ' états · ', runTerrain directory basename.
	notebook selectPageIndex: 3
]

{ #category : 'metrics' }
SoSeAtelierPresenter >> showMetrics: history fields: fields [
	| sample descriptions rows |
	history history ifEmpty: [ ^ metricsView items: #() ].
	sample := history history last.
	descriptions := SoSeAtelierOptionsPresenter metricChoices asDictionary.
	descriptions at: #timeStep put: 'Tik'.
	rows := fields select: [ :field | sample respondsTo: field ] thenCollect: [ :field |
		| value |
		value := sample perform: field.
		(descriptions at: field) -> (value isFloat
			ifTrue: [ value printShowingDecimalPlaces: 3 ]
			ifFalse: [ value printString ]) ].
	metricsView items: rows
]

{ #category : 'actions' }
SoSeAtelierPresenter >> generateTerrain [
	| parent snapshot settings |
	parent := UIManager default chooseDirectory: 'Dossier de sortie du MNT'.
	parent ifNil: [ ^ self ].
	snapshot := mission terrain.
	settings := mission generationSettings.
	self performWork: [ snapshot generateIn: parent step: settings first margin: settings second
		source: settings third geoTiff: settings fourth ]
		status: 'Préparation du terrain avec GDAL…'
		then: [ :path |
			mission useTerrainDirectory: path.
			status label: 'MNT prêt · lance la simulation avec ce terrain.' ]
]

{ #category : 'cartography' }
SoSeAtelierPresenter >> openMap [
	| address settings |
	settings := mission generationSettings.
	mapServer onSaveTerrain: [ :request :report |
		UIManager default defer: [
			[ self saveTerrainFromMap: request report: report ] on: Error do: [ :error |
				report value: 'error' value: error messageText ] ] ]
		options: { 'step' -> settings first. 'margin' -> settings second } asDictionary.
	address := mapServer startWith: mission mapPlan example: mission exampleId onApply: [ :plan :identifier |
		UIManager default defer: [ closed ifFalse: [
			[ (identifier notNil and: [ identifier ~= mission exampleId ]) ifTrue: [
				mission loadExampleNamed: identifier ].
			mission applyMapPlan: plan.
			status label: 'Tracé cartographique appliqué · ', plan geoPoints size printString, ' points.' ]
				on: Error do: [ :error | self signalFailure: error messageText ] ] ] ].
	status label: 'Carte locale · ', address.
	WebBrowser openOn: address
]

{ #category : 'cartography' }
SoSeAtelierPresenter >> saveTerrainFromMap: request report: report [
	| source geoTiff directory snapshot |
	closed ifTrue: [ self error: 'Rouvre la carte depuis l’atelier.' ].
	busy ifTrue: [ self error: 'Attends la fin de l’opération en cours dans Pharo.' ].
	source := request at: #source.
	source = 'geotiff' ifTrue: [
		report value: 'pending' value: 'Choisis le fichier GeoTIFF dans Pharo.'.
		geoTiff := UIManager default chooseFullFileNameMatching: #('*.tif' '*.tiff') label: 'Choisir le GeoTIFF du terrain'.
		geoTiff ifNil: [ ^ report value: 'cancelled' value: 'Enregistrement annulé.' ] ].
	source = 'example' ifTrue: [
		geoTiff := (SoSeAtelierResources directoryFor: (request at: #example)) / 'relief.tif' ].
	report value: 'pending' value: 'Choisis le dossier de destination dans Pharo.'.
	directory := UIManager default chooseDirectory: 'Dossier de destination du nouveau terrain'.
	directory ifNil: [ ^ report value: 'cancelled' value: 'Enregistrement annulé.' ].
	snapshot := request at: #terrain.
	report value: 'pending' value: 'Préparation et enregistrement de la grille avec GDAL…'.
	self performWork: [ snapshot saveNamed: (request at: #name) into: directory
		step: (request at: #step) margin: (request at: #margin) source: source geoTiff: geoTiff ]
		status: 'Enregistrement du terrain cartographique…'
		then: [ :path |
			mission openTerrainDirectory: path.
			(mission field: #margin) number: (request at: #margin).
			mission selectChoice: source asSymbol ofField: #source.
			(mission field: #geoTiff) text: (geoTiff ifNil: [ '' ] ifNotNil: [ geoTiff asFileReference fullName ]).
			status label: 'Terrain enregistré et chargé · ', path basename.
			report value: 'saved' value: ('Terrain enregistré et chargé dans Pharo · ', path fullName) ]
		onFailure: [ :message |
			status label: message.
			report value: 'error' value: message ]
]

{ #category : 'mission files' }
SoSeAtelierPresenter >> missionDocument [
	| settings |
	settings := Dictionary new.
	mission simulationSettings keysAndValuesDo: [ :key :value |
		settings at: key asString put: (value isSymbol ifTrue: [ value asString ] ifFalse: [ value ]) ].
	^ { 'format' -> 'sose-mission'. 'version' -> 1. 'scenario' -> scenario asString.
		'source' -> editor text asString. 'laws' -> (laws snapshot collect: #asJSON) asArray.
		'plan' -> mission mapPlan asJSON. 'example' -> mission exampleId.
		'simulation' -> settings. 'terrain' -> mission terrainSettings. 'display' -> options configuration } asDictionary
]

{ #category : 'mission files' }
SoSeAtelierPresenter >> loadMissionFrom: file [
	| document selector entry plan commands |
	document := SoSeAtelierMissionFile read: file.
	selector := (document at: 'scenario') asSymbol.
	entry := scenarioList items detect: [ :item | item key = selector ] ifNone: [
		self error: 'Le scénario enregistré est absent de cette image Pharo.' ].
	plan := SoSeAtelierMapPlan fromJSON: (document at: 'plan').
	commands := (document at: 'laws') collect: [ :law | SoSeAtelierCommandLaw fromJSON: law ].
	mission applyTerrainSettings: (document at: 'terrain') example: (document at: 'example').
	self stop.
	mapServer stop.
	scenarioList selectItem: entry.
	laws loadLaws: commands.
	mission applySimulationSettings: (document at: 'simulation').
	laws showLawWithId: (mission choiceValue: #policy).
	mission applyMapPlan: plan.
	options setDroneIds: #(); loadConfiguration: (document at: 'display').
	editor text: (document at: 'source').
	simulator := metrics := runTerrain := runSeconds := nil.
	metricsView items: #().
	mapView image: (Form extent: 1 @ 1 depth: 32).
	revisit clear.
	notebook selectPageIndex: 1.
	self refreshActions.
	status label: 'Mission chargée · ', file asFileReference basename
]

{ #category : 'mission files' }
SoSeAtelierPresenter >> saveMissionTo: file [
	SoSeAtelierMissionFile write: self missionDocument to: file.
	status label: 'Mission enregistrée · ', file asFileReference basename
]

{ #category : 'mission files' }
SoSeAtelierPresenter >> chooseMissionToOpen [
	| path |
	path := UIManager default chooseFullFileNameMatching: #('*.json') label: 'Ouvrir une mission SoSe'.
	path ifNotNil: [ self loadMissionFrom: path ]
]

{ #category : 'mission files' }
SoSeAtelierPresenter >> chooseMissionToSave [
	| directory name file |
	directory := UIManager default chooseDirectory: 'Dossier de la mission SoSe'.
	directory ifNil: [ ^ self ].
	name := UIManager default request: 'Nom du fichier de mission' initialAnswer: 'mission-sose.json'.
	name := name ifNil: [ '' ] ifNotNil: [ name trimBoth ].
	name ifEmpty: [ ^ self ].
	((name includesAny: '/\') or: [ #('.' '..') includes: name ]) ifTrue: [ self error: 'Saisis un nom de fichier.' ].
	(name endsWith: '.json') ifFalse: [ name := name, '.json' ].
	file := directory asFileReference / name.
	(file exists and: [ (UIManager default confirm: 'Remplacer ', name, ' ?') not ]) ifTrue: [ ^ self ].
	self saveMissionTo: file
]

{ #category : 'actions' }
SoSeAtelierPresenter >> exportMetrics [
	| directory fields raw sim terrain seconds display corners threshold opticalFields |
	directory := UIManager default chooseDirectory: 'Dossier de sortie du CSV'.
	directory ifNil: [ ^ self ].
	fields := options metricFields.
	raw := metrics.
	sim := simulator.
	terrain := runTerrain.
	seconds := runSeconds.
	display := options displaySettings.
	corners := options metricZoneCorners.
	threshold := options minimumFreshRatio.
	opticalFields := SoSeAtelierOptionsPresenter opticalFields.
	self performWork: [
		| report |
		report := (fields anySatisfy: [ :field | opticalFields includes: field ])
			ifTrue: [ SoSeAtelierLecture opticalMetricsOf: sim terrain: terrain tickSeconds: seconds
				display: display zone: corners minimumFreshRatio: threshold ]
			ifFalse: [ raw ].
		{ SoSeAtelierExport metrics: report fields: fields into: directory. report } ]
		status: 'Calcul des métriques et export CSV…'
		then: [ :result |
			self showMetrics: result second fields: fields.
			notebook selectPageIndex: 3.
			status label: 'CSV · ', result first fullName ]
]

{ #category : 'actions' }
SoSeAtelierPresenter >> exportVideo [
	| directory makeLecture |
	directory := UIManager default chooseDirectory: 'Dossier de sortie de la vidéo'.
	directory ifNil: [ ^ self ].
	makeLecture := self lectureFactory.
	self performWork: [ SoSeAtelierExport video: makeLecture value into: directory ]
		status: 'Rendu Roassal et encodage FFmpeg…'
		then: [ :path | status label: 'MP4 · ', path fullName ]
]

{ #category : 'playback' }
SoSeAtelierPresenter >> openReplay3D [
	| playback ground history seconds height |
	playback := options playbackSettings.
	ground := runTerrain ifNotNil: [
		runTerrain points size >= 3 ifTrue: [ runTerrain ] ].
	history := simulator history.
	seconds := runSeconds.
	height := options displaySettings at: #height.
	self performWork: [
		SoSeAtelierRenderScene history: history tickSeconds: seconds terrain: ground
			heightAboveGround: height stride: (playback at: #stride) ]
		status: 'Préparation du rejeu 3D…'
		then: [ :scene |
			renderServer ifNotNil: [ renderServer stop ].
			renderServer := SoSeAtelierRenderServer on: scene.
			renderServer open.
			status label: 'Rejeu 3D ouvert dans le navigateur.' ]
]

{ #category : 'playback' }
SoSeAtelierPresenter >> lectureFactory [
	| terrain history seconds display timing |
	terrain := runTerrain.
	history := simulator history.
	seconds := runSeconds.
	display := options displaySettings.
	timing := options playbackSettings.
	^ [ SoSeAtelierLecture terrain: terrain history: history tickSeconds: seconds
		display: display timing: timing ]
]

{ #category : 'playback' }
SoSeAtelierPresenter >> play [
	| token makeLecture |
	makeLecture := self lectureFactory.
	self stop.
	token := Object new.
	playToken := token.
	notebook selectPageIndex: 2.
	status label: 'Préparation de la carte…'.
	self refreshActions.
	[ [ self playFramesFor: token lecture: makeLecture value ]
		on: Error do: [ :exception |
			| message |
			message := exception messageText.
			UIManager default defer: [ playToken == token ifTrue: [ self signalFailure: message ] ] ] ]
		forkAt: Processor userBackgroundPriority
]

{ #category : 'playback' }
SoSeAtelierPresenter >> playFramesFor: token lecture: lecture [
	| next frame |
	next := lecture frameReader.
	[ playToken == token and: [ frame := next value. frame notNil ] ] whileTrue: [
		[ :image :tick :seconds |
			UIManager default defer: [
				playToken == token ifTrue: [
					mapView image: image.
					status label: 'Lecture · tik ', tick printString ] ].
			(Delay forMilliseconds: ((seconds * 1000) rounded max: 10)) wait ]
			valueWithArguments: frame ].
	UIManager default defer: [
		playToken == token ifTrue: [
			playToken := nil.
			status label: 'Lecture terminée'.
			self refreshActions ] ]
]

{ #category : 'playback' }
SoSeAtelierPresenter >> stop [
	playToken ifNotNil: [
		playToken := nil.
		status label: 'Lecture arrêtée'.
		self refreshActions ]
]

{ #category : 'processing' }
SoSeAtelierPresenter >> performWork: work status: message then: action [
	self performWork: work status: message then: action onFailure: [ :error | self signalFailure: error ]
]

{ #category : 'processing' }
SoSeAtelierPresenter >> performWork: work status: message then: action onFailure: failure [
	busy ifTrue: [ ^ self ].
	self stop.
	busy := true.
	status label: message.
	self refreshActions.
	[ [ | result |
		result := work value.
		UIManager default defer: [
			closed ifFalse: [
				busy := false.
				[ action value: result ] on: Error do: [ :error | failure value: error messageText ].
				self refreshActions ] ] ]
		on: Error do: [ :exception |
			| errorMessage |
			errorMessage := exception messageText.
			UIManager default defer: [ closed ifFalse: [
				busy := false.
				failure value: errorMessage.
				self refreshActions ] ] ] ]
		forkAt: Processor userBackgroundPriority
]

{ #category : 'processing' }
SoSeAtelierPresenter >> signalFailure: message [
	busy := false.
	playToken := nil.
	status label: message.
	self refreshActions.
	self inform: message
]

{ #category : 'processing' }
SoSeAtelierPresenter >> refreshActions [
	| hasRun |
	hasRun := simulator notNil and: [ busy not ].
	scenarioList enabled: busy not.
	openMissionButton enabled: busy not.
	saveMissionButton enabled: busy not.
	runButton enabled: busy not.
	mission generationEnabled: busy not.
	revisit estimationEnabled: (busy not and: [ #(vercors geographic sose) includes: scenario ]).
	playButton enabled: hasRun.
	renderButton enabled: hasRun.
	stopButton enabled: playToken notNil.
	csvButton enabled: hasRun.
	videoButton enabled: hasRun
]
