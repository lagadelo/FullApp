"
Transforme un historique terminé en une scène JSON pour le rejeu 3D local.
Les coordonnées sont exprimées en mètres dans un repère local x est, y haut,
z sud. Le rejeu garde le premier et le dernier état. Entre les deux, stride
détermine quels états sont conservés. Pour un historique sans polygone,
le parcours est un cercle de même périmètre que le circuit du simulateur.
"
Class {
	#name : 'SoSeAtelierRenderScene',
	#superclass : 'Object',
	#instVars : [ 'document' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierRenderScene class >> history: steps tickSeconds: seconds terrain: aTerrain heightAboveGround: height stride: stride [
	(steps isEmpty or: [ (steps first range > 0) not ])
		ifTrue: [ self error: 'Le rejeu exige un historique et un circuit de longueur positive.' ].
	(seconds isNumber and: [ seconds asFloat isFinite and: [ seconds > 0 ] ])
		ifFalse: [ self error: 'La durée d’un tik doit être positive et finie.' ].
	(height isNumber and: [ height asFloat isFinite and: [ height > 0 ] ])
		ifFalse: [ self error: 'La hauteur de vol doit être positive et finie.' ].
	(stride isInteger and: [ stride > 0 ])
		ifFalse: [ self error: 'Le pas de lecture doit être un entier positif.' ].
	^ self new initializeHistory: steps tickSeconds: seconds terrain: aTerrain
		heightAboveGround: height stride: stride
]

{ #category : 'initialization' }
SoSeAtelierRenderScene >> initializeHistory: steps tickSeconds: seconds terrain: aTerrain heightAboveGround: height stride: stride [
	| replay model route routeGeometry center altitude ground mesh indexes frames mode |
	replay := aTerrain ifNotNil: [ aTerrain newReplay ].
	model := replay ifNotNil: [ replay terrain ].
	routeGeometry := self routeWith: replay firstStep: steps first.
	route := routeGeometry first.
	center := model
		ifNil: [ (Rectangle encompassing: route) center ]
		ifNotNil: [ model projectedBounds center ].
	altitude := model ifNil: [ 0 ] ifNotNil: [ model minimumSurface ].
	ground := [ :point | model ifNil: [ 0 ] ifNotNil: [ model groundAt: point ] ].
	mesh := model ifNotNil: [ self sample: model relativeTo: center altitude: altitude ].
	indexes := (1 to: steps size by: stride) asOrderedCollection.
	indexes last = steps size ifFalse: [ indexes add: steps size ].
	frames := indexes collect: [ :index |
		| step |
		step := steps at: index.
		{ 'tick' -> step timeStep.
		  'seconds' -> (step timeStep * seconds) asFloat.
		  'drones' -> (step drones collect: [ :drone |
				| point elevation |
				point := routeGeometry second value: drone value: step.
				elevation := ground value: point.
				{ 'id' -> drone id asString.
				  'position' -> (self point: point height: (elevation ifNotNil: [ elevation + height ])
					relativeTo: center altitude: altitude) } asDictionary ] as: Array) } asDictionary ].
	mode := model ifNotNil: [ 'terrain' ] ifNil: [ routeGeometry third ].
	document := { 'format' -> 'sose-replay-3d'. 'version' -> 1. 'mode' -> mode.
		'route' -> (route collect: [ :point |
			self point: point height: (ground value: point) relativeTo: center altitude: altitude ]).
		'terrain' -> mesh. 'heightAboveGround' -> height asFloat.
		'frames' -> frames asArray } asDictionary
]

{ #category : 'geometry' }
SoSeAtelierRenderScene >> routeWith: replay firstStep: step [
	| parameters points project circle |
	replay ifNotNil: [
		^ { replay projectedWayPoints.
		    [ :drone :state | replay projectedPositionOf: drone in: state ].
		    'terrain' } ].
	parameters := step simulator ifNotNil: [ step simulator parameters ].
	points := parameters ifNotNil: [ parameters wayPoints ].
	(points notNil and: [ points size >= 3 ]) ifTrue: [
		project := [ :point |
			| local |
			local := parameters localXYOf: point relativeTo: points first.
			(parameters isGeographicPoint: point) ifTrue: [ local := local * 1000 ].
			local ].
		^ { (points collect: project as: Array).
		    [ :drone :state | project value: (state realPositionOfDrone: drone) ].
		    'planar' } ].
	circle := [ :fraction :circumference |
		| angle radius |
		angle := fraction * 2 * Float pi.
		radius := circumference / (2 * Float pi).
		(radius * angle cos) @ (radius * angle sin) ].
	^ { ((0 to: 95) collect: [ :index | circle value: index / 96 value: step range ]).
	    [ :drone :state | circle value: (drone position \\ state range) / state range value: state range ].
	    'abstract' }
]

{ #category : 'geometry' }
SoSeAtelierRenderScene >> point: point height: elevation relativeTo: center altitude: altitude [
	^ { (point x - center x) asFloat.
		(elevation ifNotNil: [ (elevation - altitude) asFloat ]).
		(center y - point y) asFloat }
]

{ #category : 'geometry' }
SoSeAtelierRenderScene >> sample: terrain relativeTo: center altitude: altitude [
	| columns rows |
	columns := self sampleIndices: terrain columns.
	rows := self sampleIndices: terrain rows.
	^ { 'x' -> (columns collect: [ :column |
			(((terrain projectedCenterAtColumn: column row: 0) x) - center x) asFloat ]).
	    'z' -> (rows collect: [ :row |
			(center y - (terrain projectedCenterAtColumn: 0 row: row) y) asFloat ]).
	    'heights' -> (rows collect: [ :row |
			columns collect: [ :column |
				(terrain surfaceAtColumn: column row: row) ifNotNil: [ :z | (z - altitude) asFloat ] ] ]) } asDictionary
]

{ #category : 'geometry' }
SoSeAtelierRenderScene >> sampleIndices: count [
	| samples |
	samples := count min: 76.
	samples = 1 ifTrue: [ ^ #(0) ].
	^ (0 to: samples - 1) collect: [ :index | (index * (count - 1) / (samples - 1)) rounded ]
]

{ #category : 'export' }
SoSeAtelierRenderScene >> asJSON [
	^ STONJSON toString: document
]

{ #category : 'export' }
SoSeAtelierRenderScene >> writeTo: aFile [
	| file |
	file := aFile asFileReference.
	file writeStreamDo: [ :stream | stream nextPutAll: self asJSON ].
	^ file
]
