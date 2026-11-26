Class {
	#name : 'SoSeAtelierMissionPresenter',
	#superclass : 'SoSeAtelierFormPresenter',
	#instVars : [ 'points', 'terrainDirectory', 'terrainLabel', 'pointsList', 'nominalLabel', 'notebook',
		'generateAction', 'generateButton', 'mapAction', 'mapBounds', 'areaLabel', 'exampleMenu', 'exampleId' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'configuration' }
SoSeAtelierMissionPresenter class >> numericFields [
	^ #(numberOfDrones ticks tickSeconds minSpeed maxSpeed sensingRadius captureRadius seed seedIndex
		revisitTargetSeconds distanceWeight bearingHalfAngle)
]

{ #category : 'initialization' }
SoSeAtelierMissionPresenter >> initializePresenters [
	super initializePresenters.
	points := OrderedCollection new.
	terrainDirectory := FileLocator imageDirectory.
	generateAction := [ ].
	mapAction := [ ].
	terrainLabel := self newLabel label: 'Choisis un dossier de MNT'; yourself.
	areaLabel := self newLabel label: 'Emprise automatique'; yourself.
	pointsList := self newList display: [ :point |
		(point longitude printShowingDecimalPlaces: 6), '   ', (point latitude printShowingDecimalPlaces: 6) ]; yourself.
	self initializeSimulationControls.
	self initializeTerrainControls.
	notebook := self newNotebook
		addPageTitle: 'Simulation' provider: [ self scrollPage: self simulationLayout ];
		addPageTitle: 'Terrain et parcours' provider: [ self scrollPage: self terrainLayout ];
		yourself.
	(FileLocator imageDirectory / 'rejeu-vercors' / 'parcours-vercors.geojson') isFile
		ifTrue: [ self loadVercors ]
]

{ #category : 'initialization' }
SoSeAtelierMissionPresenter >> initializeSimulationControls [
	self number: #numberOfDrones initial: 20 from: 1 to: 10000.
	self number: #ticks initial: 140 from: 0 to: 100000.
	self number: #tickSeconds initial: 2.0 from: 0.01 to: 1000.
	self number: #minSpeed initial: 5.0 from: 0 to: 1000.
	nominalLabel := self newLabel label: '10 m/s'; yourself.
	(self slider: #nominalSpeed initial: 10 from: 1 to: 60)
		whenValueChangedDo: [ :value | nominalLabel label: value rounded printString, ' m/s' ].
	self number: #maxSpeed initial: 15.0 from: 0.01 to: 1000.
	self number: #sensingRadius initial: 1600.0 from: 0 to: 1000000.
	self number: #captureRadius initial: 90.0 from: 0 to: 1000000.
	self number: #revisitTargetSeconds initial: 180.0 from: 0.01 to: 1000000.
	self number: #distanceWeight initial: 2.0 from: 0 to: 10.
	self number: #bearingHalfAngle initial: 180.0 from: 0 to: 180.
	self number: #seed initial: 3950149054165 from: 1 to: 9007199254740991.
	self number: #seedIndex initial: 10 from: 1 to: MacroSimulatorExample isseRandomSequence size.
	self choice: #policy labels: SoSeAtelierSimulation commandChoices.
	self choice: #perceptionMode labels: SoSeAtelierSimulation perceptionChoices
]

{ #category : 'initialization' }
SoSeAtelierMissionPresenter >> initializeTerrainControls [
	exampleMenu := self newDropList display: [ :entry | entry value ];
		items: ({ 'vercors' -> 'Vercors' }, (SoSeAtelierResources examples collect: [ :example |
			(example at: 'id') -> (example at: 'label') ]));
		selectFirst; yourself.
	self number: #longitude initial: 5.35 from: -180 to: 180.
	self number: #latitude initial: 44.89 from: -90 to: 90.
	self check: #hull label: 'Enveloppe convexe' initial: false.
	self number: #gridStep initial: 25.0 from: 0.1 to: 10000.
	self number: #margin initial: 700.0 from: 0 to: 100000.
	self choice: #source labels: { #auto -> 'Automatique'. #copernicus -> 'Copernicus'. #ign -> 'IGN'. #usgs -> 'USGS' }.
	fields at: #geoTiff put: self newTextInput.
	generateButton := self newButton
		label: 'Générer le MNT…';
		action: [ generateAction value ];
		yourself
]

{ #category : 'layout' }
SoSeAtelierMissionPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom add: notebook; yourself
]

{ #category : 'layout' }
SoSeAtelierMissionPresenter >> simulationLayout [
	^ self column
		add: (self row: 'Drones' field: #numberOfDrones) height: 30;
		add: (self row: 'Nombre de tiks' field: #ticks) height: 30;
		add: (self row: 'Durée du tik · s' field: #tickSeconds) height: 30;
		add: (self row: 'Vitesse min · m/s' field: #minSpeed) height: 30;
		add: (SpBoxLayout newLeftToRight
			add: (self newLabel label: 'Vitesse nominale'; yourself);
			add: nominalLabel width: 72; yourself) height: 24;
		add: (self field: #nominalSpeed) height: 28;
		add: (self row: 'Vitesse max · m/s' field: #maxSpeed) height: 30;
		add: (self row: 'Portée voisins · m' field: #sensingRadius) height: 30;
		add: (self row: 'Capture macro · m' field: #captureRadius) height: 30;
		add: (self row: 'Objectif revisite · s' field: #revisitTargetSeconds) height: 30;
		add: (self newLabel label: 'Loi de commande'; yourself) height: 22;
		add: (self field: #policy) height: 30;
		add: (self row: 'Poids des écarts' field: #distanceWeight) height: 30;
		add: (self newLabel label: 'Perception des voisins'; yourself) height: 22;
		add: (self field: #perceptionMode) height: 30;
		add: (self row: 'Demi-angle gisement · °' field: #bearingHalfAngle) height: 30;
		add: (self row: 'Graine' field: #seed) height: 30;
		add: (self row: 'Indice ISSe' field: #seedIndex) height: 30;
		yourself
]

{ #category : 'layout' }
SoSeAtelierMissionPresenter >> terrainLayout [
	^ self column
		add: terrainLabel height: 24;
		add: exampleMenu height: 29;
		add: (self newButton label: 'Charger l’exemple'; action: [ self chooseExample ]; yourself) height: 29;
		add: (self newButton label: 'Dessiner sur la carte…'; action: [ mapAction value ]; yourself) height: 31;
		add: areaLabel height: 21;
		add: (self newButton label: 'Ouvrir un MNT…'; action: [ self chooseTerrain ]; yourself) height: 28;
		add: (self newLabel label: 'Points du parcours · WGS84'; yourself) height: 24;
		add: pointsList height: 124;
		add: (SpBoxLayout newLeftToRight spacing: 4;
			add: (self newButton label: 'Monter'; action: [ self movePointBy: -1 ]; yourself);
			add: (self newButton label: 'Descendre'; action: [ self movePointBy: 1 ]; yourself);
			add: (self newButton label: 'Retirer'; action: [ self removePoint ]; yourself);
			yourself) height: 28;
		add: (self row: 'Longitude · °' field: #longitude) height: 28;
		add: (self row: 'Latitude · °' field: #latitude) height: 28;
		add: (SpBoxLayout newLeftToRight spacing: 4;
			add: (self newButton label: 'Ajouter un point'; action: [ self addPoint ]; yourself);
			add: (self field: #hull);
			yourself) height: 29;
		add: (self row: 'Maille · m' field: #gridStep) height: 28;
		add: (self row: 'Marge MNT · m' field: #margin) height: 28;
		add: (self row: 'Source du MNT' field: #source) height: 28;
		add: (self newLabel label: 'GeoTIFF local (chemin facultatif)'; yourself) height: 21;
		add: (self field: #geoTiff) height: 29;
		add: generateButton height: 30;
		yourself
]

{ #category : 'scenarios' }
SoSeAtelierMissionPresenter >> useScenario: scenario [
	| usesConfiguration |
	usesConfiguration := #(vercors geographic sose) includes: scenario.
	#(numberOfDrones tickSeconds minSpeed nominalSpeed maxSpeed sensingRadius captureRadius policy seed distanceWeight)
		do: [ :key | (self field: key) enabled: usesConfiguration ].
	(self field: #ticks) enabled: (usesConfiguration or: [ scenario = #isse ]).
	(self field: #revisitTargetSeconds) enabled: (usesConfiguration or: [ scenario = #isse ]).
	(self field: #perceptionMode) enabled: (#(vercors geographic) includes: scenario).
	(self field: #bearingHalfAngle) enabled: (#(vercors geographic) includes: scenario).
	(self field: #perceptionMode) selectFirst.
	(self field: #seedIndex) enabled: scenario = #isse.
	(#(vercors geographic) includes: scenario) ifTrue: [
		(self field: #numberOfDrones) number: 20.
		(self field: #ticks) number: 140.
		(self field: #tickSeconds) number: 2.
		(self field: #sensingRadius) number: 1600.
		(self field: #captureRadius) number: 90.
		self selectChoice: #revisedCapingPolicy ofField: #policy ].
	scenario = #sose ifTrue: [
		(self field: #numberOfDrones) number: 100.
		(self field: #ticks) number: 1500.
		(self field: #tickSeconds) number: 1.
		(self field: #sensingRadius) number: 20.
		(self field: #captureRadius) number: 20.
		self selectChoice: #capingPolicy ofField: #policy ].
	usesConfiguration ifFalse: [
		(self field: #ticks) number: 1500.
		(self field: #tickSeconds) number: 1 ].
	(self field: #minSpeed) number: 5.
	(self field: #nominalSpeed) value: 10.
	(self field: #maxSpeed) number: 15
]

{ #category : 'accessing' }
SoSeAtelierMissionPresenter >> simulationSettings [
	| options |
	options := Dictionary new.
	self class numericFields
		do: [ :key | options at: key put: (self field: key) number ].
	options at: #nominalSpeed put: (self field: #nominalSpeed) value.
	options at: #policy put: (self choiceValue: #policy).
	options at: #perceptionMode put: (self choiceValue: #perceptionMode).
	^ options
]

{ #category : 'accessing' }
SoSeAtelierMissionPresenter >> terrain [
	^ SoSeAtelierTerrain directory: terrainDirectory points: points convexHull: (self field: #hull) state bounds: mapBounds
]

{ #category : 'accessing' }
SoSeAtelierMissionPresenter >> exampleId [
	^ exampleId
]

{ #category : 'accessing' }
SoSeAtelierMissionPresenter >> mapPlan [
	^ SoSeAtelierMapPlan waypoints: (points asArray collect: [ :point | { point longitude. point latitude } ])
		bounds: mapBounds convexHull: (self field: #hull) state
]

{ #category : 'configuration' }
SoSeAtelierMissionPresenter >> commandChoices: choices selecting: preferred [
	| menu key |
	menu := self field: #policy.
	key := preferred ifNil: [ menu selectedItem ifNotNil: [ :entry | entry key ] ].
	menu items: choices.
	self selectChoice: key ofField: #policy
]

{ #category : 'configuration' }
SoSeAtelierMissionPresenter >> applySimulationSettings: settings [
	self class numericFields
		do: [ :key | (self field: key) number: (settings at: key asString) ].
	(self field: #nominalSpeed) value: (settings at: 'nominalSpeed').
	self selectChoice: (settings at: 'policy') asSymbol ofField: #policy.
	self selectChoice: (settings at: 'perceptionMode') asSymbol ofField: #perceptionMode
]

{ #category : 'configuration' }
SoSeAtelierMissionPresenter >> terrainSettings [
	| settings |
	settings := self generationSettings.
	^ { 'directory' -> terrainDirectory asFileReference fullName. 'gridStep' -> settings first.
		'margin' -> settings second. 'source' -> settings third. 'geoTiff' -> settings fourth } asDictionary
]

{ #category : 'configuration' }
SoSeAtelierMissionPresenter >> applyTerrainSettings: settings example: identifier [
	| path |
	path := (settings at: 'directory') asFileReference.
	(identifier notNil and: [ identifier = 'vercors' or: [ (SoSeAtelierResources exampleNamed: identifier) notNil ] ])
		ifTrue: [
			(identifier = 'vercors' and: [ (FileLocator imageDirectory / 'rejeu-vercors' / 'parcours-vercors.geojson') isFile not ])
				ifTrue: [ self restoreTerrainPath: path ]
				ifFalse: [ self loadExampleNamed: identifier ] ]
		ifFalse: [ self restoreTerrainPath: path ].
	(self field: #gridStep) number: (settings at: 'gridStep').
	(self field: #margin) number: (settings at: 'margin').
	self selectChoice: (settings at: 'source') asSymbol ofField: #source.
	(self field: #geoTiff) text: ((settings at: 'geoTiff') ifNil: [ '' ])
]

{ #category : 'configuration' }
SoSeAtelierMissionPresenter >> restoreTerrainPath: path [
	((path / 'terrain.json') isFile and: [ (path / 'mnt.csv') isFile ])
		ifTrue: [ self useTerrainDirectory: path ]
		ifFalse: [
			terrainDirectory := path.
			exampleId := nil.
			terrainLabel label: 'MNT à retrouver · ', path basename ]
]

{ #category : 'accessing' }
SoSeAtelierMissionPresenter >> generationSettings [
	| path |
	path := (self field: #geoTiff) text asString trimBoth.
	^ { (self field: #gridStep) number. (self field: #margin) number.
		(self choiceValue: #source) asString. path ifEmpty: [ nil ] }
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> useTerrainDirectory: aDirectory [
	| size |
	(aDirectory asFileReference / 'mnt.csv') isFile
		ifFalse: [ self error: 'Choisis un dossier qui contient terrain.json et mnt.csv.' ].
	size := (SoSeAtelierTerrain directory: aDirectory points: points convexHull: false) cellSize.
	terrainDirectory := aDirectory asFileReference.
	exampleId := nil.
	terrainLabel label: terrainDirectory basename, ' · ', size first printString, ' m'
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> chooseTerrain [
	| directory |
	directory := UIManager default chooseDirectory: 'Ouvrir un dossier de terrain'.
	directory ifNil: [ ^ self ].
	[ self openTerrainDirectory: directory ] on: Error do: [ :error | self inform: error messageText ]
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> openTerrainDirectory: directory [
	| plan |
	plan := SoSeAtelierTerrain savedPlanIn: directory.
	self useTerrainDirectory: directory.
	(self field: #gridStep) number: self terrain cellSize first.
	plan ifNotNil: [ self applyMapPlan: plan ]
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> loadVercors [
	| vercors |
	vercors := SoSeAtelierTerrain vercorsFrom: FileLocator imageDirectory / 'rejeu-vercors'.
	self useTerrainDirectory: vercors directory.
	self applyMapPlan: (SoSeAtelierMapPlan waypoints: (vercors points collect: [ :point | { point longitude. point latitude } ])
		bounds: nil convexHull: false).
	exampleId := 'vercors'.
	(self field: #gridStep) number: vercors cellSize first.
	(self field: #geoTiff) text: ''
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> chooseExample [
	[ self loadExampleNamed: exampleMenu selectedItem key ] on: Error do: [ :error | self inform: error messageText ]
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> loadExampleNamed: identifier [
	| site plan |
	identifier = 'vercors' ifTrue: [ ^ self loadVercors ].
	site := SoSeAtelierResources exampleNamed: identifier.
	site ifNil: [ self error: 'Exemple de terrain introuvable.' ].
	plan := SoSeAtelierMapPlan fromJSON: site.
	self useTerrainDirectory: (SoSeAtelierResources directoryFor: identifier).
	exampleId := identifier.
	(self field: #gridStep) number: (site at: 'gridStep').
	(self field: #geoTiff) text: ''.
	exampleMenu selectItem: (exampleMenu items detect: [ :entry | entry key = identifier ]).
	self applyMapPlan: plan
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> applyMapPlan: plan [
	points := plan geoPoints asOrderedCollection.
	mapBounds := plan bounds.
	(self field: #hull) state: plan convexHull.
	pointsList items: points copy.
	areaLabel label: (mapBounds ifNil: [ 'Emprise automatique' ] ifNotNil: [ 'Emprise définie sur la carte' ])
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> addPoint [
	points add: (GeoPoint latitude: (self field: #latitude) number
		longitude: (self field: #longitude) number altitude: 0).
	pointsList items: points copy; selectIndex: points size
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> removePoint [
	| index |
	index := pointsList selectedIndex.
	index > 0 ifFalse: [ ^ self ].
	points removeAt: index.
	pointsList items: points copy
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> movePointBy: offset [
	| index next |
	index := pointsList selectedIndex.
	next := index + offset.
	(index > 0 and: [ next between: 1 and: points size ]) ifFalse: [ ^ self ].
	points swap: index with: next.
	pointsList items: points copy; selectIndex: next
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> onGenerate: aBlock [
	generateAction := aBlock
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> onMap: aBlock [
	mapAction := aBlock
]

{ #category : 'actions' }
SoSeAtelierMissionPresenter >> generationEnabled: enabled [
	generateButton enabled: enabled
]
