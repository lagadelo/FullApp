Class {
	#name : 'SoSeAtelierMapPlan',
	#superclass : 'Object',
	#instVars : [ 'waypoints', 'bounds', 'convexHull' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierMapPlan class >> fromJSON: dictionary [
	^ self
		waypoints: (dictionary at: 'waypoints')
		bounds: (dictionary at: 'bounds' ifAbsent: [ nil ])
		convexHull: (dictionary at: 'convexHull' ifAbsent: [ false ])
]

{ #category : 'instance creation' }
SoSeAtelierMapPlan class >> waypoints: coordinates bounds: extent convexHull: useHull [
	^ self new initializeWaypoints: coordinates bounds: extent convexHull: useHull
]

{ #category : 'initialization' }
SoSeAtelierMapPlan >> initializeWaypoints: coordinates bounds: extent convexHull: useHull [
	(coordinates isArray and: [ (coordinates allSatisfy: [ :pair | self validPair: pair ])
		and: [ #(true false) includes: useHull ] ])
		ifFalse: [ self error: 'Le tracé attend des paires [longitude, latitude] WGS84.' ].
	extent ifNotNil: [
		(extent isArray and: [ extent size = 4 and: [
			(self validPair: { extent first. extent second }) and: [
				(self validPair: { extent third. extent fourth }) and: [
					extent first < extent third and: [ extent second < extent fourth ] ] ] ] ])
			ifFalse: [ self error: 'L’emprise doit être un rectangle WGS84 de surface positive.' ] ].
	waypoints := coordinates collect: #copy.
	bounds := extent ifNotNil: [ extent copy ].
	convexHull := useHull
]

{ #category : 'validation' }
SoSeAtelierMapPlan >> validPair: pair [
	^ pair isArray and: [ pair size = 2 and: [
		(pair allSatisfy: [ :coordinate | coordinate isNumber and: [ coordinate asFloat isFinite ] ]) and: [
			(pair first between: -180 and: 180) and: [ pair second between: -90 and: 90 ] ] ] ]
]

{ #category : 'accessing' }
SoSeAtelierMapPlan >> bounds [ ^ bounds ifNotNil: [ bounds copy ] ]

{ #category : 'accessing' }
SoSeAtelierMapPlan >> convexHull [ ^ convexHull ]

{ #category : 'accessing' }
SoSeAtelierMapPlan >> geoPoints [
	^ waypoints collect: [ :pair | GeoPoint latitude: pair second longitude: pair first altitude: 0 ]
]

{ #category : 'serializing' }
SoSeAtelierMapPlan >> asJSON [
	^ { 'waypoints' -> (waypoints collect: #copy). 'bounds' -> self bounds.
		'convexHull' -> convexHull } asDictionary
]
