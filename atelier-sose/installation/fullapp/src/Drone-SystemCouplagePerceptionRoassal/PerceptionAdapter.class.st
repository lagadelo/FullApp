Class {
	#name : 'PerceptionAdapter',
	#superclass : 'Object',
	#instVars : [
		'terrain',
		'referenceTerrain',
		'gridOffset',
		'projection',
		'fadeSeconds',
		'sensorPixels',
		'halfField',
		'time',
		'polygon',
		'poses',
		'observations',
		'intervalOverlaps',
		'omissions',
		'footprintClipped'
	],
	#category : 'Drone-SystemCouplagePerceptionRoassal',
	#package : 'Drone-SystemCouplagePerceptionRoassal'
}

{ #category : 'instance creation' }
PerceptionAdapter class >> fromDirectory: aDirectory [

	| directory metadata |
	directory := aDirectory asFileReference.
	metadata := STONJSON fromString:
		            (directory / 'terrain.json') contents.
	^ self
		  on:
		  (PerceptionTerrain fromDirectory: directory metadata: metadata)
		  projection: (PerceptionCoordinateTransform forMetadata: metadata)
]

{ #category : 'instance creation' }
PerceptionAdapter class >> on: terrain [

	^ self on: terrain projection: [ :point | point ]
]

{ #category : 'instance creation' }
PerceptionAdapter class >> on: terrain projection: transform [

	^ self new initializeOn: terrain projection: transform
]

{ #category : 'setup' }
PerceptionAdapter >> cameraHalfFieldTangent: tangent sensorSidePixels: pixels [

	(tangent > 0 and: [
		 tangent asFloat isFinite and: [
			 pixels isInteger and: [ pixels > 0 ] ] ]) ifFalse: [
		self error: 'Paramètres de caméra invalides.' ].
	halfField := tangent asFloat.
	sensorPixels := pixels
]

{ #category : 'setup' }
PerceptionAdapter >> fadeAfterSeconds: seconds [

	(seconds > 0 and: [ seconds asFloat isFinite ]) ifFalse: [
		self error: 'Durée de fraîcheur invalide.' ].
	fadeSeconds := seconds
]

{ #category : 'query' }
PerceptionAdapter >> fadeSeconds [

	^ fadeSeconds
]

{ #category : 'query' }
PerceptionAdapter >> footprintMayBeClipped [

	^ footprintClipped
]

{ #category : 'setup' }
PerceptionAdapter >> initializeOn: aTerrain projection: transform [

	referenceTerrain := aTerrain.
	projection := transform.
	observations := Dictionary new.
	polygon := #(  ).
	poses := #(  ).
	omissions := Dictionary new.
	intervalOverlaps := 0.
	footprintClipped := false.
	fadeSeconds := 300.
	halfField := 2.5.
	sensorPixels := 2000.
	self replaceTerrain: aTerrain
]

{ #category : 'query' }
PerceptionAdapter >> observationAt: localPoint [
	"Answer { simulated time. metres per pixel. drone id }, or nil."

	| cell answer |
	cell := referenceTerrain gridCoordinatesOf:
		        (self projectPoint: localPoint).
	answer := observations
		          at: cell x floor @ cell y floor
		          ifAbsent: [ nil ].
	^ answer ifNotNil: [ answer copy ]
]

{ #category : 'simulation' }
PerceptionAdapter >> observePose: pose do: receiver [

	| point cameraGrid elevation groundZ surfaceZ radius spacing lower upper clipped |
	point := pose position.
	cameraGrid := terrain gridCoordinatesOf: point.
	(terrain includesGrid: cameraGrid) ifFalse: [ ^ #horsTerrain ].
	elevation := pose altitude.
	pose usesHeightAboveGround ifTrue: [
			groundZ := terrain groundAt: point.
			groundZ ifNil: [ ^ #solInconnu ].
			elevation := elevation + groundZ ].
	surfaceZ := terrain
		            surfaceAtColumn: cameraGrid x floor
		            row: cameraGrid y floor.
	surfaceZ ifNil: [ ^ #surfaceInconnue ].
	elevation <= surfaceZ ifTrue: [ ^ #sousSurface ].
	spacing := terrain cellSize.
	radius := elevation - terrain minimumSurface * halfField.
	lower := cameraGrid - (radius / spacing x @ (radius / spacing y)).
	upper := cameraGrid + (radius / spacing x @ (radius / spacing y)).
	clipped := lower x < 0 or: [
			           lower y < 0 or: [
				           upper x > terrain columns or: [ upper y > terrain rows ] ] ].
	(lower y floor max: 0) to: (upper y ceiling min: terrain rows - 1)
		do: [ :row |
				(lower x floor max: 0) to:
					(upper x ceiling min: terrain columns - 1) do: [ :column |
						| height offset clearance |
						height := terrain surfaceAtColumn: column row: row.
						height ifNotNil: [
								clearance := elevation - height.
								offset := (column + 0.5 - cameraGrid x) abs * spacing x max:
									          (row + 0.5 - cameraGrid y) abs * spacing y.
								(clearance > 0 and: [
										 offset <= (halfField * clearance) and: [
												 terrain
													 visibleColumn: column
													 row: row
													 from: cameraGrid
													 elevation: elevation
													 clearance: clearance ] ]) ifTrue: [
										receiver
											value: column @ row + gridOffset
											value: 2 * halfField * clearance / sensorPixels ] ] ] ].
	^ clipped
		  ifTrue: [ #bord ]
		  ifFalse: [ #ok ]
]

{ #category : 'query' }
PerceptionAdapter >> omissions [

	^ omissions copy
]

{ #category : 'query' }
PerceptionAdapter >> overlapCellCount [

	^ intervalOverlaps
]

{ #category : 'query' }
PerceptionAdapter >> polygon [

	^ polygon copy
]

{ #category : 'query' }
PerceptionAdapter >> polygonIncludedInTerrain [

	| bounds |
	bounds := terrain projectedBounds.
	^ polygon allSatisfy: [ :vertex |
			  (vertex x between: bounds origin x and: bounds corner x) and: [
				  vertex y between: bounds origin y and: bounds corner y ] ]
]

{ #category : 'query' }
PerceptionAdapter >> poses [

	^ poses copy
]

{ #category : 'setup' }
PerceptionAdapter >> projectPoint: localPoint [

	| projected |
	projected := projection value: localPoint.
	(projected isPoint and: [
			 projected x isNumber and: [
					 projected y isNumber and: [
						 projected x asFloat isFinite and: [
							 projected y asFloat isFinite ] ] ] ]) ifFalse: [
		self error: 'La projection doit retourner un Point en mètres.' ].
	^ projected x asFloat @ projected y asFloat
]

{ #category : 'setup' }
PerceptionAdapter >> projectPolygon: vertices [

	| projected first area |
	projected := vertices asArray collect: [ :vertex |
		             self projectPoint: vertex ].
	(projected size > 1 and: [ projected first = projected last ])
		ifTrue: [ projected := projected allButLast ].
	projected asSet size < 3 ifTrue: [
		self error:
			'Le polygone doit avoir au moins trois sommets distincts.' ].
	first := projected first.
	area := 0.0.
	1 to: projected size do: [ :i |
			| a b |
			a := (projected at: i) - first.
			b := (projected at: i \\ projected size + 1) - first.
			area := area + (a x * b y) - (a y * b x) ].
	area abs <= 0.000000001 ifTrue: [
		self error: 'Le polygone doit délimiter une surface non nulle.' ].
	^ projected
]

{ #category : 'simulation' }
PerceptionAdapter >> recordAfter: duration polygon: vertices drones: dronePoses [

	(duration isNumber and: [
		 duration > 0 and: [ duration asFloat isFinite ] ]) ifFalse: [
		self error: 'La durée du pas doit être finie et positive.' ].
	^ self
		  recordAt: (time ifNil: [ 0 ]) + duration
		  polygon: vertices
		  drones: dronePoses
]

{ #category : 'simulation' }
PerceptionAdapter >> recordAt: seconds polygon: vertices drones: dronePoses [
    "Call after the movement and control update of a simulator tick. Time is cumulative simulated seconds."
    | nextPolygon nextPoses nextSeen overlaps nextOmissions nextClipped ids |
    (seconds isNumber and: [ seconds asFloat isFinite and: [ seconds >= 0 and: [ time isNil or: [ seconds > time ] ] ] ])
        ifFalse: [ self error: 'Le temps simulé doit être fini et strictement croissant.' ].
    nextPolygon := self projectPolygon: vertices.
    nextPoses := dronePoses asArray collect: [ :pose | pose withPosition: (self projectPoint: pose position) ].
    ids := nextPoses collect: #id.
    ids asSet size = ids size ifFalse: [ self error: 'Chaque drone doit conserver un identifiant distinct.' ].
    nextSeen := Dictionary new.
    overlaps := Set new.
    nextOmissions := Dictionary new.
    nextClipped := false.
    nextPoses do: [ :pose |
        | result |
        result := self observePose: pose do: [ :cell :gsd |
            | before |
            before := nextSeen at: cell ifAbsent: [ nil ].
            before ifNotNil: [ overlaps add: cell ].
            (before isNil or: [ gsd < before second ]) ifTrue: [
                nextSeen at: cell put: { seconds. gsd. pose id } ] ].
        result = #bord ifTrue: [ nextClipped := true ].
        (#(ok bord) includes: result) ifFalse: [ nextOmissions at: pose id put: result ] ].
    nextSeen keysAndValuesDo: [ :cell :reading | observations at: cell put: reading ].
    time := seconds.
    polygon := nextPolygon.
    poses := nextPoses.
    omissions := nextOmissions.
    intervalOverlaps := overlaps size.
    footprintClipped := nextClipped.
    ^ self

]

{ #category : 'setup' }
PerceptionAdapter >> replaceTerrain: aTerrain [

	| offset |
	offset := aTerrain offsetFrom: referenceTerrain.
	terrain := aTerrain.
	gridOffset := offset
]

{ #category : 'query' }
PerceptionAdapter >> terrain [

	^ terrain
]

{ #category : 'query' }
PerceptionAdapter >> time [

	^ time
]

{ #category : 'query' }
PerceptionAdapter >> visibleGridObservationsDo: block [

	observations keysAndValuesDo: [ :globalCell :reading |
			| currentCell |
			currentCell := globalCell - gridOffset.
			(terrain includesGrid: currentCell) ifTrue: [
				block value: currentCell value: reading ] ]
]

{ #category : 'query' }
PerceptionAdapter >> whitenessOf: reading [

	^ time - reading first / fadeSeconds asFloat min: 1.0
]
