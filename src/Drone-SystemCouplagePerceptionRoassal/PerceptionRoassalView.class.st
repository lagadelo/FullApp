Class {
	#name : 'PerceptionRoassalView',
	#superclass : 'Object',
	#instVars : [
		'adapter',
		'canvas',
		'background',
		'backgroundTerrain',
		'mapOrigin',
		'mapScale',
		'colors'
	],
	#category : 'Drone-SystemCouplagePerceptionRoassal',
	#package : 'Drone-SystemCouplagePerceptionRoassal'
}

{ #category : 'instance creation' }
PerceptionRoassalView class >> on: adapter [

	^ self new initializeOn: adapter
]

{ #category : 'drawing' }
PerceptionRoassalView >> addFixed: shape [

	shape setAsFixed.
	canvas add: shape
]

{ #category : 'configuration' }
PerceptionRoassalView >> asForm [

	self refresh.
	^ canvas asForm
]

{ #category : 'configuration' }
PerceptionRoassalView >> canvas [

	^ canvas
]

{ #category : 'drawing' }
PerceptionRoassalView >> drawBitmap: form extent: dimensions [

	| shape |
	shape := RSBitmap new
		         form: form;
		         extent: dimensions;
		         yourself.
	shape translateTo: mapOrigin + (dimensions / 2).
	self addFixed: shape
]

{ #category : 'drawing' }
PerceptionRoassalView >> drawDrones [

	adapter poses do: [ :pose |
			| point shape |
			(adapter terrain includesProjectedPoint: pose position) ifTrue: [
					point := self screenPoint: pose position.
					shape := RSEllipse new
						         size: 9;
						         color: Color white;
						         yourself.
					shape translateTo: point.
					self addFixed: shape.
					self
						label: pose id asString
						at: point + (6 @ -17)
						size: 12
						color: Color white ] ]
]

{ #category : 'drawing' }
PerceptionRoassalView >> drawLegend [

	| title y labels muted |
	muted := Color fromHexString: 'C0CEE0'.
	title := adapter time
		         ifNil: [ 'En attente du premier pas' ]
		         ifNotNil: [ :seconds |
				         'Temps simulé  '
				         ,
				         ((seconds printShowingDecimalPlaces: 2)
					          copyReplaceAll: '.'
					          with: ',') , ' s' ].
	self
		label: title
		at: 16 @ 10
		size: 18
		color: Color white.
	(adapter polygonIncludedInTerrain not or: [
		 adapter footprintMayBeClipped ]) ifTrue: [
			self
				label: 'Bord du modèle de terrain'
				at: canvas extent x - 211 @ 14
				size: 13
				color: (Color fromHexString: 'F5DD86') ].
	y := canvas extent y - 49.
	self
		label: 'Finesse (m/px)'
		at: 16 @ y
		size: 13
		color: muted.
	labels := #( '≤ 0,15' '≤ 0,30' '≤ 0,45' '≤ 0,65' '> 0,65' ).
	labels doWithIndex: [ :text :index |
			self
				label: text
				at: 139 + (index - 1 * 63) @ y
				size: 13
				color: (colors at: index) ].
	self
		label:
		'Blanc après ' , adapter fadeSeconds printString , ' s sans passage'
		at: 16 @ (y + 21)
		size: 13
		color: muted
]

{ #category : 'drawing' }
PerceptionRoassalView >> drawPolygon [

	| vertices color |
	vertices := adapter polygon.
	color := Color fromHexString: 'F5DD86'.
	1 to: vertices size do: [ :i |
			| shape |
			shape := RSLine new
				         startPoint: (self screenPoint: (vertices at: i));
				         endPoint:
					         (self screenPoint: (vertices at: i \\ vertices size + 1));
				         color: color;
				         width: 1.6;
				         dashArray: #( 6 4 );
				         yourself.
			self addFixed: shape ]
]

{ #category : 'configuration' }
PerceptionRoassalView >> initializeOn: aPerceptionAdapter [

	adapter := aPerceptionAdapter.
	canvas := RSCanvas new
		          extent: 860 @ 660;
		          color: (Color fromHexString: '101B29');
		          yourself.
	colors := #( 'F7DF79' '71E3AF' '5DD0EB' '6E9CFF' 'BEA9FF' ) collect: [
		          :hex | Color fromHexString: hex ]
]

{ #category : 'drawing' }
PerceptionRoassalView >> label: text at: point size: size color: color [

	| label |
	label := RSLabel new
		         text: text;
		         fontSize: size;
		         color: color;
		         yourself.
	label translateTo: point + (label extent / 2).
	self addFixed: label
]

{ #category : 'configuration' }
PerceptionRoassalView >> open [

	self refresh.
	^ canvas open
]

{ #category : 'drawing' }
PerceptionRoassalView >> overlayFor: terrain [

	| overlay white limits |
	overlay := Form extent: terrain columns @ terrain rows depth: 32.
	white := Color fromHexString: 'F8FBFF'.
	limits := #( 0.15 0.30 0.45 0.65 ).
	adapter visibleGridObservationsDo: [ :cell :reading |
			| shade grade |
			grade := limits findFirst: [ :limit | reading second <= limit ].
			shade := (colors at: (grade = 0
					           ifTrue: [ 5 ]
					           ifFalse: [ grade ]))
				         mixed: 1 - (adapter whitenessOf: reading)
				         with: white.
			overlay colorAt: cell put: (shade alpha: 0.74) ].
	^ overlay
]

{ #category : 'drawing' }
PerceptionRoassalView >> refresh [

	| terrain available mapExtent |
	terrain := adapter terrain.
	available := canvas extent - (36 @ 100).
	(available x <= 0 or: [ available y <= 0 ]) ifTrue: [ ^ self ].
	mapScale := available x / (terrain columns * terrain cellSize x)
		            min: available y / (terrain rows * terrain cellSize y).
	mapExtent := terrain columns * terrain cellSize x
	             @ (terrain rows * terrain cellSize y) * mapScale.
	mapOrigin := canvas extent x - mapExtent x / 2 @ 44.
	canvas fixedShapes copy do: #remove.
	self drawBitmap: (self reliefFor: terrain) extent: mapExtent.
	self drawBitmap: (self overlayFor: terrain) extent: mapExtent.
	self drawPolygon.
	self drawDrones.
	self drawLegend.
	canvas signalUpdate
]

{ #category : 'drawing' }
PerceptionRoassalView >> reliefFor: terrain [

	| low high bright dark invalid |
	backgroundTerrain == terrain ifTrue: [ ^ background ].
	low := terrain minimumSurface.
	high := terrain maximumSurface max: low + 20.
	bright := Color fromHexString: '65788B'.
	dark := Color fromHexString: '263B50'.
	invalid := Color fromHexString: '0B141F'.
	background := Form extent: terrain columns @ terrain rows depth: 32.
	0 to: terrain rows - 1 do: [ :row |
			0 to: terrain columns - 1 do: [ :column |
					| z fraction shade |
					z := terrain surfaceAtColumn: column row: row.
					shade := z ifNil: [ invalid ] ifNotNil: [
							         fraction := z - low / (high - low).
							         bright mixed: fraction with: dark ].
					background colorAt: column @ row put: shade ] ].
	backgroundTerrain := terrain.
	^ background
]

{ #category : 'drawing' }
PerceptionRoassalView >> screenPoint: projectedPoint [

	| grid spacing |
	grid := adapter terrain gridCoordinatesOf: projectedPoint.
	spacing := adapter terrain cellSize.
	^ mapOrigin + (grid x * spacing x @ (grid y * spacing y) * mapScale)
]
