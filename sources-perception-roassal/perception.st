Object subclass: #DronePerceptionDemo
    instanceVariableNames: 'width height cellSize altitude sensorPixels halfFov terrain importedSurface maximumHeight palette position mapOrigin mapScale canvas'
    classVariableNames: ''
    package: 'DronePerceptionDemo'!

!DronePerceptionDemo methodsFor: 'configuration'!
initialize
    super initialize.
    width := 180.
    height := 130.
    cellSize := 10.
    altitude := 200.0.
    sensorPixels := 2000.
    halfFov := 2.5.
    mapOrigin := 38 @ 106.
    mapScale := 4.
    palette := #('689EF7' '50C9E5' '55E2B3' 'BBEE75') collect: [ :hex | Color fromHexString: hex ]
!

gaussianAt: aPoint center: center radii: radii
    | distance |
    distance := (aPoint - center) / radii.
    ^ ((distance x squared + distance y squared) negated / 2) exp
!

urbanHeightAt: aPoint
    | x y column row bx by |
    x := aPoint x floor.
    y := aPoint y floor.
    (x < 23 or: [ x > 156 or: [ y < 23 or: [ y > 108 ] ] ]) ifTrue: [ ^ 0 ].
    ((y - (30 + (x * 0.49))) abs < 4.0) ifTrue: [ ^ 0 ].
    column := x // 15.
    row := y // 13.
    bx := x \\ 15.
    by := y \\ 13.
    (bx < 3 or: [ bx > 11 or: [ by < 2 or: [ by > 10 ] ] ]) ifTrue: [ ^ 0 ].
    ((column + (row * 3)) \\ 9 = 2 and: [ bx > 8 ]) ifTrue: [ ^ 0 ].
    ^ 16 + (((column * 23 + (row * 37)) \\ 91) * (1 - ((x - 91) abs / 110)))
!

mountainHeightAt: aPoint
    | ridge spur east river |
    ridge := 137 * (self gaussianAt: aPoint center: 74@55 radii: 17@10).
    spur := 126 * (self gaussianAt: aPoint center: 103@82 radii: 12@16).
    east := 145 * (self gaussianAt: aPoint center: 133@42 radii: 12@12).
    river := 16 * (self gaussianAt: aPoint center: 95@68 radii: 32@4).
    ^ ((ridge max: (spur max: east)) + (9 * (1 + (aPoint x / 13 + (aPoint y / 18)) sin)) - river) max: 0
!

surfaceFromCsv: file
    | heights lineCount |
    heights := OrderedCollection new: width * height.
    lineCount := 0.
    file readStreamDo: [ :stream |
        [ stream atEnd ] whileFalse: [
            | row |
            row := stream nextLine splitOn: $,.
            row size = width ifFalse: [ self error: 'Le CSV doit comporter 180 colonnes.' ].
            row do: [ :field |
                | elevation |
                elevation := field trimmed asNumber.
                (elevation isNumber and: [ elevation between: 0 and: altitude - 0.000001 ])
                    ifFalse: [ self error: 'Altitude de surface attendue entre 0 m et moins de 200 m.' ].
                heights add: elevation ].
            lineCount := lineCount + 1 ] ].
    lineCount = height ifFalse: [ self error: 'Le CSV doit comporter 130 lignes.' ].
    importedSurface := heights asArray
!

configureScene: scene
    scene = #surface ifTrue: [
        importedSurface ifNil: [ self error: 'Surface importée manquante.' ].
        terrain := importedSurface.
        maximumHeight := terrain max.
        ^ self ].
    terrain := Array new: width * height.
    0 to: height - 1 do: [ :y |
        0 to: width - 1 do: [ :x |
            | point |
            point := (x + 0.5) @ (y + 0.5).
            terrain at: y * width + x + 1 put: (scene = #ville
                ifTrue: [ self urbanHeightAt: point ]
                ifFalse: [ self mountainHeightAt: point ]) ] ].
    maximumHeight := terrain max.
    maximumHeight < altitude ifFalse: [ self error: 'La trajectoire traverse le relief' ]
