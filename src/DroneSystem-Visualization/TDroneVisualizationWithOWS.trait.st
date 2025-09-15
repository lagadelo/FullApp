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
		'infoText'
	],
	#category : 'DroneSystem-Visualization',
	#package : 'DroneSystem-Visualization'
}

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

{ #category : 'initialization' }
TDroneVisualizationWithOWS >> renderDrones [
    "Affiche tous les drones de la simulation."
    self renderDronesWith: simulation allDrones.

]

{ #category : 'initialization' }
TDroneVisualizationWithOWS >> renderDronesWith: droneCollection [
    "Affiche une collection de drones sur la carte et le canvas."
    rsCanvas shapes do: [:s | (s isKindOf: RSBox) ifTrue: [ rsCanvas remove: s ]].
    droneCollection do: [:d |
        | color dot |
        color := d isHostile ifTrue: [ Color red ] ifFalse: [ Color green ].
        dot := RSBox new
            size: 8@8;
            color: color;
            yourself.
        rsCanvas add: dot.
        dot translateTo: (d longitude * 5) @ (d latitude * -5). "Projection simplifiée"
    ].
    rsCanvas signalUpdate.
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
