Class {
	#name : 'DroneMapWithOWSView',
	#superclass : 'Object',
	#traits : 'TDroneVisualizationWithOWS',
	#classTraits : 'TDroneVisualizationWithOWS classTrait',
	#instVars : [
		'simulation',
		'centerLat',
		'centerLon',
		'zoom',
		'owsMap',
		'rsCanvas'
	],
	#category : 'DroneSystem-Visualization-visualization',
	#package : 'DroneSystem-Visualization',
	#tag : 'visualization'
}

{ #category : 'accessing' }
DroneMapWithOWSView >> centerLat [

	^ centerLat
]

{ #category : 'accessing' }
DroneMapWithOWSView >> centerLat: anObject [

	centerLat := anObject
]

{ #category : 'accessing' }
DroneMapWithOWSView >> centerLon [

	^ centerLon
]

{ #category : 'accessing' }
DroneMapWithOWSView >> centerLon: anObject [

	centerLon := anObject
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeWithSimulation: aSimulation centerLat: lat centerLon: lon zoom: z [
    simulation := aSimulation.
    centerLat := lat.
    centerLon := lon.
    zoom := z.

    "Si PharoOWS est présent, configurer une carte OWS"
    (Smalltalk includesKey: #OWSMapView)
        ifTrue: [
            owsMap := (Smalltalk at: #OWSMapView) new.
            (owsMap respondsTo: #center:) ifTrue: [ owsMap center: lat @ lon ].
            (owsMap respondsTo: #zoom:) ifTrue: [ owsMap zoom: z ].
        ]
        ifFalse: [ owsMap := nil ].

    "Créer un canvas Roassal pour superposer les drones"
    rsCanvas := RSCanvas new.
    rsCanvas extent: 1000@700.

    "Installer le HUD fourni par le trait"
    self initializeHUD.

    ^ self
]

{ #category : 'accessing' }
DroneMapWithOWSView >> owsMap [

	^ owsMap
]

{ #category : 'accessing' }
DroneMapWithOWSView >> owsMap: anObject [

	owsMap := anObject
]

{ #category : 'accessing' }
DroneMapWithOWSView >> rsCanvas [

	^ rsCanvas
]

{ #category : 'accessing' }
DroneMapWithOWSView >> rsCanvas: anObject [

	rsCanvas := anObject
]

{ #category : 'accessing' }
DroneMapWithOWSView >> simulation [

	^ simulation
]

{ #category : 'accessing' }
DroneMapWithOWSView >> simulation: anObject [

	simulation := anObject
]

{ #category : 'accessing' }
DroneMapWithOWSView >> zoom [

	^ zoom
]

{ #category : 'accessing' }
DroneMapWithOWSView >> zoom: anObject [

	zoom := anObject
]
