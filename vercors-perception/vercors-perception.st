PerceptionTerrain subclass: #VercorsPerceptionTerrain
    instanceVariableNames: 'shadowCandidates'
    classVariableNames: ''
    package: 'VercorsPerception'!

PerceptionAdapter subclass: #VercorsPerceptionAdapter
    instanceVariableNames: 'shadowCells'
    classVariableNames: ''
    package: 'VercorsPerception'!

PerceptionRoassalView subclass: #VercorsPerceptionView
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'VercorsPerception'!

Object subclass: #VercorsPerceptionExample
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'VercorsPerception'!

!VercorsPerceptionTerrain methodsFor: 'visibility'!
collectShadowsDuring: block
    | previous candidates |
    previous := shadowCandidates.
    candidates := Set new.
    shadowCandidates := candidates.
    block ensure: [ shadowCandidates := previous ].
    ^ candidates
!

visibleColumn: column row: row from: cameraGrid elevation: altitude clearance: clearance
    | visible |
    visible := super visibleColumn: column row: row from: cameraGrid
        elevation: altitude clearance: clearance.
    (visible not and: [ shadowCandidates notNil ]) ifTrue: [
        shadowCandidates add: column @ row ].
    ^ visible
! !

!VercorsPerceptionAdapter methodsFor: 'simulation'!
recordAt: seconds polygon: vertices drones: dronePoses
    shadowCells := terrain collectShadowsDuring: [
        super recordAt: seconds polygon: vertices drones: dronePoses ].
    ^ self
! !

!VercorsPerceptionAdapter methodsFor: 'query'!
shadowGridCellsDo: block
    "Keep only cells in a footprint that every contributing ray failed to reach."
    shadowCells ifNotNil: [
        shadowCells do: [ :cell |
            | reading |
            reading := observations at: cell + gridOffset ifAbsent: [ nil ].
            (reading isNil or: [ reading first < time ]) ifTrue: [ block value: cell ] ] ]
! !

!VercorsPerceptionView methodsFor: 'configuration'!
initializeOn: aPerceptionAdapter
    super initializeOn: aPerceptionAdapter.
    self canvas extent: 770 @ 860
! !

!VercorsPerceptionView methodsFor: 'drawing'!
reliefFor: aTerrain
    | lowest range forest rock shaded spacing |
    backgroundTerrain == aTerrain ifTrue: [ ^ background ].
    lowest := aTerrain minimumSurface.
    range := (aTerrain maximumSurface - lowest) max: 1.
    forest := Color fromHexString: '3B514C'.
    rock := Color fromHexString: 'B1B6AA'.
    shaded := Color fromHexString: '192939'.
    spacing := aTerrain cellSize.
    background := Form extent: aTerrain columns @ aTerrain rows depth: 32.
    0 to: aTerrain rows - 1 do: [ :row |
        0 to: aTerrain columns - 1 do: [ :column |
            | height west east north south slopeX slopeY light tint |
            height := aTerrain surfaceAtColumn: column row: row.
            height ifNil: [
                background colorAt: column @ row put: shaded ] ifNotNil: [
                west := aTerrain surfaceAtColumn: ((column - 1) max: 0) row: row.
                east := aTerrain surfaceAtColumn: ((column + 1) min: aTerrain columns - 1) row: row.
                north := aTerrain surfaceAtColumn: column row: ((row - 1) max: 0).
                south := aTerrain surfaceAtColumn: column row: ((row + 1) min: aTerrain rows - 1).
                slopeX := ((east ifNil: [ height ]) - (west ifNil: [ height ])) / (2 * spacing x).
                slopeY := ((north ifNil: [ height ]) - (south ifNil: [ height ])) / (2 * spacing y).
                light := (0.48 * slopeX - (0.52 * slopeY) + 0.71)
                    / (1 + slopeX squared + slopeY squared) sqrt.
                tint := rock mixed: (height - lowest) / range with: forest.
                background colorAt: column @ row
                    put: (tint mixed: 0.37 + (0.63 * (light max: 0)) with: shaded) ] ] ].
    backgroundTerrain := aTerrain.
    ^ background
!

overlayFor: aTerrain
    | overlay hatch |
    overlay := super overlayFor: aTerrain.
    hatch := (Color fromHexString: 'F879A7') alpha: 0.85.
    adapter shadowGridCellsDo: [ :cell |
        ((cell x + cell y) \\ 5) < 2 ifTrue: [
            overlay colorAt: cell put: hatch ] ].
    ^ overlay
!

