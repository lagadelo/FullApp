Class {
	#name : 'IDroneMapWithOWSView',
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
	#category : 'DroneSystem-Visualization',
	#package : 'DroneSystem-Visualization'
}

{ #category : 'accessing' }
IDroneMapWithOWSView >> centerLat [

	^ centerLat
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> centerLat: anObject [

	centerLat := anObject
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> centerLon [

	^ centerLon
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> centerLon: anObject [

	centerLon := anObject
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> owsMap [

	^ owsMap
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> owsMap: anObject [

	owsMap := anObject
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> rsCanvas [

	^ rsCanvas
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> rsCanvas: anObject [

	rsCanvas := anObject
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> simulation [

	^ simulation
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> simulation: anObject [

	simulation := anObject
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> updateDelay [

	^ updateDelay
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> updateDelay: anObject [

	updateDelay := anObject
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> zoom [

	^ zoom
]

{ #category : 'accessing' }
IDroneMapWithOWSView >> zoom: anObject [

	zoom := anObject
]
