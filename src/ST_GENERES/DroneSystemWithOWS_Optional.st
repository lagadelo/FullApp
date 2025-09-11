"=========================================================="
"   Drone System With Optional PharoOWS (Pharo 13)         "
"=========================================================="

Trait named: #TDroneVisualizationWithOWS
    uses: { #TDroneDrawing . #TClusterDrawing . #TInteractiveDrones . #TRealTimeUpdate }
    category: 'Drones-Visualization-OWS'.

TDroneVisualizationWithOWS>>projectLat: lat lon: lon
    "Essai d’utiliser PharoOWS si dispo, sinon fallback projection simple"
    (owsMap notNil) ifTrue: [
        (owsMap respondsTo: #worldToScreen:) ifTrue: [ ^ owsMap worldToScreen: (lat@lon) ].
        (owsMap respondsTo: #latLonToScreen:) ifTrue: [ ^ owsMap latLonToScreen: lat@lon ].
        (owsMap respondsTo: #latLonToScreenPoint:) ifTrue: [ ^ owsMap latLonToScreenPoint: lat@lon ].
        (owsMap respondsTo: #toScreen:) ifTrue: [ ^ owsMap toScreen: (lat@lon) ].
    ].

    "Fallback si aucune API PharoOWS dispo"
    | cx cy scale x y |
    cx := centerLon ifNil: [ 0 ].
    cy := centerLat ifNil: [ 0 ].
    scale := 10000. "A ajuster selon zoom / dimension"
    x := (lon - cx) * scale.
    y := ((lat - cy) * scale) negated.
    ^ x @ y.


Object subclass: #DroneMapWithOWSView
    instanceVariableNames: 'simulation centerLat centerLon zoom owsMap'
    classVariableNames: ''
    package: 'Drones-Visualization-OWS'.

DroneMapWithOWSView>>initializeWithSimulation: aSim centerLat: lat centerLon: lon zoom: z
    simulation := aSim.
    centerLat := lat.
    centerLon := lon.
    zoom := z.
    (Smalltalk includesKey: #OWSMapView)
        ifTrue: [
            owsMap := (Smalltalk at: #OWSMapView) new.
            (owsMap respondsTo: #center:) ifTrue: [ owsMap center: lat@lon ].
            (owsMap respondsTo: #zoom:) ifTrue: [ owsMap zoom: z ].
        ]
        ifFalse: [
            owsMap := nil.
        ].

DroneMapWithOWSView>>buildRoassalView
    | view |
    view := RSCanvas new.
    "Ici tu ajoutes la visualisation Roassal de tes drones/clusters"
    simulation drones do: [:d |
        | pt |
        pt := self projectLat: d latitude lon: d longitude.
        view add: (RSEllipse new
            size: 10;
            color: Color red;
            translateTo: pt).
    ].
    ^ view.

DroneMapWithOWSView>>open
    (owsMap notNil)
        ifTrue: [
            "Si PharoOWS présent, intégrer la vue Roassal comme overlay"
            (owsMap respondsTo: #openWithRoassalOverlay:) 
                ifTrue: [ ^ owsMap openWithRoassalOverlay: self buildRoassalView ].
            ^ owsMap open. "fallback si pas d’API overlay"
        ]
        ifFalse: [
            ^ (self buildRoassalView) open
        ].

"=========================================================="
"   Fin du fichier                                         "
"=========================================================="