drawLegend
    | y heightCaption heights |
    super drawLegend.
    self label: 'Vercors · Vassieux et les Gagères' at: 275 @ 10 size: 18 color: Color white.
    self drawPlace: 'Col de la Chau' at: 5.35662 @ 44.90731 offset: -76 @ -20.
    self drawPlace: 'Crêtes des Gagères' at: 5.34170 @ 44.88896 offset: -115 @ 6.
    self drawPlace: 'Vassieux-en-Vercors' at: 5.37066 @ 44.89559 offset: 8 @ -5.
    y := canvas extent y - 49.
    self label: 'Hachures roses · masque de relief' at: 472 @ y size: 13
        color: (Color fromHexString: 'F879A7').
    heights := adapter poses collect: #altitude.
    heights ifNotEmpty: [
        heightCaption := heights min = heights max
            ifTrue: [ heights first printString ]
            ifFalse: [ heights min printString, '–', heights max printString ].
        self label: (heights size printString, ' drones · ', heightCaption, ' m au-dessus du sol')
            at: 472 @ (y + 21) size: 13 color: (Color fromHexString: 'C0CEE0') ]
!

drawPlace: name at: lonLat offset: offset
    | point |
    point := self screenPoint: (PerceptionCoordinateTransform lambert93: lonLat).
    self label: name at: point + offset size: 13 color: Color white
! !

!VercorsPerceptionExample class methodsFor: 'inputs'!
wayPointsFrom: bundle
    | geometry |
    geometry := STONJSON fromString: (bundle asFileReference / 'parcours-vercors.geojson') contents.
    ^ (geometry at: 'coordinates') first allButLast collect: [ :pair |
        pair first @ pair second ]
!

observerOver: ground wayPoints: wayPoints heightAt: heightAt fadeAfterSeconds: fadeSeconds
    | directory metadata terrain source points segments perimeter perception view |
    directory := ground asFileReference.
    metadata := STONJSON fromString: (directory / 'terrain.json') contents.
    terrain := VercorsPerceptionTerrain fromDirectory: directory metadata: metadata.
    source := PerceptionAdapter on: terrain
        projection: (PerceptionCoordinateTransform forMetadata: metadata).
    points := source projectPolygon: wayPoints.
    segments := OrderedCollection new.
    perimeter := 0.0.
    "Each segment contains both ends and their cumulative distances in metres."
    points withIndexDo: [ :a :i |
        | b endDistance |
        b := points at: (i \\ points size) + 1.
        endDistance := perimeter + (a distanceTo: b).
        endDistance > perimeter ifTrue: [
            segments add: { a. b. perimeter. endDistance }.
            perimeter := endDistance ] ].

    perception := VercorsPerceptionAdapter on: terrain.
    perception cameraHalfFieldTangent: 1.0 sensorSidePixels: 2000.
    perception fadeAfterSeconds: fadeSeconds.
    view := VercorsPerceptionView on: perception.
    ^ [ :step :seconds |
        | lap poses |
        lap := step range.
        poses := step drones collect: [ :drone |
            | distance segment fraction |
            distance := (drone position \\ lap) / lap * perimeter.
            segment := segments detect: [ :each | distance < each fourth ]
                ifNone: [ segments last ].
            fraction := (distance - segment third) / (segment fourth - segment third).
            PerceptionDronePose
                id: drone id
                position: (segment first interpolateTo: segment second at: fraction)
                heightAboveGround: (heightAt value: step value: drone) ].
        perception recordAt: seconds polygon: points drones: poses.
        view ]
! !

!VercorsPerceptionExample class methodsFor: 'example'!
replayFrom: bundle heightAboveGround: metres secondsPerTick: secondsPerTick
    ^ self replayFrom: bundle heightAt: [ :step :drone | metres ] secondsPerTick: secondsPerTick
!

replayFrom: bundle heightAt: heightAt secondsPerTick: secondsPerTick
    | simulator observer view |
    (secondsPerTick isNumber and: [ secondsPerTick > 0 and: [ secondsPerTick asFloat isFinite ] ])
        ifFalse: [ self error: 'La durée du tik doit être finie et positive.' ].
    observer := self observerOver: bundle asFileReference / 'terrain-vercors'
        wayPoints: (self wayPointsFrom: bundle)
        heightAt: heightAt
        fadeAfterSeconds: 300.
    simulator := self newSimulator.
    simulator run: 90.
    simulator history do: [ :step |
        view := observer value: step value: step timeStep * secondsPerTick ].
    ^ view
!

newSimulator
    | parameters simulator |
    parameters := MacroSimulatorParameters new
        numberOfDrones: 20;
        nominalSpeed: 10;
        maxSpeed: 15;
        sensingRadius: 20;
        captureRadius: 20;
        totalDistance: 10000;
        policy: #capingPolicy;
        seed: 3950149054165;
        yourself.
    simulator := parameters initializeSimulator.
    simulator behavior sensibility: 0.01; pacingRate: 1.0.
    ^ simulator
! !
