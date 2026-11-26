"
Options du rejeu pour le fond, les noms, les vitesses et l’affichage des pertes. Les croix restent à la dernière position enregistrée par SoSe pendant lossMarkerSeconds. Un point mobile devient doré au pas où sa cellule est effectivement relevée. detectedIntruderIds répond les identifiants détectés au dernier pas, pour une lecture dans l’exemple ou un moniteur.

showCoverage commande le dessin des empreintes et des masques du relief. showRoute commande le trait du parcours. droneMarkerSize donne le diamètre des symboles des drones en pixels.

droneColorMode choisit speed, acceleration ou none. accelerationThreshold donne la demi-largeur de la zone neutre en m/s². En mode accélération, le bleu indique un freinage et l’orange une hausse de vitesse.

"
Class {
	#name : 'PerceptionMissionView',
	#superclass : 'PerceptionRoassalView',
	#instVars : [
		'options',
		'speedRatios',
		'accelerations',
		'losses',
		'intruders'
	],
	#category : 'PerceptionMission',
	#package : 'PerceptionMission'
}

{ #category : 'instance creation' }
PerceptionMissionView class >> on: adapter options: settings [
    ^ self new initializeOn: adapter options: settings

]

{ #category : 'configuration' }
PerceptionMissionView >> accelerationThreshold [
    ^ options at: #accelerationThreshold ifAbsent: [ 0 ]

]

{ #category : 'configuration' }
PerceptionMissionView >> annotateAccelerations: values [
    accelerations := values

]

{ #category : 'configuration' }
PerceptionMissionView >> annotateSpeeds: ratios losses: lossMarkers intruders: pointMarkers [
    speedRatios := ratios.
    losses := lossMarkers.
    intruders := pointMarkers

]

{ #category : 'configuration' }
PerceptionMissionView >> detectedIntruderIds [
    ^ (intruders select: [ :marker | marker third ]) collect: #first

]

{ #category : 'drawing' }
PerceptionMissionView >> dotAt: point size: size color: color [
    | dot |
    dot := RSEllipse new size: size; color: color; yourself.
    dot translateTo: point.
    self addFixed: dot

]

{ #category : 'drawing' }
PerceptionMissionView >> drawDrones [
    | names markerSize |
    names := options at: #showDroneNames ifAbsent: [ true ].
    markerSize := options at: #droneMarkerSize ifAbsent: [ 9 ].
    adapter poses do: [ :pose |
        (adapter terrain includesProjectedPoint: pose position) ifTrue: [
            | point |
            point := self screenPoint: pose position.
            self dotAt: point size: markerSize color: (self droneColorFor: pose id).
            names ifTrue: [ self label: pose id asString at: point + (6 @ -17)
                size: 12 color: Color white ] ] ].
    losses do: [ :marker |
        (adapter terrain includesProjectedPoint: marker second) ifTrue: [
            | point color |
            point := self screenPoint: marker second.
            color := Color fromHexString: 'FF706B'.
            self drawLineFrom: point - (5 @ 5) to: point + (5 @ 5) color: color.
            self drawLineFrom: point + (-5 @ 5) to: point + (5 @ -5) color: color.
            names ifTrue: [ self label: marker first asString at: point + (7 @ -15)
                size: 12 color: color ] ] ].
    intruders do: [ :marker |
        (adapter terrain includesProjectedPoint: marker second) ifTrue: [
            self dotAt: (self screenPoint: marker second)
                size: (marker third ifTrue: [ 12 ] ifFalse: [ 4 ])
                color: (Color fromHexString: (marker third
                    ifTrue: [ 'FFE48F' ] ifFalse: [ '8994A4' ])) ] ]

]

{ #category : 'drawing' }
PerceptionMissionView >> drawLegend [
    | y muted coverage mode |
    coverage := self showsCoverage.
    coverage
        ifTrue: [ super drawLegend ]
        ifFalse: [
            self
                label: 'Temps simulé  ', ((adapter time ifNil: [ 0 ]) printShowingDecimalPlaces: 2), ' s'
                at: 16 @ 10
                size: 18
                color: Color white ].
    y := canvas extent y - 49.
    muted := Color fromHexString: 'C0CEE0'.
    mode := self droneColorMode.
    mode = #none ifFalse: [
        | labels |
        labels := mode = #acceleration
            ifTrue: [ #( 'Accélération' 'Freine' 'Stable' 'Accélère' ) ]
            ifFalse: [ #( 'Vitesse' 'Lente' 'Nominale' 'Rapide' ) ].
        self label: labels first at: 445 @ y size: 13 color: muted.
        self label: labels second at: 552 @ y size: 13 color: (Color fromHexString: '62C6FF').
        self label: labels third at: 614 @ y size: 13 color: Color white.
        self label: labels fourth at: 697 @ y size: 13 color: (Color fromHexString: 'FFAE68') ].
    coverage ifTrue: [
        self label: 'Hachures · masque' at: 777 @ y size: 13
            color: (Color fromHexString: 'F879A7').
        adapter transparentAfterSeconds ifNotNil: [ :seconds |
            self label: 'Transparent à ', seconds printString, ' s'
                at: 270 @ (y + 21) size: 13 color: muted ] ].
    (options at: #lossMarkerSeconds ifAbsent: [ 0 ]) > 0 ifTrue: [
        self label: 'Croix rouge · perte' at: 460 @ (y + 21)
            size: 13 color: (Color fromHexString: 'FF706B') ].
    intruders ifNotEmpty: [
        self label: 'Point doré · détecté' at: 760 @ (y + 21)
            size: 13 color: (Color fromHexString: 'FFE48F') ]

]

{ #category : 'drawing' }
PerceptionMissionView >> drawLineFrom: start to: stop color: color [
    self addFixed: (RSLine new startPoint: start; endPoint: stop; color: color; width: 2.5; yourself)

]

{ #category : 'drawing' }
PerceptionMissionView >> drawPolygon [
    (options at: #showRoute ifAbsent: [ true ]) ifTrue: [ super drawPolygon ]

]

{ #category : 'drawing' }
PerceptionMissionView >> droneColorFor: id [
    | acceleration threshold |
    self droneColorMode = #acceleration ifFalse: [ ^ self speedColorFor: id ].
    acceleration := accelerations at: id ifAbsent: [ 0 ].
    threshold := self accelerationThreshold.
    acceleration < threshold negated ifTrue: [ ^ Color fromHexString: '62C6FF' ].
    acceleration > threshold ifTrue: [ ^ Color fromHexString: 'FFAE68' ].
    ^ Color white

]

{ #category : 'configuration' }
PerceptionMissionView >> droneColorMode [
    ^ options at: #droneColorMode ifAbsent: [
        (options at: #showSpeedColors ifAbsent: [ false ])
            ifTrue: [ #speed ]
            ifFalse: [ #none ] ]

]

{ #category : 'configuration' }
PerceptionMissionView >> initializeOn: anAdapter options: settings [
    | mode threshold |
    super initializeOn: anAdapter.
    options := settings copy.
    (#(hillshade elevation none) includes: (options at: #background ifAbsent: [ #hillshade ]))
        ifFalse: [ self error: 'Fond de carte inconnu.' ].
    mode := self droneColorMode.
    (#(speed acceleration none) includes: mode)
        ifFalse: [ self error: 'Mode de couleur des drones inconnu.' ].
    mode = #acceleration ifTrue: [
        threshold := self accelerationThreshold.
        (threshold isNumber and: [ threshold >= 0 and: [ threshold asFloat isFinite ] ])
            ifFalse: [ self error: 'Le seuil d’accélération doit être positif ou nul et fini.' ] ].
    canvas extent: 960 @ 740.
    speedRatios := Dictionary new.
    accelerations := Dictionary new.
    losses := intruders := #()

]

{ #category : 'drawing' }
PerceptionMissionView >> overlayFor: aTerrain [
    | overlay hatch |
    self showsCoverage ifFalse: [
        ^ Form extent: aTerrain columns @ aTerrain rows depth: 32 ].
    overlay := super overlayFor: aTerrain.
    adapter transparentAfterSeconds ifNotNil: [
        adapter visibleGridObservationsDo: [ :cell :reading |
            | color |
            color := overlay colorAt: cell.
            overlay colorAt: cell put: (color alpha: 0.90 * (adapter opacityOf: reading)) ] ].
    hatch := (Color fromHexString: 'F879A7') alpha: 0.85.
    adapter shadowGridCellsDo: [ :cell |
        ((cell x + cell y) \\ 5) < 2 ifTrue: [
            overlay colorAt: cell put: hatch ] ].
    ^ overlay

]

{ #category : 'drawing' }
PerceptionMissionView >> reliefFor: aTerrain [
    | lowest range forest rock shaded spacing style |
    style := options at: #background ifAbsent: [ #hillshade ].
    style = #elevation ifTrue: [ ^ super reliefFor: aTerrain ].
    backgroundTerrain == aTerrain ifTrue: [ ^ background ].
    style = #none ifTrue: [
        background := Form extent: aTerrain columns @ aTerrain rows depth: 32.
        backgroundTerrain := aTerrain.
        ^ background ].
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

]

{ #category : 'configuration' }
PerceptionMissionView >> showsCoverage [
    ^ options at: #showCoverage ifAbsent: [ true ]

]

{ #category : 'drawing' }
PerceptionMissionView >> speedColorFor: id [
    | ratio |
    self droneColorMode = #speed ifFalse: [ ^ Color white ].
    ratio := speedRatios at: id ifAbsent: [ 1 ].
    ratio < 0.95 ifTrue: [ ^ Color fromHexString: '62C6FF' ].
    ratio > 1.05 ifTrue: [ ^ Color fromHexString: 'FFAE68' ].
    ^ Color white

]

{ #category : 'configuration' }
PerceptionMissionView >> visibleLossMarkers [
    ^ losses collect: #copy

]
