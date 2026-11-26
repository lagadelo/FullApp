"
Un terrain local et ses sommets WGS84. Le parcours peut garder l'ordre de
saisie ou prendre l'enveloppe convexe. L'emprise du MNT couvre tous les sommets.
"
Class {
	#name : 'SoSeAtelierTerrain',
	#superclass : 'Object',
	#instVars : [ 'directory', 'points', 'convexHull', 'bounds' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierTerrain class >> directory: aDirectory points: geodesicPoints convexHull: useHull [
	^ self directory: aDirectory points: geodesicPoints convexHull: useHull bounds: nil
]

{ #category : 'instance creation' }
SoSeAtelierTerrain class >> directory: aDirectory points: geodesicPoints convexHull: useHull bounds: extent [
	^ self new initializeDirectory: aDirectory points: geodesicPoints convexHull: useHull bounds: extent
]

{ #category : 'instance creation' }
SoSeAtelierTerrain class >> vercorsFrom: bundle [
	| geometry points |
	geometry := STONJSON fromString: (bundle / 'parcours-vercors.geojson') contents.
	points := (geometry at: 'coordinates') first allButLast collect: [ :pair |
		GeoPoint latitude: pair second longitude: pair first altitude: 0 ].
	^ self directory: bundle / 'terrain-vercors' points: points convexHull: false
]

{ #category : 'terrain files' }
SoSeAtelierTerrain class >> validatedName: name [
	| trimmed |
	name isString ifFalse: [ self error: 'Indique un nom pour le dossier du terrain.' ].
	trimmed := name trimBoth.
	(trimmed isEmpty or: [ trimmed first = $. or: [
		trimmed anySatisfy: [ :character | ('/\:' includes: character) or: [ character codePoint < 32 ] ] ] ])
		ifTrue: [ self error: 'Indique un nom de dossier simple, par exemple Côte de Crozon.' ].
	^ trimmed
]

{ #category : 'terrain files' }
SoSeAtelierTerrain class >> savedPlanIn: directory [
	| file document |
	file := directory asFileReference / 'trace-sose.json'.
	file isFile ifFalse: [ ^ nil ].
	document := STONJSON fromString: file contents.
	((document at: 'format') = 'sose-trace' and: [ (document at: 'version') = 1 ])
		ifFalse: [ self error: 'Le format du tracé joint au MNT est inconnu.' ].
	^ SoSeAtelierMapPlan fromJSON: (document at: 'plan')
]

{ #category : 'mapping' }
SoSeAtelierTerrain class >> gridOf: metadata [
	^ (#('crs' 'topLeft' 'cellSize' 'columns' 'rows') collect: [ :key | key -> (metadata at: key) copy ]) asDictionary
]

{ #category : 'system' }
SoSeAtelierTerrain class >> runGeographicTool: arguments in: directory [
	| errorLog command |
	errorLog := directory / 'outil-erreur.txt'.
	command := '/usr/bin/env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR GDAL_HTTP_TIMEOUT=30 PATH=/opt/homebrew/bin:/usr/local/bin:"$PATH" ',
		(' ' join: (arguments collect: [ :argument | SoSeAtelierExport quote: argument asString ])),
		' 2> ', (SoSeAtelierExport quote: errorLog fullName).
	(LibC system: command) = 0 ifFalse: [
		self error: arguments first, ' a échoué. ', (errorLog contents trimBoth truncateTo: 500) ]
]

{ #category : 'initialization' }
SoSeAtelierTerrain >> initializeDirectory: aDirectory points: vertices convexHull: useHull bounds: extent [
	directory := aDirectory asFileReference.
	points := vertices asArray copy.
	convexHull := useHull.
	bounds := extent ifNotNil: [ extent copy ]
]

{ #category : 'accessing' }
SoSeAtelierTerrain >> directory [
	^ directory
]

{ #category : 'accessing' }
SoSeAtelierTerrain >> points [
	^ points copy
]

{ #category : 'accessing' }
SoSeAtelierTerrain >> metadata [
	| file metadata |
	file := directory / 'terrain.json'.
	file isFile ifFalse: [ self error: 'Choisis un dossier qui contient terrain.json et mnt.csv.' ].
	metadata := STONJSON fromString: file contents.
	(metadata at: 'inputCrs' ifAbsent: [ 'EPSG:4326' ]) = 'EPSG:4326'
		ifFalse: [ self error: 'Les points GeoPoint exigent un terrain dont le repère d’entrée est EPSG:4326.' ].
	^ metadata
]

{ #category : 'accessing' }
SoSeAtelierTerrain >> cellSize [
	^ self metadata at: 'cellSize'
]

{ #category : 'mapping' }
SoSeAtelierTerrain >> mapOverlay [
	| metadata description file image |
	metadata := self metadata.
	description := metadata at: 'cartography' ifAbsent: [ ^ nil ].
	file := directory / (description at: 'overlay').
	file isFile ifFalse: [ ^ nil ].
	(description at: 'grid') = (self class gridOf: metadata)
		ifFalse: [ self error: 'Le fond cartographique doit utiliser la même grille que le MNT.' ].
	image := PNGReadWriter formFromFileNamed: file.
	image extent = ((metadata at: 'columns') @ (metadata at: 'rows'))
		ifFalse: [ self error: 'Le fond cartographique doit utiliser la même grille que le MNT.' ].
	^ image -> (description at: 'credit')
]

{ #category : 'accessing' }
SoSeAtelierTerrain >> routePoints [
	| vertices |
	vertices := points collect: [ :point | point longitude @ point latitude ].
	vertices asSet size >= 3 ifFalse: [ self error: 'Le parcours exige trois sommets distincts.' ].
	^ convexHull
		ifTrue: [ ConvexHullCalculator new hullForPoints: vertices ]
		ifFalse: [ vertices ]
]

{ #category : 'mapping' }
SoSeAtelierTerrain >> newReplay [
	| route transform extent |
	route := self routePoints.
	transform := PerceptionCoordinateTransform forMetadata: self metadata.
	extent := self projectedBounds.
	(route allSatisfy: [ :point | extent containsPoint: (transform value: point) ])
		ifFalse: [ self error: 'Le parcours sort du MNT chargé. Ouvre ou génère le MNT de cette zone.' ].
	^ PerceptionMacroReplay fromTerrain: directory wayPoints: route
]

{ #category : 'mapping' }
SoSeAtelierTerrain >> projectedBoundsFrom: southWest to: northEast [
	| project corners |
	(southWest x < northEast x and: [ southWest y < northEast y ])
		ifFalse: [ self error: 'La zone doit avoir une longitude ouest < est et une latitude sud < nord.' ].
	project := PerceptionCoordinateTransform forMetadata: self metadata.
	corners := { southWest. southWest x @ northEast y.
		northEast. northEast x @ southWest y } collect: [ :point | project value: point ].
	^ ((corners collect: #x) min @ (corners collect: #y) min)
		corner: ((corners collect: #x) max @ (corners collect: #y) max)
]

{ #category : 'generation' }
SoSeAtelierTerrain >> footprint [
	^ self footprintFrom: self generationBounds
]

{ #category : 'generation' }
SoSeAtelierTerrain >> generationBounds [
	| longitudes latitudes west east south north |
	bounds ifNotNil: [
		(points allSatisfy: [ :point |
			(point longitude between: bounds first and: bounds third)
				and: [ point latitude between: bounds second and: bounds fourth ] ])
			ifFalse: [ self error: 'Élargis l’emprise cartographique pour inclure tous les points de passage.' ].
		^ bounds copy ].
	points size >= 3 ifFalse: [ self error: 'Ajoute au moins trois points avant de générer le MNT.' ].
	longitudes := points collect: #longitude.
	latitudes := points collect: #latitude.
	west := longitudes min.
	east := longitudes max.
	south := latitudes min.
	north := latitudes max.
	(west < east and: [ south < north ])
		ifFalse: [ self error: 'L’emprise doit avoir une surface positive.' ].
	^ { west. south. east. north }
]

{ #category : 'generation' }
SoSeAtelierTerrain >> footprintFrom: extent [
	| west south east north |
	west := extent first. south := extent second. east := extent third. north := extent fourth.
	^ { 'type' -> 'Polygon'.
		'coordinates' -> { { { west. south }. { east. south }. { east. north }.
			{ west. north }. { west. south } } } } asDictionary
]

{ #category : 'generation' }
SoSeAtelierTerrain >> generateIn: parent step: metres margin: margin source: source geoTiff: aFileOrNil [
	| destination |
	destination := (parent asFileReference / ('terrain-', UUID new asString)) ensureCreateDirectory.
	^ self prepareIn: destination step: metres margin: margin source: source geoTiff: aFileOrNil
]

{ #category : 'generation' }
SoSeAtelierTerrain >> prepareIn: destination step: metres margin: margin source: source geoTiff: aFileOrNil [
	| extent footprint options output |
	extent := self generationBounds.
	(metres isNumber and: [ metres asFloat isFinite and: [ metres > 0 ] ])
		ifFalse: [ self error: 'Le maillage doit être strictement positif.' ].
	(margin isNumber and: [ margin asFloat isFinite and: [ margin >= 0 ] ])
		ifFalse: [ self error: 'La marge doit être positive ou nulle.' ].
	aFileOrNil ifNotNil: [
		aFileOrNil asFileReference isFile ifFalse: [ self error: 'Le GeoTIFF est introuvable.' ] ].
	footprint := destination / 'emprise.geojson'.
	footprint writeStreamDo: [ :stream | stream nextPutAll: (STONJSON toString: (self footprintFrom: extent)) ].
	options := { #pas -> metres. #marge -> margin. #source -> source } asDictionary.
	aFileOrNil ifNotNil: [ options at: #mnt put: aFileOrNil asFileReference ].
	(source = 'copernicus' and: [ aFileOrNil isNil ]) ifTrue: [
		^ self prepareCopernicusIn: destination footprint: footprint extent: extent options: options ].
	output := PreparerTerrain polygone: footprint sortie: destination / 'mnt' options: options.
	source = 'example' ifTrue: [ self carryExampleSourceFrom: aFileOrNil asFileReference parent into: output ].
	^ output
]

{ #category : 'generation' }
SoSeAtelierTerrain >> prepareCopernicusIn: destination footprint: footprint extent: extent options: options [
	| temporary copernicus padding output |
	temporary := (destination / 'copernicus') ensureCreateDirectory.
	[ copernicus := SoSeAtelierCopernicusSource new.
		padding := (options at: #marge) + (2 * (options at: #pas)).
		options at: #mnt put: (copernicus mosaicFor: extent padding: padding into: temporary).
		output := PreparerTerrain polygone: footprint sortie: destination / 'mnt' options: options.
		copernicus recordSourceIn: output ] ensure: [ temporary ensureDeleteAll ].
	^ output
]

{ #category : 'generation' }
SoSeAtelierTerrain >> carryExampleSourceFrom: source into: output [
	| original file metadata |
	original := STONJSON fromString: (source / 'terrain.json') contents.
	file := output / 'terrain.json'.
	metadata := STONJSON fromString: file contents.
	#('source' 'sourceUrl' 'sourceTiles' 'attribution') do: [ :key |
		original at: key ifPresent: [ :value | metadata at: key put: value ] ].
	self carryMapOverlayFrom: source metadata: original into: output metadata: metadata.
	file writeStreamDo: [ :stream | stream truncate; nextPutAll: (STONJSON toStringPretty: metadata) ]
]

{ #category : 'generation' }
SoSeAtelierTerrain >> carryMapOverlayFrom: source metadata: original into: output metadata: metadata [
	| description overlay grid originalExtent targetExtent temp sourceRaster targetRaster |
	description := original at: 'cartography' ifAbsent: [ ^ self ].
	overlay := source / (description at: 'overlay').
	overlay isFile ifFalse: [ ^ self ].
	(description at: 'grid') = (self class gridOf: original)
		ifFalse: [ self error: 'La grille du fond cartographique source diffère de celle du GeoTIFF.' ].
	grid := self class gridOf: metadata.
	originalExtent := self projectedBoundsFor: (description at: 'grid').
	targetExtent := self projectedBoundsFor: grid.
	temp := (output / '.cartographie') ensureCreateDirectory.
	[ sourceRaster := temp / 'source.vrt'.
		targetRaster := temp / 'cible.vrt'.
		self class runGeographicTool: { 'gdal_translate'. '-q'. '-of'. 'VRT'. '-a_srs'. (original at: 'crs').
			'-a_ullr'. originalExtent left. originalExtent bottom. originalExtent right. originalExtent top.
			overlay fullName. sourceRaster fullName } in: temp.
		self class runGeographicTool: { 'gdalwarp'. '-q'. '-of'. 'VRT'. '-r'. 'near'. '-srcalpha'. '-dstalpha'.
			'-t_srs'. (metadata at: 'crs'). '-te'. targetExtent left. targetExtent top. targetExtent right. targetExtent bottom.
			'-ts'. (metadata at: 'columns'). (metadata at: 'rows'). sourceRaster fullName. targetRaster fullName } in: temp.
		self class runGeographicTool: { 'gdal_translate'. '-q'. '-of'. 'PNG'. targetRaster fullName.
			(output / overlay basename) fullName } in: temp ] ensure: [ temp ensureDeleteAll ].
	metadata at: 'cartography' put: (description copy at: 'grid' put: grid; yourself)
]

{ #category : 'terrain files' }
SoSeAtelierTerrain >> saveNamed: name into: parent step: metres margin: margin source: source geoTiff: aFileOrNil [
	| target staging output trace |
	target := parent asFileReference asAbsolute / (self class validatedName: name).
	target exists ifTrue: [ self error: 'Ce dossier de terrain existe déjà. Choisis un autre nom.' ].
	staging := (target parent / ('.terrain-', UUID new asString)) ensureCreateDirectory.
	[ output := self prepareIn: staging step: metres margin: margin source: source geoTiff: aFileOrNil.
		(staging / 'emprise.geojson') moveTo: output / 'emprise.geojson'.
		trace := { 'format' -> 'sose-trace'. 'version' -> 1. 'example' -> nil.
			'plan' -> (SoSeAtelierMapPlan waypoints: (points collect: [ :point | { point longitude. point latitude } ])
				bounds: self generationBounds convexHull: convexHull) asJSON } asDictionary.
		(output / 'trace-sose.json') writeStreamDo: [ :stream | stream nextPutAll: (STONJSON toStringPretty: trace) ].
		output fileSystem rename: output path to: target path ] ensure: [ staging ensureDeleteAll ].
	^ target
]

{ #category : 'mapping' }
SoSeAtelierTerrain >> projectedBounds [
	^ self projectedBoundsFor: self metadata
]

{ #category : 'mapping' }
SoSeAtelierTerrain >> projectedBoundsFor: metadata [
	| topLeft cellSize width height |
	topLeft := metadata at: 'topLeft'.
	cellSize := metadata at: 'cellSize'.
	width := (metadata at: 'columns') * cellSize first.
	height := (metadata at: 'rows') * cellSize second.
	^ (topLeft first @ (topLeft second - height))
		corner: ((topLeft first + width) @ topLeft second)
]
