Class {
	#name : 'DroneMapWithOWSView',
	#superclass : 'Object',
	#instVars : [
		'simulation',
		'owsMap',
		'rsCanvas',
		'trait',
		'centerLat',
		'centerLon',
		'zoom'
	],
	#category : 'DroneSystem-Visualization',
	#package : 'DroneSystem-Visualization'
}

{ #category : 'initialization' }
DroneMapWithOWSView >> >open [
    owsMap ifNotNil: [ (owsMap respondsTo: #open) ifTrue: [ owsMap open ] ].
    rsCanvas open.
    trait startUpdatingEvery: 1000.
    ^ self.

]

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
    (Smalltalk includesKey: #OWSMapView) ifTrue: [
        owsMap := (Smalltalk at: #OWSMapView) new.
        (owsMap respondsTo: #center:) ifTrue: [ owsMap center: lat@lon ].
        (owsMap respondsTo: #zoom:) ifTrue: [ owsMap zoom: z ].
    ] ifFalse: [ owsMap := nil ].
    rsCanvas := RSCanvas new.
    rsCanvas extent: 1000@700.
    trait := (TDroneVisualizationWithOWS new).
    trait simulation: simulation.
    trait rsCanvas: rsCanvas.
    trait owsMap: owsMap.
    trait centerLat: centerLat.
    trait centerLon: centerLon.
    trait initializeHUD.
    ^ self.


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
DroneMapWithOWSView >> trait [

	^ trait
]

{ #category : 'accessing' }
DroneMapWithOWSView >> trait: anObject [

	trait := anObject
]

{ #category : 'accessing' }
DroneMapWithOWSView >> zoom [

	^ zoom
]

{ #category : 'accessing' }
DroneMapWithOWSView >> zoom: anObject [

	zoom := anObject
]