! !

!DronePerceptionDemo methodsFor: 'projection'!
canSeeX: targetX y: targetY clearance: clearance
    "Traverse the heightfield cells in ray order. In each crossed cell the ray is lowest at its exit."
    | startX startY dx dy cellX cellY stepX stepY nextX nextY deltaX deltaY exit rayZ |
    startX := position x.
    startY := position y.
    dx := targetX + 0.5 - startX.
    dy := targetY + 0.5 - startY.
    cellX := startX floor.
    cellY := startY floor.
    stepX := dx sign.
    stepY := dy sign.
    deltaX := dx = 0 ifTrue: [ 2.0 ] ifFalse: [ 1.0 / dx abs ].
    deltaY := dy = 0 ifTrue: [ 2.0 ] ifFalse: [ 1.0 / dy abs ].
    nextX := stepX = 0 ifTrue: [ 2.0 ] ifFalse: [
        ((stepX > 0 ifTrue: [ cellX + 1 ] ifFalse: [ cellX ]) - startX) / dx ].
    nextY := stepY = 0 ifTrue: [ 2.0 ] ifFalse: [
        ((stepY > 0 ifTrue: [ cellY + 1 ] ifFalse: [ cellY ]) - startY) / dy ].
    [ cellX = targetX and: [ cellY = targetY ] ] whileFalse: [
        exit := nextX min: nextY.
        rayZ := altitude - (exit * clearance).
        (rayZ <= maximumHeight and: [
            (terrain at: cellY * width + cellX + 1) > (rayZ + 0.000001) ]) ifTrue: [ ^ false ].
        nextX <= exit ifTrue: [ cellX := cellX + stepX. nextX := nextX + deltaX ].
        nextY <= exit ifTrue: [ cellY := cellY + stepY. nextY := nextY + deltaY ] ].
    ^ true
!

classForGsd: gsd
    gsd <= 0.20 ifTrue: [ ^ 4 ].
    gsd <= 0.32 ifTrue: [ ^ 3 ].
    gsd <= 0.44 ifTrue: [ ^ 2 ].
    ^ 1
!

footprintOn: overlay
    | radius visible blocked shadow |
    radius := halfFov * altitude / cellSize.
    visible := 0.
    blocked := 0.
    shadow := (Color fromHexString: 'FF9B68') alpha: 0.60.
    ((position y - radius) floor max: 0) to: ((position y + radius) ceiling min: height - 1) do: [ :y |
        ((position x - radius) floor max: 0) to: ((position x + radius) ceiling min: width - 1) do: [ :x |
            | clearance distance gsd |
            clearance := altitude - (terrain at: y * width + x + 1).
            distance := ((x + 0.5 - position x) abs max: (y + 0.5 - position y) abs) * cellSize.
            distance <= (halfFov * clearance) ifTrue: [
                (self canSeeX: x y: y clearance: clearance)
                    ifTrue: [
                        gsd := 2 * halfFov * clearance / sensorPixels.
                        visible := visible + 1.
                        overlay colorAt: x@y put: ((palette at: (self classForGsd: gsd)) alpha: 0.70) ]
                    ifFalse: [
                        blocked := blocked + 1.
                        (x + y \\ 4 < 2) ifTrue: [ overlay colorAt: x@y put: shadow ] ] ] ] ].
    ^ { visible * cellSize squared. blocked * cellSize squared }
! !

!DronePerceptionDemo methodsFor: 'rendering'!
addFixed: shape
    shape setAsFixed.
    canvas add: shape
!

boxAt: origin extent: extent fill: fill
    | shape |
    shape := RSBox new extent: extent; color: fill; yourself.
    shape translateTo: origin + (extent / 2).
    ^ shape
!

label: text at: topLeft size: size color: color bold: isBold
    | label |
    label := RSLabel new text: text; fontSize: size; color: color; yourself.
    isBold ifTrue: [ label bold ].
    label translateTo: topLeft + (label extent / 2).
    self addFixed: label.
    ^ label
