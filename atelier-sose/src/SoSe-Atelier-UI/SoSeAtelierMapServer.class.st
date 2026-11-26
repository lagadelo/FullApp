"
Dessert l’éditeur cartographique sur la boucle locale. Le navigateur échange
un tracé WGS84 avec Pharo. Chaque ouverture a une adresse de session propre.
"
Class {
	#name : 'SoSeAtelierMapServer',
	#superclass : 'Object',
	#instVars : [ 'server', 'token', 'currentPlan', 'currentExample', 'examples', 'onApply',
		'onSaveTerrain', 'terrainOptions', 'saveLock', 'saveStatus' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'initialization' }
SoSeAtelierMapServer >> initialize [
	super initialize.
	saveLock := Semaphore forMutualExclusion
]

{ #category : 'running' }
SoSeAtelierMapServer >> startWith: plan example: identifier onApply: action [
	| deadline |
	(SoSeAtelierResources directory / 'cartographie' / 'index.html') isFile
		ifFalse: [ self error: 'Indique le dossier de livraison avec SoSeAtelierResources directory:.' ].
	self stop.
	currentPlan := plan.
	currentExample := identifier.
	examples := SoSeAtelierResources examples.
	onApply := action.
	saveLock critical: [ saveStatus := nil ].
	token := UUID new asString.
	server := ZnServer on: 0.
	server bindingAddress: #[127 0 0 1]; delegate: self; start.
	deadline := DateAndTime now + 2 seconds.
	[ server isListening not and: [ DateAndTime now < deadline ] ] whileTrue: [
		(Delay forMilliseconds: 20) wait ].
	server isListening ifFalse: [ self stop. self error: 'Le serveur local de la carte ne démarre pas.' ].
	^ 'http://127.0.0.1:', server port printString, '/', token, '/'
]

{ #category : 'configuration' }
SoSeAtelierMapServer >> onSaveTerrain: action options: options [
	onSaveTerrain := action.
	terrainOptions := options
]

{ #category : 'running' }
SoSeAtelierMapServer >> stop [
	server ifNotNil: [ server stop. server := nil ]
]

{ #category : 'http' }
SoSeAtelierMapServer >> handleRequest: request [
	| parts path |
	parts := request uri pathSegments.
	(parts isEmpty or: [ parts first ~= token ]) ifTrue: [ ^ ZnResponse notFound: request uri ].
	path := '/' join: (parts allButFirst reject: [ :segment | segment = $/ ]).
	path = 'etat' ifTrue: [
		request method = #GET ifTrue: [ ^ self json: self state ].
		request method = #POST ifTrue: [ ^ self apply: request ] ].
	(path = 'terrain' and: [ onSaveTerrain notNil ]) ifTrue: [
		request method = #GET ifTrue: [ ^ self json: self terrainStatus ].
		request method = #POST ifTrue: [ ^ self saveTerrain: request ] ].
	request method = #GET ifTrue: [ ^ self serve: path ifEmptyIndexFor: request ].
	^ ZnResponse notFound: request uri
]

{ #category : 'http' }
SoSeAtelierMapServer >> state [
	^ { 'plan' -> currentPlan asJSON. 'example' -> currentExample. 'examples' -> examples.
		'terrainOptions' -> terrainOptions. 'basemaps' -> SoSeAtelierBasemap sources } asDictionary
]

{ #category : 'http' }
SoSeAtelierMapServer >> json: dictionary [
	^ ZnResponse ok: (ZnEntity json: (STONJSON toString: dictionary))
]

{ #category : 'http' }
SoSeAtelierMapServer >> apply: request [
	[ | payload plan identifier |
		(self terrainStatus at: 'state') = 'pending' ifTrue: [
			self error: 'Attends la fin de l’enregistrement du terrain.' ].
		payload := STONJSON fromString: request entity contents.
		plan := SoSeAtelierMapPlan fromJSON: (payload at: 'plan').
		identifier := self exampleIn: payload.
		onApply value: plan value: identifier.
		currentPlan := plan.
		currentExample := identifier.
		^ self json: { 'ok' -> true } asDictionary ]
		on: Error do: [ :error | ^ self failureFor: request message: error messageText ]
]

{ #category : 'http' }
SoSeAtelierMapServer >> exampleIn: payload [
	| identifier |
	identifier := payload at: 'example' ifAbsent: [ nil ].
	(identifier notNil and: [ examples noneSatisfy: [ :site | (site at: 'id') = identifier ] ])
		ifTrue: [ self error: 'Exemple de terrain inconnu.' ].
	^ identifier
]

{ #category : 'http' }
SoSeAtelierMapServer >> failureFor: request message: message [
	^ ZnResponse badRequest: request entity:
		(ZnEntity json: (STONJSON toString: { 'message' -> message } asDictionary))
]

{ #category : 'terrain files' }
SoSeAtelierMapServer >> terrainStatus [
	^ saveLock critical: [ saveStatus ifNil: [ { 'state' -> 'idle' } asDictionary ] ]
]

{ #category : 'terrain files' }
SoSeAtelierMapServer >> saveTerrain: request [
	[ | payload plan name step margin source snapshot identifier job report |
		payload := STONJSON fromString: request entity contents.
		plan := SoSeAtelierMapPlan fromJSON: (payload at: 'plan').
		name := SoSeAtelierTerrain validatedName: (payload at: 'name').
		step := payload at: 'step'.
		margin := payload at: 'margin'.
		source := payload at: 'source'.
		identifier := self exampleIn: payload.
		(step isNumber and: [ step between: 0.1 and: 10000 ]) ifFalse: [ self error: 'Indique une maille positive en mètres.' ].
		(margin isNumber and: [ margin between: 0 and: 100000 ]) ifFalse: [ self error: 'Indique une marge positive ou nulle en mètres.' ].
		(#('copernicus' 'ign' 'usgs' 'geotiff' 'example') includes: source)
			ifFalse: [ self error: 'Choisis une source d’altitude.' ].
		(source = 'example' and: [ identifier isNil ]) ifTrue: [ self error: 'Sélectionne un exemple pour utiliser son GeoTIFF.' ].
		snapshot := SoSeAtelierTerrain directory: SoSeAtelierResources directory points: plan geoPoints
			convexHull: plan convexHull bounds: plan bounds.
		snapshot generationBounds.
		job := UUID new asString.
		saveLock critical: [
			(saveStatus notNil and: [ (saveStatus at: 'state') = 'pending' ])
				ifTrue: [ self error: 'Un terrain est déjà en cours d’enregistrement.' ].
			saveStatus := self terrainStatusFor: job state: 'pending' message: 'Choisis le dossier de destination dans Pharo.' ].
		report := [ :state :message | saveLock critical: [
			(saveStatus notNil and: [ (saveStatus at: 'id') = job ]) ifTrue: [
				state = 'saved' ifTrue: [
					currentPlan := plan.
					currentExample := nil.
					terrainOptions at: 'step' put: step; at: 'margin' put: margin ].
				saveStatus := self terrainStatusFor: job state: state message: message ] ] ].
		[ onSaveTerrain value: ({ #terrain -> snapshot. #name -> name. #step -> step. #margin -> margin.
			#source -> source. #example -> identifier } asDictionary) value: report ]
			on: Error do: [ :error | report value: 'error' value: error messageText ].
		^ self json: self terrainStatus ]
		on: Error do: [ :error | ^ self failureFor: request message: error messageText ]
]

{ #category : 'terrain files' }
SoSeAtelierMapServer >> terrainStatusFor: job state: state message: message [
	^ { 'id' -> job. 'state' -> state. 'message' -> message } asDictionary
]

{ #category : 'http' }
SoSeAtelierMapServer >> serve: path ifEmptyIndexFor: request [
	| assets named type file |
	named := path ifEmpty: [ 'index.html' ].
	assets := {
		'index.html' -> 'text/html; charset=utf-8'. 'carte.js' -> 'text/javascript; charset=utf-8'.
		'carte.css' -> 'text/css; charset=utf-8'. 'leaflet/leaflet.js' -> 'text/javascript'.
		'leaflet/leaflet.css' -> 'text/css'. 'leaflet/images/layers.png' -> 'image/png'.
		'leaflet/images/layers-2x.png' -> 'image/png' } asDictionary.
	type := assets at: named ifAbsent: [ nil ].
	type ifNotNil: [ file := SoSeAtelierResources directory / 'cartographie' / named ].
	examples do: [ :example |
		| id |
		id := example at: 'id'.
		named = ('relief/', id) ifTrue: [
			file := (SoSeAtelierResources directoryFor: id) / 'relief-carte.png'.
			type := 'image/png' ] ].
	(file isNil or: [ file isFile not ]) ifTrue: [ ^ ZnResponse notFound: request uri ].
	^ ZnResponse ok: ((ZnEntity bytes: (file binaryReadStreamDo: [ :stream | stream contents ]))
		contentType: type asZnMimeType; yourself)
]
