"
Configuration de simulation utilisable depuis un Playground ou une commande
headless. Les fichiers JSON contiennent des valeurs et des sélecteurs de
scénarios. Les vitesses sont en m/s et les distances en mètres.

    | parameters simulator |
    parameters := SoSeAtelierParameters exampleComparison.
    parameters perceptionMode: #bearing; numberOfDrones: 16.
    parameters writeTo: FileLocator home / 'experience.json'.
    simulator := parameters run.
    simulator evaluateMetrics inspect.

exampleComparison construit une boucle métrique pour comparer les observations
entre voisins sans MNT. Pour un rendu, sélectionner un terrain et son tracé.
"
Class {
	#name : 'SoSeAtelierParameters',
	#superclass : 'Object',
	#instVars : [ 'scenario', 'simulation', 'display', 'playback', 'terrainOptions', 'mapPlan', 'metricFields', 'minimumFreshRatio', 'metricZone', 'baseDirectory', 'publicationOptions', 'fleetSchedule' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'examples' }
SoSeAtelierParameters class >> exampleLegacySoSe [
	^ self new
		scenario: #legacySoSe;
		numberOfDrones: 100;
		minSpeed: 10.0;
		policy: #capingPolicy;
		perceptionMode: #scenario;
		at: #sensingRadius put: 20;
		at: #captureRadius put: 20;
		at: #revisitTargetSeconds put: nil;
		ticks: 1500;
		yourself
]

{ #category : 'examples' }
SoSeAtelierParameters class >> exampleComparison [
	^ self new
		scenario: #geometry;
		syntheticLoopLength: 4000;
		perceptionMode: #hybrid;
		at: #sensorOutages put: true;
		at: #fleetWithdrawalTick put: 18;
		at: #fleetArrivalTick put: 110;
		yourself
]

{ #category : 'geometry' }
SoSeAtelierParameters class >> syntheticLoopOfLength: metres [
	| side |
	(metres > 0 and: [ metres asFloat isFinite ])
		ifFalse: [ self error: 'La longueur de la boucle doit être positive et finie.' ].
	side := metres / 4.0.
	^ { 0 @ 0. side @ 0. side @ side. 0 @ side }
]

{ #category : 'files' }
SoSeAtelierParameters class >> readFrom: file [
	| reference document |
	reference := file asFileReference asAbsolute.
	document := STONJSON fromString: reference contents.
	^ self new loadDocument: document relativeTo: reference parent
]

{ #category : 'initialization' }
SoSeAtelierParameters >> initialize [
	super initialize.
	scenario := #geometry.
	simulation := { #numberOfDrones -> 12. #minSpeed -> 5.0. #nominalSpeed -> 10.0.
		#maxSpeed -> 15.0. #sensingRadius -> 800.0. #captureRadius -> 90.0.
		#seed -> 3950149054165. #seedIndex -> 10. #policy -> #revisedCapingPolicy.
		#perceptionMode -> #hybrid. #revisitTargetSeconds -> 32.0. #tickSeconds -> 1.0.
		#ticks -> 140. #sensorOutages -> false. #distanceWeight -> 2.0.
		#bearingHalfAngle -> 180.0. #fleetWithdrawalTick -> nil. #fleetArrivalTick -> nil.
		#maxDate -> nil } asDictionary.
	display := { #background -> #hillshade. #droneColorMode -> #acceleration.
		#focusDrone -> nil. #height -> 180.0. #camera -> #(0.5 2000).
		#accelerationThreshold -> 0.05. #fadeAfterSeconds -> 40.0.
		#transparentAfterSeconds -> 75.0. #lossMarkerSeconds -> 40.0 } asDictionary.
	SoSeAtelierOptionsPresenter displayLayers do: [ :each |
		display at: each key put: (#(showDroneNames showDroneStatus) includes: each key) not ].
	playback := { #stride -> 5. #normalRate -> 20. #slowRate -> 4.0. #interval -> nil.
		#hotspot -> nil. #hotspotDrone -> nil } asDictionary.
	terrainOptions := { #example -> nil. #directory -> nil. #syntheticLoopLength -> 4000.
		#gridStep -> 30.0. #margin -> 250.0. #source -> #copernicus. #geoTiff -> nil } asDictionary.
	metricFields := #(timeStep fleetSize avgSpeed maxGap stdGap coverageRatio directPerceptionRatio
		angularPerceptionRatio unobservablePerceptionRatio outOfRangePerceptionRatio avgGapEstimationError).
	minimumFreshRatio := 0.75.
	baseDirectory := FileSystem workingDirectory
]

{ #category : 'initialization' }
SoSeAtelierParameters >> postCopy [
	super postCopy.
	simulation := simulation copy.
	display := display copy.
	playback := playback copy.
	terrainOptions := terrainOptions copy.
	publicationOptions := self publicationSettings copy.
	metricFields := metricFields copy
]

{ #category : 'publication' }
SoSeAtelierParameters >> publicationSettings [
	^ publicationOptions ifNil: [ publicationOptions := Dictionary new ]
]

{ #category : 'publication' }
SoSeAtelierParameters >> publicationAt: key put: value [
	| name |
	name := key asSymbol.
	(SoSeAtelierPublication defaultOptions includesKey: name)
		ifFalse: [ self error: 'Réglage de publication inconnu ', key asString ].
	self publicationSettings at: name put: value
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> fleetSchedule: schedule [
	fleetSchedule := schedule ifNotNil: [
		(schedule isKindOf: SoSeAtelierFleetSchedule)
			ifTrue: [ schedule ]
			ifFalse: [ SoSeAtelierFleetSchedule fromJSON: schedule ] ]
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> scenario: name [
	| selector |
	selector := name asSymbol.
	(#(geometry sose legacySoSe legacyISSe) includes: selector)
		ifFalse: [ self error: 'Scénario inconnu. Choisis geometry, sose, legacySoSe ou legacyISSe.' ].
	scenario := selector
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> at: key [
	^ simulation at: key asSymbol
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> at: key put: value [
	| name |
	name := key asSymbol.
	(simulation includesKey: name) ifFalse: [ self error: 'Réglage de simulation inconnu ', key asString ].
	simulation at: name put: ((#(policy perceptionMode) includes: name)
		ifTrue: [ value asSymbol ] ifFalse: [ value ])
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> numberOfDrones: count [
	self at: #numberOfDrones put: count
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> minSpeed: speed [
	self at: #minSpeed put: speed
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> nominalSpeed: speed [
	self at: #nominalSpeed put: speed
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> maxSpeed: speed [
	self at: #maxSpeed put: speed
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> perceptionMode: name [
	self at: #perceptionMode put: name
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> policy: name [
	self at: #policy put: name
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> ticks: count [
	self at: #ticks put: count
]

{ #category : 'simulation settings' }
SoSeAtelierParameters >> tickSeconds: seconds [
	self at: #tickSeconds put: seconds
]

{ #category : 'display settings' }
SoSeAtelierParameters >> displayAt: key [
	^ display at: key asSymbol
]

{ #category : 'display settings' }
SoSeAtelierParameters >> displayAt: key put: value [
	| name |
	name := key asSymbol.
	(display includesKey: name) ifFalse: [ self error: 'Réglage d’affichage inconnu ', key asString ].
	display at: name put: ((#(background droneColorMode) includes: name)
		ifTrue: [ value asSymbol ] ifFalse: [ value ])
]

{ #category : 'display settings' }
SoSeAtelierParameters >> heightAboveGround: metres [
	self displayAt: #height put: metres
]

{ #category : 'display settings' }
SoSeAtelierParameters >> fieldOfView: degrees [
	(degrees between: 1 and: 170)
		ifFalse: [ self error: 'Le champ de vue optique doit être compris entre 1 et 170 degrés.' ].
	display at: #camera put: { (degrees * Float pi / 360.0) tan. (display at: #camera) second }
]

{ #category : 'playback settings' }
SoSeAtelierParameters >> playbackAt: key [
	^ playback at: key asSymbol
]

{ #category : 'playback settings' }
SoSeAtelierParameters >> playbackAt: key put: value [
	| name |
	name := key asSymbol.
	(playback includesKey: name) ifFalse: [ self error: 'Réglage de lecture inconnu ', key asString ].
	playback at: name put: (value isInterval
		ifTrue: [ { value first. value last } ] ifFalse: [ value ])
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> terrainExample: name [
	name ifNotNil: [
		(name asString = 'vercors' or: [ (SoSeAtelierResources exampleNamed: name asString) notNil ])
			ifFalse: [ self error: 'Exemple de terrain inconnu ', name asString ] ].
	terrainOptions at: #example put: (name ifNotNil: [ name asString ])
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> terrainDirectory: path [
	terrainOptions at: #directory put: (path ifNotNil: [
		path isString ifTrue: [ path ] ifFalse: [ path asFileReference fullName ] ])
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> syntheticLoopLength: metres [
	self class syntheticLoopOfLength: metres.
	terrainOptions at: #syntheticLoopLength put: metres
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> path: vertices [
	mapPlan := SoSeAtelierMapPlan
		waypoints: (vertices asArray collect: [ :point | self coordinatePairFor: point ])
		bounds: (mapPlan ifNotNil: [ mapPlan bounds ])
		convexHull: (mapPlan ifNil: [ false ] ifNotNil: [ mapPlan convexHull ])
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> terrainBounds: extent [
	"Ordre WGS84 ouest, sud, est, nord."
	| plan |
	plan := mapPlan ifNil: [ self exampleMapPlan ].
	mapPlan := SoSeAtelierMapPlan
		waypoints: (plan ifNil: [ #() ] ifNotNil: [ plan asJSON at: 'waypoints' ])
		bounds: extent
		convexHull: (plan ifNil: [ false ] ifNotNil: [ plan convexHull ])
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> convexHull: useHull [
	| plan |
	plan := mapPlan ifNil: [ self exampleMapPlan ].
	mapPlan := SoSeAtelierMapPlan
		waypoints: (plan ifNil: [ #() ] ifNotNil: [ plan asJSON at: 'waypoints' ])
		bounds: (plan ifNotNil: [ plan bounds ])
		convexHull: useHull
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> gridStep: metres [
	terrainOptions at: #gridStep put: metres
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> terrainMargin: metres [
	terrainOptions at: #margin put: metres
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> terrainSource: source [
	terrainOptions at: #source put: source asSymbol
]

{ #category : 'terrain settings' }
SoSeAtelierParameters >> geoTiff: path [
	terrainOptions at: #geoTiff put: (path ifNotNil: [
		path isString ifTrue: [ path ] ifFalse: [ path asFileReference fullName ] ])
]

{ #category : 'metric settings' }
SoSeAtelierParameters >> metricFields: fields [
	| allowed requested selected |
	allowed := #(timeStep), (SoSeAtelierOptionsPresenter metricChoices collect: #key).
	requested := fields asArray collect: #asSymbol.
	(requested allSatisfy: [ :name | allowed includes: name ])
		ifFalse: [ self error: 'Le CSV demande une métrique inconnue.' ].
	selected := OrderedCollection with: #timeStep.
	requested do: [ :key | (selected includes: key) ifFalse: [ selected add: key ] ].
	metricFields := selected asArray
]

{ #category : 'metric settings' }
SoSeAtelierParameters >> minimumFreshRatio: ratio [
	(ratio between: 0 and: 1) ifFalse: [ self error: 'Le seuil de fraîcheur doit être une fraction de 0 à 1.' ].
	minimumFreshRatio := ratio
]

{ #category : 'metric settings' }
SoSeAtelierParameters >> metricZone: corners [
	metricZone := corners ifNotNil: [ self normalizedBoundsFrom: corners ]
]

{ #category : 'geometry' }
SoSeAtelierParameters >> coordinatePairFor: point [
	(point isKindOf: Point) ifTrue: [ ^ { point x. point y } ].
	(point isKindOf: GeoPoint) ifTrue: [ ^ { point longitude. point latitude } ].
	^ point
]

{ #category : 'geometry' }
SoSeAtelierParameters >> normalizedBoundsFrom: corners [
	| lower upper extent |
	(corners isSequenceable and: [ corners size = 2 ])
		ifFalse: [ self error: 'Fourni deux coins WGS84 (sud-ouest et nord-est).' ].
	lower := self coordinatePairFor: corners first.
	upper := self coordinatePairFor: corners second.
	(lower isArray and: [ upper isArray and: [ lower size = 2 and: [ upper size = 2 ] ] ])
		ifFalse: [ self error: 'Les coins WGS84 contiennent une longitude et une latitude.' ].
	extent := lower, upper.
	SoSeAtelierMapPlan waypoints: #() bounds: extent convexHull: false.
	^ { lower copy. upper copy }
]

{ #category : 'geometry' }
SoSeAtelierParameters >> fileFor: path [
	| file |
	file := path asFileReference.
	^ file isAbsolute ifTrue: [ file ] ifFalse: [ baseDirectory resolve: file path ]
]

{ #category : 'geometry' }
SoSeAtelierParameters >> vercorsTerrain [
	^ SoSeAtelierTerrain vercorsFrom: FileLocator imageDirectory / 'rejeu-vercors'
]

{ #category : 'geometry' }
SoSeAtelierParameters >> exampleMapPlan [
	| name terrainExample |
	name := terrainOptions at: #example.
	name ifNil: [ ^ nil ].
	name = 'vercors' ifTrue: [
		^ SoSeAtelierMapPlan waypoints: (self vercorsTerrain points collect: [ :point |
			self coordinatePairFor: point ]) bounds: nil convexHull: false ].
	terrainExample := SoSeAtelierResources exampleNamed: name.
	^ SoSeAtelierMapPlan fromJSON: terrainExample
]

{ #category : 'geometry' }
SoSeAtelierParameters >> terrain [
	| directory path name plan |
	path := terrainOptions at: #directory.
	name := terrainOptions at: #example.
	(path isNil and: [ name isNil ]) ifTrue: [ ^ nil ].
	directory := path
		ifNotNil: [ self fileFor: path ]
		ifNil: [
			name = 'vercors'
				ifTrue: [ self vercorsTerrain directory ]
				ifFalse: [ SoSeAtelierResources directoryFor: name ] ].
	((directory / 'terrain.json') isFile and: [ (directory / 'mnt.csv') isFile ])
		ifFalse: [ self error: 'MNT introuvable ou incomplet dans ', directory fullName ].
	plan := mapPlan
		ifNil: [ (SoSeAtelierTerrain savedPlanIn: directory) ifNil: [ self exampleMapPlan ] ].
	plan ifNil: [ self error: 'Le MNT exige un tracé joint ou des points WGS84.' ].
	^ SoSeAtelierTerrain directory: directory points: plan geoPoints convexHull: plan convexHull bounds: plan bounds
]

{ #category : 'terrain generation' }
SoSeAtelierParameters >> prepareTerrainInto: directory [
	| plan input destination |
	plan := mapPlan ifNil: [ self exampleMapPlan ].
	plan ifNil: [ self error: 'Fournis un tracé WGS84 ou une emprise pour générer le MNT.' ].
	input := (terrainOptions at: #geoTiff) ifNotNil: [ :path | self fileFor: path ].
	destination := directory asFileReference asAbsolute.
	destination parent ensureCreateDirectory.
	(SoSeAtelierTerrain directory: destination points: plan geoPoints convexHull: plan convexHull bounds: plan bounds)
		saveNamed: destination basename into: destination parent step: (terrainOptions at: #gridStep)
		margin: (terrainOptions at: #margin) source: (terrainOptions at: #source) asString geoTiff: input.
	self terrainDirectory: destination.
	^ destination
]

{ #category : 'validation' }
SoSeAtelierParameters >> validateSimulation [
	(self at: #maxDate) ifNotNil: [ :value |
		self validateNumber: value named: #maxDate.
		value < 0 ifTrue: [ self error: 'maxDate doit être positif ou nul.' ] ].
	#(numberOfDrones ticks seedIndex) do: [ :key |
		| value |
		value := self at: key.
		(value isInteger and: [ value > 0 ]) ifFalse: [ self error: 'Entier positif requis pour ', key asString ] ].
	#(fleetWithdrawalTick fleetArrivalTick) do: [ :key |
		(self at: key) ifNotNil: [ :value |
			(value isInteger and: [ value > 0 ])
				ifFalse: [ self error: 'Tik entier positif requis pour ', key asString ] ] ].
	((self at: #fleetWithdrawalTick) notNil and: [ (self at: #numberOfDrones) < 2 ])
		ifTrue: [ self error: 'Un retrait exige au moins deux drones au départ.' ].
	fleetSchedule ifNotNil: [
		(scenario = #geometry and: [
			(self at: #fleetWithdrawalTick) isNil and: [
				(self at: #fleetArrivalTick) isNil and: [ (self at: #sensorOutages) = false ] ] ])
			ifFalse: [ self error: 'fleetSchedule requiert geometry ainsi que des réglages historiques de pannes, retrait et arrivée désactivés.' ] ].
	(self at: #seed) isInteger ifFalse: [ self error: 'La graine doit être un entier.' ].
	(#(true false) includes: (self at: #sensorOutages))
		ifFalse: [ self error: 'sensorOutages attend une valeur booléenne.' ].
	#(minSpeed nominalSpeed maxSpeed sensingRadius captureRadius tickSeconds distanceWeight bearingHalfAngle)
		do: [ :key | self validateNumber: (self at: key) named: key ].
	(self at: #revisitTargetSeconds) ifNotNil: [ :seconds |
		self validateNumber: seconds named: #revisitTargetSeconds.
		seconds > 0 ifFalse: [ self error: 'Le délai cible de revisite doit être positif.' ] ].
	((self at: #tickSeconds) > 0 and: [
		(self at: #sensingRadius) >= 0 and: [ (self at: #captureRadius) >= 0 ] ])
		ifFalse: [ self error: 'La durée du tik doit être positive et les rayons ne peuvent pas être négatifs.' ].
	((self at: #distanceWeight) between: 0 and: 10)
		ifFalse: [ self error: 'Le gain de distance doit être compris entre 0 et 10.' ].
	((self at: #bearingHalfAngle) between: 0 and: 180)
		ifFalse: [ self error: 'Le demi-angle doit être compris entre 0 et 180 degrés.' ].
	((SoSeAtelierSimulation commandChoices asDictionary includesKey: (self at: #policy)) and: [
		SoSeAtelierSimulation perceptionChoices asDictionary includesKey: (self at: #perceptionMode) ])
		ifFalse: [ self error: 'Loi de commande ou modèle de perception inconnu.' ]
]

{ #category : 'validation' }
SoSeAtelierParameters >> validateNumber: value named: key [
	(value isNumber and: [ value asFloat isFinite ])
		ifFalse: [ self error: 'Valeur numérique finie requise pour ', key asString ]
]

{ #category : 'files' }
SoSeAtelierParameters >> loadDocument: document relativeTo: directory [
	((document isKindOf: Dictionary) and: [
		(document at: 'format' ifAbsent: [ nil ]) = 'sose-atelier-parameters' and: [
			(document at: 'version' ifAbsent: [ nil ]) = 1 ] ])
		ifFalse: [ self error: 'Le fichier doit utiliser le format sose-atelier-parameters version 1.' ].
	baseDirectory := directory.
	self scenario: (document at: 'scenario' ifAbsent: [ #geometry ]).
	(document at: 'simulation' ifAbsent: [ Dictionary new ])
		keysAndValuesDo: [ :key :value | self at: key put: value ].
	(document at: 'display' ifAbsent: [ Dictionary new ])
		keysAndValuesDo: [ :key :value | self displayAt: key put: value ].
	(document at: 'playback' ifAbsent: [ Dictionary new ])
		keysAndValuesDo: [ :key :value | self playbackAt: key put: value ].
	(document at: 'terrain' ifAbsent: [ Dictionary new ]) keysAndValuesDo: [ :key :value |
		(terrainOptions includesKey: key asSymbol) ifFalse: [ self error: 'Réglage de terrain inconnu ', key ].
		terrainOptions at: key asSymbol put: (key = 'source' ifTrue: [ value asSymbol ] ifFalse: [ value ]) ].
	self terrainExample: (terrainOptions at: #example).
	self syntheticLoopLength: (terrainOptions at: #syntheticLoopLength).
	mapPlan := (document at: 'plan' ifAbsent: [ nil ]) ifNotNil: [ :plan | SoSeAtelierMapPlan fromJSON: plan ].
	self metricFields: (document at: 'metrics' ifAbsent: [ metricFields ]).
	self minimumFreshRatio: (document at: 'minimumFreshRatio' ifAbsent: [ minimumFreshRatio ]).
	self metricZone: (document at: 'metricZone' ifAbsent: [ nil ]).
	self fleetSchedule: (document at: 'fleetSchedule' ifAbsent: [ nil ]).
	publicationOptions := Dictionary new.
	(document at: 'publication' ifAbsent: [ Dictionary new ])
		keysAndValuesDo: [ :key :value | self publicationAt: key put: value ].
	self validateSimulation.
	^ self
]

{ #category : 'files' }
SoSeAtelierParameters >> writeTo: file [
	| target terrainDocument |
	target := file asFileReference asAbsolute.
	target parent ensureCreateDirectory.
	terrainDocument := terrainOptions copy.
	#(directory geoTiff) do: [ :key |
		(terrainDocument at: key) ifNotNil: [ :path |
			| reference |
			reference := self fileFor: path.
			reference = target parent
				ifTrue: [ terrainDocument at: key put: '.' ]
				ifFalse: [ target parent = baseDirectory ifFalse: [
					terrainDocument at: key put: reference fullName ] ] ] ].
	SoSeAtelierMissionFile write: ({
		'format' -> 'sose-atelier-parameters'. 'version' -> 1. 'scenario' -> scenario asString.
		'simulation' -> (self jsonDictionaryFrom: simulation).
		'display' -> (self jsonDictionaryFrom: display).
		'playback' -> (self jsonDictionaryFrom: playback).
		'terrain' -> (self jsonDictionaryFrom: terrainDocument).
		'plan' -> (mapPlan ifNotNil: [ mapPlan asJSON ]).
		'metrics' -> (metricFields collect: #asString).
		'metricZone' -> metricZone.
		'fleetSchedule' -> (fleetSchedule ifNotNil: [ fleetSchedule asJSON ]).
		'publication' -> self publicationDocument.
		'minimumFreshRatio' -> minimumFreshRatio } asDictionary) to: target.
	^ target
]

{ #category : 'files' }
SoSeAtelierParameters >> jsonDictionaryFrom: options [
	| document |
	document := Dictionary new.
	options keysAndValuesDo: [ :key :value |
		document at: key asString put: (value isSymbol
			ifTrue: [ value asString ]
			ifFalse: [
				(key = #hotspot and: [ value notNil ])
					ifTrue: [ value asArray collect: [ :point | self coordinatePairFor: point ] ]
					ifFalse: [ value ] ]) ].
	^ document
]

{ #category : 'files' }
SoSeAtelierParameters >> publicationDocument [
	| document |
	document := self jsonDictionaryFrom: self publicationSettings.
	#('policies' 'modes' 'dates') do: [ :key |
		document at: key ifPresent: [ :values | document at: key put: (values asArray collect: #asString) ] ].
	#('ticks' 'seconds' 'droneIds' 'mapDroneIds' 'footprintHeights' 'camera') do: [ :key |
		document at: key ifPresent: [ :values | document at: key put: values asArray copy ] ].
	document at: 'origin' ifPresent: [ :date |
		document at: 'origin' put: (date ifNotNil: [ date asString ]) ].
	^ document
]

{ #category : 'simulation' }
SoSeAtelierParameters >> run [
	^ self runRecordingSchedule: [ :realization | ]
]

{ #category : 'simulation' }
SoSeAtelierParameters >> runRecordingSchedule: onRealization [
	self validateSimulation.
	scenario = #legacySoSe ifTrue: [
		^ MacroSimulatorFreshnessScope value: (self at: #maxDate) during: [ FullAppMacroReplay soSe ] ].
	scenario = #legacyISSe ifTrue: [
		^ MacroSimulatorFreshnessScope value: (self at: #maxDate)
			during: [ FullAppMacroReplay isSeWithSeedIndex: (self at: #seedIndex) ] ].
	scenario = #sose ifTrue: [
		(self at: #perceptionMode) = #scenario ifFalse: [
			self error: 'Pour comparer les modèles de perception, utilise le scénario geometry.' ].
		^ (SoSeAtelierSimulation terrain: nil settings: simulation)
			runSource: (SoSeAtelierSimulation sourceFor: #sose) ].
	^ self runGeometryRecordingSchedule: onRealization
]

{ #category : 'simulation' }
SoSeAtelierParameters >> runGeometry [
	^ self runGeometryRecordingSchedule: [ :realization | ]
]

{ #category : 'simulation' }
SoSeAtelierParameters >> runGeometryRecordingSchedule: onRealization [
	| ground recipe simulator options |
	ground := self terrain.
	(ground isNil and: [ mapPlan notNil ]) ifTrue: [
		self error: 'Le tracé WGS84 requiert un MNT. Génère le terrain ou sélectionne un MNT existant.' ].
	options := simulation copy.
	(options at: #perceptionMode) = #scenario ifTrue: [ options at: #perceptionMode put: #hybrid ].
	recipe := SoSeAtelierSimulation terrain: ground settings: options.
	simulator := ground
		ifNil: [ self simulatorOnSyntheticLoopUsing: recipe ]
		ifNotNil: [ self simulatorOnTerrain: ground using: recipe ].
	simulator behavior sensibility: 0.01; pacingRate: 0.9.
	recipe configurerPerceptionDe: simulator.
	recipe configurerCommandeDe: simulator.
	(self at: #sensorOutages) ifTrue: [ self scheduleSensorOutagesOn: simulator ].
	(self at: #fleetWithdrawalTick) ifNotNil: [ :tick | simulator loose: simulator current drones first id at: tick ].
	(self at: #fleetArrivalTick) ifNotNil: [ :tick | simulator newIncomerAt: tick ].
	fleetSchedule ifNotNil: [
		onRealization value: (fleetSchedule scheduleOn: simulator through: (self at: #ticks)) ].
	simulator runSingleUpdate: (self at: #ticks).
	^ simulator
]

{ #category : 'simulation' }
SoSeAtelierParameters >> simulatorOnSyntheticLoopUsing: recipe [
	| parameters seconds |
	parameters := MacroSimulatorParameters new.
	parameters wayPoints: (self class syntheticLoopOfLength: (terrainOptions at: #syntheticLoopLength)).
	recipe configurer: parameters.
	seconds := self at: #tickSeconds.
	parameters
		minSpeed: parameters minSpeed * seconds;
		nominalSpeed: parameters nominalSpeed * seconds;
		maxSpeed: parameters maxSpeed * seconds.
	^ parameters initializeSimulator
]

{ #category : 'simulation' }
SoSeAtelierParameters >> simulatorOnTerrain: ground using: recipe [
	| replay |
	replay := ground newReplay.
	replay secondsPerTick: (self at: #tickSeconds).
	^ replay newSimulatorWith: [ :parameters |
		parameters wayPoints: replay projectedWayPoints.
		recipe configurer: parameters ]
]

{ #category : 'simulation' }
SoSeAtelierParameters >> scheduleSensorOutagesOn: simulator [
	simulator scheduleAllDistanceMeasurementAvailable: false at: 25.
	simulator scheduleVisionAvailable: false at: 45 matching: [ :drone | true ].
	simulator scheduleVisionAvailable: true at: 70 matching: [ :drone | true ].
	simulator scheduleAllDistanceMeasurementAvailable: true at: 85
]

{ #category : 'simulation' }
SoSeAtelierParameters >> effectiveTickSeconds [
	^ (#(legacySoSe legacyISSe) includes: scenario)
		ifTrue: [ 1.0 ] ifFalse: [ self at: #tickSeconds ]
]

{ #category : 'exporting' }
SoSeAtelierParameters >> exportInto: directory [
	| simulator output realization |
	simulator := self runRecordingSchedule: [ :events | realization := events ].
	output := directory asFileReference ensureCreateDirectory.
	self writeTo: output / ('parametres-', UUID new asString, '.json').
	realization ifNotNil: [ SoSeAtelierFleetSchedule writeRealization: realization into: output ].
	^ self exportMetricsOf: simulator into: output
]

{ #category : 'exporting' }
SoSeAtelierParameters >> exportMetricsOf: simulator into: directory [
	| report ground fields |
	report := (metricFields anySatisfy: [ :field | SoSeAtelierOptionsPresenter opticalFields includes: field ])
		ifFalse: [ simulator evaluateMetrics ]
		ifTrue: [
			ground := self terrain.
			ground ifNil: [ self error: 'Les métriques optiques exigent un MNT et un tracé WGS84.' ].
			SoSeAtelierLecture opticalMetricsOf: simulator terrain: ground tickSeconds: self effectiveTickSeconds
				display: display zone: (self pointsFromBounds: metricZone) minimumFreshRatio: minimumFreshRatio ].
	fields := (simulator isKindOf: MacroSimulatorWithFreshness)
		ifTrue: [ metricFields, (SoSeAtelierOptionsPresenter passageFields reject: [ :field |
			metricFields includes: field ]) ]
		ifFalse: [ metricFields ].
	^ SoSeAtelierExport metrics: report fields: fields into: directory
]

{ #category : 'exporting' }
SoSeAtelierParameters >> hotspotPoints [
	^ self pointsFromBounds: (playback at: #hotspot)
]

{ #category : 'publication' }
SoSeAtelierParameters >> publicationInto: parent [
	| publication options entries output |
	self validateSimulation.
	options := self publicationSettings copy.
	options at: #camera ifAbsentPut: [ display at: #camera ].
	options at: #lossMarkerSeconds ifAbsentPut: [ display at: #lossMarkerSeconds ].
	options at: #accelerationThreshold ifAbsentPut: [ display at: #accelerationThreshold ].
	publication := SoSeAtelierPublication new
		tickSeconds: self effectiveTickSeconds;
		terrain: self terrain;
		options: options;
		yourself.
	entries := self publicationVariants collect: [ :variant |
		| configuration simulator realization |
		configuration := variant value.
		simulator := configuration runRecordingSchedule: [ :events | realization := events ].
		publication addSimulation: simulator named: variant key.
		{ configuration. simulator. realization } ].
	output := publication writeInto: parent.
	self writeTo: output / 'parametres.json'.
	entries withIndexDo: [ :entry :index |
		| config destination |
		config := entry first.
		destination := publication runDirectoryAt: index in: output.
		config writeTo: destination / 'parametres.json'.
		config exportMetricsOf: entry second into: destination.
		entry third ifNotNil: [ :events | SoSeAtelierFleetSchedule writeRealization: events into: destination ] ].
	^ output
]

{ #category : 'publication' }
SoSeAtelierParameters >> publicationVariants [
	| policies labels |
	policies := self publicationSettings at: #policies ifAbsent: [ #() ].
	(policies isSequenceable and: [ policies isString not ])
		ifFalse: [ self error: 'policies attend une liste de lois.' ].
	labels := SoSeAtelierSimulation commandChoices asDictionary.
	policies ifEmpty: [
		^ { (({ #legacySoSe -> 'SoSe historique'. #legacyISSe -> 'ISSe historique' } asDictionary)
			at: scenario ifAbsent: [ labels at: (self at: #policy) ]) -> self } ].
	(#(legacySoSe legacyISSe) includes: scenario)
		ifTrue: [ self error: 'Les scénarios historiques conservent leur loi d’origine. Choisis geometry pour comparer les lois.' ].
	policies := policies collect: #asSymbol.
	policies asSet size = policies size ifFalse: [ self error: 'Sélectionne des lois distinctes.' ].
	^ policies collect: [ :policy |
		(labels at: policy ifAbsent: [ self error: 'Loi inconnue ', policy asString ]) ->
			(self copy policy: policy; publicationAt: #policies put: #(); yourself) ]
]

{ #category : 'exporting' }
SoSeAtelierParameters >> pointsFromBounds: corners [
	^ corners ifNotNil: [ (self normalizedBoundsFrom: corners) collect: [ :corner | corner first @ corner second ] ]
]

{ #category : 'exporting' }
SoSeAtelierParameters >> videoInto: directory [
	| ground output simulator timing lecture |
	ground := self terrain.
	ground ifNil: [ self error: 'La vidéo exige un MNT et un tracé WGS84.' ].
	simulator := self run.
	output := directory asFileReference ensureCreateDirectory.
	self writeTo: output / ('parametres-', UUID new asString, '.json').
	timing := playback copy.
	timing
		at: #interval put: ((playback at: #interval) ifNil: [ #() ] ifNotNil: [ :bounds |
			bounds first to: bounds second ]);
		at: #hotspot put: self hotspotPoints.
	lecture := SoSeAtelierLecture terrain: ground history: simulator history
		tickSeconds: self effectiveTickSeconds display: display timing: timing.
	^ SoSeAtelierExport video: lecture into: output
]

{ #category : 'comparison' }
SoSeAtelierParameters >> runComparisonInto: directory [
	| output summary rows variants |
	scenario = #geometry ifFalse: [ self error: 'La comparaison exige le scénario geometry.' ].
	output := (directory asFileReference / ('comparaison-', UUID new asString)) ensureCreateDirectory.
	variants := {
		{ 'distance'. #distance. #revisedCapingPolicy. 2.0. 180.0 }.
		{ 'gisement'. #bearing. #revisedCapingPolicy. 2.0. 180.0 }.
		{ 'hybride'. #hybrid. #revisedCapingPolicy. 2.0. 180.0 }.
		{ 'hybride-gain-reduit'. #hybrid. #revisedCapingPolicy. 0.35. 180.0 }.
		{ 'hybride-angle-reduit'. #hybrid. #revisedCapingPolicy. 2.0. 25.0 }.
		{ 'hybride-revisite'. #hybrid. #revisitCapingPolicy. 2.0. 180.0 }.
		{ 'hybride-capping'. #hybrid. #capingPolicy. 2.0. 180.0 } }.
	rows := variants collect: [ :variant | self runVariant: variant into: output ].
	summary := output / 'comparaison.csv'.
	summary writeStreamDo: [ :stream |
		| writer |
		writer := NeoCSVWriter on: stream.
		writer writeHeader: #(variant perception policy distanceWeight bearingHalfAngle targetSeconds
			lastDelaySeconds maxDelaySeconds ticksAboveTarget lastStdGapMeters lastSpeedMetersPerSecond
			directPercent bearingPercent outOfRangePercent unavailablePercent).
		writer nextPutAll: rows ].
	^ summary
]

{ #category : 'comparison' }
SoSeAtelierParameters >> runVariant: variant into: directory [
	| configuration runDirectory simulator analysis target realization |
	configuration := self copy
		perceptionMode: variant second;
		policy: variant third;
		at: #distanceWeight put: variant fourth;
		at: #bearingHalfAngle put: variant fifth;
		yourself.
	runDirectory := (directory / variant first) ensureCreateDirectory.
	configuration writeTo: runDirectory / 'parametres.json'.
	simulator := configuration runRecordingSchedule: [ :events | realization := events ].
	realization ifNotNil: [ SoSeAtelierFleetSchedule writeRealization: realization into: runDirectory ].
	configuration exportMetricsOf: simulator into: runDirectory.
	analysis := SoSeAtelierRevisitRun on: simulator metrics: simulator evaluateMetrics
		tickSeconds: self effectiveTickSeconds.
	target := self at: #revisitTargetSeconds.
	^ variant, (analysis indicatorsFor: (target ifNil: [ Float infinity ]))
]