!

lineFrom: start to: end color: aColor width: stroke
    | line |
    line := RSLine new startPoint: start; endPoint: end; color: aColor; width: stroke; yourself.
    self addFixed: line.
    ^ line
!

circleAt: point size: size color: fill
    | shape |
    shape := RSEllipse new size: size; color: fill; yourself.
    shape translateTo: point.
    self addFixed: shape
!

mapBitmap: form
    | bitmap extent |
    extent := (width @ height) * mapScale.
    bitmap := RSBitmap new form: form; extent: extent; yourself.
    bitmap translateTo: mapOrigin + (extent / 2).
    self addFixed: bitmap
!

baseMapFor: scene
    | form dark light road |
    form := Form extent: width @ height depth: 32.
    dark := Color fromHexString: '192A3B'.
    light := Color fromHexString: '637589'.
    road := Color fromHexString: '344657'.
    0 to: height - 1 do: [ :y |
        0 to: width - 1 do: [ :x |
            | h east south shade color |
            h := terrain at: y * width + x + 1.
            east := terrain at: y * width + ((x + 1) min: width - 1) + 1.
            south := terrain at: (((y + 1) min: height - 1) * width + x + 1).
            shade := ((h / 240 + ((h - east + (h - south)) * 0.022)) max: 0) min: 1.
            color := dark mixed: 1 - shade with: light.
            scene = #ville ifTrue: [
                ((x \\ 15 = 1 or: [ y \\ 13 = 0 ]) and: [ x between: 20 and: 160 ] ) ifTrue: [ color := road ].
                ((y - (30 + (x * 0.49))) abs < 2.0) ifTrue: [ color := road ] ].
            scene ~= #ville ifTrue: [
                (h > 15 and: [ (h / 15) floor ~= (east / 15) floor or: [ (h / 15) floor ~= (south / 15) floor ] ])
                    ifTrue: [ color := color mixed: 0.88 with: light ] ].
            form colorAt: x@y put: color ] ].
    ^ form
!

