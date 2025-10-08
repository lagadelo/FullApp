Trait {
	#name : 'TDroneVisualizationWithOWS',
	#instVars : [
		'simulation',
		'rsCanvas',
		'owsMap',
		'centerLat',
		'centerLon',
		'timeSlider',
		'fleetSelector',
		'infoText',
		'overlayModel'
	],
	#category : 'DroneSystem-Visualization',
	#package : 'DroneSystem-Visualization'
}

{ #category : 'reseting' }
TDroneVisualizationWithOWS >> drawPerceptionRadiiOn: aCanvas [
         | gp r |
   (simulation respondsTo: #drones) ifFalse: [ ^ self ].
    simulation drones do: [ :d |
        (d respondsTo: #position) ifFalse: [ ^ self ].

        gp := self graphicalPositionOf: d position.
        r := (d respondsTo: #detectionRange) ifTrue: [ d detectionRange ] ifFalse: [ 0 ].
        (r isNil or: [ r <= 0 ]) ifFalse: [
            aCanvas
                ellipseCenter: gp
                radius: r * (self respondsTo: #scaleFactor ifTrue: [ self scaleFactor ] ifFalse: [ 1 ])
                color: (Color lightBlue alpha: 0.2) ] ]
]

{ #category : 'initialization' }
TDroneVisualizationWithOWS >> initializeWithSimulation: aSimulation centerLat: lat centerLon: lon zoom: z [
    simulation := aSimulation.
    centerLat := lat.
    centerLon := lon.
    zoom := z.

    (Smalltalk includesKey: #OWSMapView)
        ifTrue: [
            owsMap := (Smalltalk at: #OWSMapView) new.
            (owsMap respondsTo: #center:) ifTrue: [ owsMap center: lat @ lon ].
            (owsMap respondsTo: #zoom:) ifTrue: [ owsMap zoom: z ].
        ]
        ifFalse: [ owsMap := nil ].

    rsCanvas := RSCanvas new.
    rsCanvas extent: 1000@700.

    "Méthodes fournies par le trait"
    self initializeHUD.

    ^ self

]

{ #category : 'reseting' }
TDroneVisualizationWithOWS >> rebuildOverlayShapes [
    | c |
    c := self canvas ifNil: [ ^ self ].
    self removeExistingOverlayShapesFrom: c.
    overlayModel ifNil: [ ^ self ].
    overlayModel showPerceptionRadius ifTrue: [ self addPerceptionRadiusShapesTo: c ].
    overlayModel showMissionPaths ifTrue: [ self addMissionPathShapesTo: c ].
    overlayModel showEnergyBars ifTrue: [ self addEnergyBarShapesTo: c ].
    overlayModel showAmmoBars ifTrue: [ self addAmmoBarShapesTo: c ].
    overlayModel showClusterHull ifTrue: [ self addClusterHullShapesTo: c ].
    c signalUpdate  "Redessine"
]

{ #category : 'reseting' }
TDroneVisualizationWithOWS >> refreshOverlay [
    self rebuildOverlayShapes
]

{ #category : 'reseting' }
TDroneVisualizationWithOWS >> removeExistingOverlayShapesFrom: aCanvas [
    "Suppression des anciennes formes marquées overlay"
    (aCanvas shapes copy) do: [ :s |
        ((s respondsTo: #attributeAt:ifAbsent:) and: [
            (s attributeAt: #overlay ifAbsent: [ false ]) = true ])
            ifTrue: [ aCanvas remove: s ] ]
]

{ #category : 'initialization' }
TDroneVisualizationWithOWS >> saveCanvasAsImage [
    "Sauvegarde le canvas en tant qu'image PNG."
    | file |
    file := FileLocator imageDirectory / 'simulation_canvas.png'.
    (RSExporter new png: rsCanvas) writeOn: file.
    Transcript show: 'Canvas saved to ', file fullName; cr.
]

{ #category : 'initialization' }
TDroneVisualizationWithOWS >> saveSimulationToCSV [
    "Exporte un état de la simulation en CSV."
    | file |
    file := FileStream fileNamed: 'simulation_export.csv'.
    file nextPutAll: 'id,type,lat,lon,alt,energy', String cr.
    simulation allDrones do: [:d |
        file
            nextPutAll: d uniqueId; nextPut: $,;
            nextPutAll: (d isHostile ifTrue: ['hostile'] ifFalse: ['ally']); nextPut: $,;
            nextPutAll: d latitude asString; nextPut: $,;
            nextPutAll: d longitude asString; nextPut: $,;
            nextPutAll: d altitude asString; nextPut: $,;
            nextPutAll: d energy asString; cr ].
    file close.
    Transcript show: 'Simulation exported to simulation_export.csv'; cr.

]

{ #category : 'initialization' }
TDroneVisualizationWithOWS >> updateAtStep: step [
    "Met à jour la simulation et l'affichage à l'instant donné."
    simulation stepAt: step.
    self renderDrones.
    infoText text: 'Time step: ', step asString, ' | Active fleets: ', simulation allFleets size asString.

]

{ #category : 'initialization' }
TDroneVisualizationWithOWS >> updateFleetFilter: choice [
    "Change le filtre d’affichage des drones selon la flotte choisie."
    choice = 'All Fleets' ifTrue: [
        self renderDronesWith: simulation allDrones ].
    choice = 'Allies' ifTrue: [
        self renderDronesWith: simulation allAlliedDrones ].
    choice = 'Hostiles' ifTrue: [
        self renderDronesWith: simulation allHostileDrones ].

]
