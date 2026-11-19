Class {
	#name : 'PerceptionTerrain',
	#superclass : 'Object',
	#instVars : [
		'crs',
		'origin',
		'cellSize',
		'columns',
		'rows',
		'ground',
		'surface',
		'minimumSurface',
		'maximumSurface'
	],
	#category : 'Drone-SystemCouplagePerceptionRoassal',
	#package : 'Drone-SystemCouplagePerceptionRoassal'
}

{ #category : 'import' }
PerceptionTerrain class >> fromCsv: groundCsv surfaceCsv: surfaceCsv origin: topLeft cellSize: spacing crs: crsName noData: sentinel [
    | groundRows surfaceRows |
    groundRows := self readCsv: groundCsv asFileReference noData: sentinel.
    surfaceRows := surfaceCsv ifNotNil: [ self readCsv: surfaceCsv asFileReference noData: sentinel ].
    ^ self new initializeGround: groundRows surface: surfaceRows origin: topLeft cellSize: spacing crs: crsName

]

{ #category : 'import' }
PerceptionTerrain class >> fromDirectory: aDirectory [
    | directory metadata |
    directory := aDirectory asFileReference.
    metadata := STONJSON fromString: (directory / 'terrain.json') contents.
    ^ self fromDirectory: directory metadata: metadata

]

{ #category : 'import' }
PerceptionTerrain class >> fromDirectory: directory metadata: metadata [
    | surfaceFile model |
    (metadata at: 'version') = 1 ifFalse: [ self error: 'Version de terrain.json incompatible.' ].
    surfaceFile := metadata at: 'surface' ifAbsent: [ nil ].
    model := self
        fromCsv: directory / (metadata at: 'ground')
        surfaceCsv: (surfaceFile ifNotNil: [ directory / surfaceFile ])
        origin: ((metadata at: 'topLeft') first @ (metadata at: 'topLeft') second)
        cellSize: ((metadata at: 'cellSize') first @ (metadata at: 'cellSize') second)
        crs: (metadata at: 'crs')
        noData: (metadata at: 'noData').
    ((metadata at: 'columns') = model columns and: [ (metadata at: 'rows') = model rows ])
        ifFalse: [ self error: 'Les dimensions annoncées diffèrent du CSV.' ].
    ^ model

]

{ #category : 'import' }
PerceptionTerrain class >> readCsv: csv noData: sentinel [
    | lines width |
    lines := OrderedCollection new.
    width := nil.
    csv readStreamDo: [ :stream |
        [ stream atEnd ] whileFalse: [
            | fields |
            fields := stream nextLine splitOn: $,.
            width ifNil: [ width := fields size ].
            (width > 0 and: [ fields size = width ]) ifFalse: [
                self error: 'Le CSV doit être rectangulaire (ligne ', (lines size + 1) printString, ').' ].
            lines add: (fields collect: [ :field |
                | numeric textStream value |
                numeric := field trimmed.
                numeric isEmpty
                    ifTrue: [ nil ]
                    ifFalse: [
                        textStream := numeric readStream.
                        value := Number readFrom: textStream.
                        (textStream atEnd and: [ value asFloat isFinite ])
                            ifFalse: [ self error: 'Altitude CSV invalide (ligne ', (lines size + 1) printString, ').' ].
                        value = sentinel ifTrue: [ nil ] ifFalse: [ value asFloat ] ] ]) ] ].
    lines isEmpty ifTrue: [ self error: 'Le CSV du terrain est vide.' ].
    ^ lines

]

{ #category : 'accessing' }
PerceptionTerrain >> cellSize [
    ^ cellSize

]

{ #category : 'accessing' }
PerceptionTerrain >> columns [
    ^ columns

]

{ #category : 'accessing' }
PerceptionTerrain >> crs [
    ^ crs

]

{ #category : 'georeferencing' }
PerceptionTerrain >> gridCoordinatesOf: worldPoint [
    ^ ((worldPoint x - origin x) / cellSize x) @ ((origin y - worldPoint y) / cellSize y)

]

{ #category : 'accessing' }
PerceptionTerrain >> groundAt: projectedPoint [
    | grid |
    grid := self gridCoordinatesOf: projectedPoint.
    (self includesGrid: grid) ifFalse: [ ^ nil ].
    ^ self groundAtColumn: grid x floor row: grid y floor

]

{ #category : 'accessing' }
PerceptionTerrain >> groundAtColumn: column row: row [
    ^ ground at: row * columns + column + 1

]

{ #category : 'georeferencing' }
PerceptionTerrain >> includesGrid: gridPoint [
    ^ gridPoint x >= 0 and: [ gridPoint x < columns and: [ gridPoint y >= 0 and: [ gridPoint y < rows ] ] ]

]

{ #category : 'georeferencing' }
PerceptionTerrain >> includesProjectedPoint: point [
    ^ self includesGrid: (self gridCoordinatesOf: point)

]

{ #category : 'configuration' }
PerceptionTerrain >> initializeGround: bareEarth surface: topSurface origin: topLeft cellSize: spacing crs: crsName [
    | valid |
    (spacing x > 0 and: [ spacing y > 0 ]) ifFalse: [ self error: 'Le pas de grille doit être positif.' ].
    origin := topLeft x asFloat @ topLeft y asFloat.
    cellSize := spacing x asFloat @ spacing y asFloat.
    crs := crsName asString.
    rows := bareEarth size.
    columns := bareEarth first size.
    ground := bareEarth flatCollect: [ :row | row ] as: Array.
    topSurface
        ifNil: [ surface := ground ]
        ifNotNil: [
            (topSurface size = rows and: [ topSurface first size = columns ]) ifFalse: [
                self error: 'Le MNT et le MNS doivent utiliser la même grille.' ].
            surface := topSurface flatCollect: [ :row | row ] as: Array.
            1 to: surface size do: [ :i |
                | base roof |
                base := ground at: i.
                roof := surface at: i.
                (base notNil and: [ roof notNil ]) ifTrue: [ surface at: i put: (base max: roof) ] ] ].
    valid := surface reject: #isNil.
    valid isEmpty ifTrue: [ self error: 'Aucune altitude exploitable dans la grille.' ].
    minimumSurface := valid min.
    maximumSurface := valid max

]

{ #category : 'accessing' }
PerceptionTerrain >> maximumSurface [
    ^ maximumSurface

]

{ #category : 'accessing' }
PerceptionTerrain >> minimumSurface [
    ^ minimumSurface

]

{ #category : 'georeferencing' }
PerceptionTerrain >> offsetFrom: reference [
    | offset integerOffset |
    (crs = reference crs and: [ cellSize = reference cellSize ]) ifFalse: [
        self error: 'Pour conserver la mémoire, garder le même CRS et le même pas.' ].
    offset := reference gridCoordinatesOf: origin.
    integerOffset := offset x rounded @ offset y rounded.
    ((offset x - integerOffset x) abs < 0.000001 and: [ (offset y - integerOffset y) abs < 0.000001 ])
        ifFalse: [ self error: 'La nouvelle grille doit être alignée sur les cellules de la première.' ].
    ^ integerOffset

]

{ #category : 'accessing' }
PerceptionTerrain >> origin [
    ^ origin

]

{ #category : 'georeferencing' }
PerceptionTerrain >> projectedBounds [
    ^ (origin x @ (origin y - (rows * cellSize y))) corner: ((origin x + (columns * cellSize x)) @ origin y)

]

{ #category : 'georeferencing' }
PerceptionTerrain >> projectedCenterAtColumn: column row: row [
    ^ (origin x + ((column + 0.5) * cellSize x)) @ (origin y - ((row + 0.5) * cellSize y))

]

{ #category : 'accessing' }
PerceptionTerrain >> rows [
    ^ rows

]

{ #category : 'accessing' }
PerceptionTerrain >> surfaceAtColumn: column row: row [
    ^ surface at: row * columns + column + 1

]

{ #category : 'visibility' }
PerceptionTerrain >> visibleColumn: column row: row from: cameraGrid elevation: cameraAltitude clearance: clearance [
    "The ray rises from the target centre. A crossed cell is tested at the ray's lowest point within it."
    | x y sensorX sensorY dx dy stepX stepY deltaX deltaY nextX nextY entryX entryY t surfaceZ targetZ |
    x := column.
    y := row.
    sensorX := cameraGrid x floor.
    sensorY := cameraGrid y floor.
    dx := cameraGrid x - (x + 0.5).
    dy := cameraGrid y - (y + 0.5).
    stepX := dx sign.
    stepY := dy sign.
    deltaX := stepX = 0 ifTrue: [ Float infinity ] ifFalse: [ 1.0 / dx abs ].
    deltaY := stepY = 0 ifTrue: [ Float infinity ] ifFalse: [ 1.0 / dy abs ].
    nextX := deltaX / 2.
    nextY := deltaY / 2.
    targetZ := cameraAltitude - clearance.
    [ x = sensorX and: [ y = sensorY ] ] whileFalse: [
        entryX := x = sensorX ifTrue: [ Float infinity ] ifFalse: [ nextX ].
        entryY := y = sensorY ifTrue: [ Float infinity ] ifFalse: [ nextY ].
        t := entryX min: entryY.
        entryX <= t ifTrue: [ x := x + stepX. nextX := nextX + deltaX ].
        entryY <= t ifTrue: [ y := y + stepY. nextY := nextY + deltaY ].
        surfaceZ := self surfaceAtColumn: x row: y.
        (surfaceZ isNil or: [ surfaceZ > (targetZ + (clearance * t) + 0.000001) ]) ifTrue: [ ^ false ] ].
    ^ true

]