drawHeaderFor: scene
    | ink muted name source |
    ink := Color fromHexString: 'F1F6FC'.
    muted := Color fromHexString: 'A8B9CC'.
    name := scene caseOf: {
        [ #ville ] -> [ 'Scène urbaine' ].
        [ #montagne ] -> [ 'Relief montagneux' ].
        [ #surface ] -> [ 'Relief importé' ] }.
    source := scene = #surface ifTrue: [ 'SURFACE IMPORTÉE' ] ifFalse: [ 'SCÈNE SYNTHÉTIQUE' ].
    self label: name at: 37@21 size: 35 color: ink bold: true.
    self label: 'Empreinte optique au sol · caméra verticale' at: 39@74 size: 16 color: muted bold: false.
    self label: source at: 848@53 size: 13 color: muted bold: true
!

drawKeyWith: counts elapsed: elapsed
    | ink muted panel x y units |
    ink := Color fromHexString: 'F1F6FC'.
    muted := Color fromHexString: 'A8B9CC'.
    panel := Color fromHexString: '152334'.
    self addFixed: (self boxAt: 782@106 extent: 260@520 fill: panel).
    x := 803.
    self label: 'RÉSOLUTION AU SOL' at: x@128 size: 14 color: muted bold: true.
    self label: 'Mètres par pixel estimés' at: x@153 size: 15 color: ink bold: false.
    y := 191.
    units := #('≤ 0,20 m/px' '0,20 à 0,32 m/px' '0,32 à 0,44 m/px' '> 0,44 m/px').
    4 to: 1 by: -1 do: [ :k |
        self addFixed: (self boxAt: x@y extent: 16@13 fill: (palette at: k)).
        self label: (units at: 5 - k) at: (x + 26) @ (y - 3) size: 15 color: ink bold: false.
        y := y + 28 ].
    self addFixed: (self boxAt: x@315 extent: 16@13 fill: (Color fromHexString: 'FF9B68')).
    self label: 'Masqué par le relief' at: (x + 26)@312 size: 15 color: ink bold: false.
    (self lineFrom: x@355 to: (x + 18)@355 color: muted width: 2) dashArray: #(4 3).
    self label: 'Carré de référence 1 km²' at: (x + 26)@344 size: 15 color: ink bold: false.
    self lineFrom: x@390 to: 1021@390 color: (Color fromHexString: '32465B') width: 1.
    self label: 'SURFACE VISIBLE' at: x@412 size: 13 color: muted bold: true.
    self label: ((counts first / 1000000 printShowingDecimalPlaces: 2) copyReplaceAll: '.' with: ','), ' km²'
        at: x@436 size: 27 color: ink bold: true.
    self label: 'SURFACE MASQUÉE' at: x@484 size: 13 color: muted bold: true.
    self label: ((counts second / 1000000 printShowingDecimalPlaces: 2) copyReplaceAll: '.' with: ','), ' km²'
        at: x@506 size: 23 color: ink bold: true.
    self label: 'ALTITUDE RÉF.   200 m' at: x@557 size: 13 color: muted bold: true.
    self label: 'Pas du modèle de surface   10 m' at: x@583 size: 13 color: muted bold: false.
    self label: ('t = ', ((elapsed printShowingDecimalPlaces: 1) copyReplaceAll: '.' with: ','), ' s')
        at: 928@647 size: 15 color: muted bold: false
!

routeAt: progress
    ^ (53 + (74 * progress)) @ (61 + (12 * (Float pi * progress) sin) + (7 * progress))
!

drawTrackAt: progress
    | ink muted center radius p1 p2 p3 p4 previous |
    ink := Color fromHexString: 'F1F6FC'.
    muted := Color fromHexString: 'A8B9CC'.
    center := mapOrigin + (position * mapScale).
    radius := (halfFov * altitude / cellSize) * mapScale.
    p1 := center - (radius@radius).
    p2 := (center x + radius) @ (center y - radius).
    p3 := center + (radius@radius).
    p4 := (center x - radius) @ (center y + radius).
    { p1 -> p2. p2 -> p3. p3 -> p4. p4 -> p1 } do: [ :pair |
        (self lineFrom: pair key to: pair value color: (ink alpha: 0.72) width: 1.1) dashArray: #(6 5) ].
    previous := mapOrigin + ((self routeAt: 0) * mapScale).
    1 to: 28 do: [ :k |
        | next |
        next := mapOrigin + ((self routeAt: progress * k / 28) * mapScale).
        self lineFrom: previous to: next color: (ink alpha: 0.72) width: 1.6.
        previous := next ].
    self circleAt: center size: 17 color: (Color fromHexString: '101E31').
    self circleAt: center size: 10 color: ink.
    self lineFrom: 39@648 to: 119@648 color: muted width: 2.
    self lineFrom: 39@644 to: 39@651 color: muted width: 2.
    self lineFrom: 119@644 to: 119@651 color: muted width: 2.
    self label: '200 m' at: 130@638 size: 14 color: muted bold: false
!

renderScene: scene in: directory frames: frameCount fps: fps
    | background |
    directory ensureCreateDirectory.
    self configureScene: scene.
    background := self baseMapFor: scene.
    0 to: frameCount - 1 do: [ :index |
        | overlay counts progress file |
        progress := frameCount = 1 ifTrue: [ 0.5 ] ifFalse: [ index / (frameCount - 1) asFloat ].
        position := self routeAt: progress.
        overlay := Form extent: width @ height depth: 32.
        counts := self footprintOn: overlay.
        canvas := RSCanvas new extent: 1080@680; color: (Color fromHexString: '101B29'); yourself.
        self mapBitmap: background.
        self mapBitmap: overlay.
        self drawHeaderFor: scene.
        self drawTrackAt: progress.
        self drawKeyWith: counts elapsed: index / fps asFloat.
        file := directory / ((index printString padLeftTo: 4 with: $0), '.png').
        file ensureDelete.
        PNGReadWriter putForm: canvas asForm onFileNamed: file fullName ]
! !
