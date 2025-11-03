Class {
	#name : 'Trajectory',
	#superclass : 'Object',
	#instVars : [
		'geoPoints'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'shapes - ordering' }
Trajectory >> asHull [

	^ ConvexHullCalculator new hullForGeoPoints: self geoPoints
]

{ #category : 'shapes - ordering' }
Trajectory >> asPolygon [

	^ Polygon vertices: self asHull
]

{ #category : 'shapes - ordering' }
Trajectory >> beHull [

	^ self geoPoints: self asHull
]

{ #category : 'shapes - ordering' }
Trajectory >> bePolygon [

	^ self geoPoints: self asPolygon
]

{ #category : 'shapes - ordering' }
Trajectory >> fromEastToWest [

	self geoPoints:
		(self geoPoints sortBlock: [ :a :b | a  longitude > b longitude ])
			asOrderedCollection
]

{ #category : 'shapes - ordering' }
Trajectory >> fromNorthToSouth [

	self geoPoints:
		(self geoPoints sortBlock: [ :a :b | a  latitude > b latitude ])
			asOrderedCollection
]

{ #category : 'shapes - ordering' }
Trajectory >> fromSouthToNorth [

	self geoPoints:
		(self geoPoints sortBlock: [ :a :b | a  latitude < b latitude ])
			asOrderedCollection
]

{ #category : 'shapes - ordering' }
Trajectory >> fromWestToEast [

	self geoPoints:
		(self geoPoints sortBlock: [ :a :b | a longitude < b longitude ])
			asOrderedCollection
]

{ #category : 'accessing' }
Trajectory >> geoPoints [

	^ geoPoints
]

{ #category : 'accessing' }
Trajectory >> geoPoints: anObject [

	geoPoints := anObject
]

{ #category : 'points accesing' }
Trajectory >> howManyPoints [

	^ self geoPoints size
]

{ #category : 'points accesing' }
Trajectory >> indexOfPoint: aPoint [

	^self geoPoints indexOf: aPoint
]

{ #category : 'points accesing' }
Trajectory >> pointAfter: aPoint [

	| tmp |
	tmp := self indexOfPoint: aPoint.
	^ tmp = self geoPoints size
		  ifTrue: [ nil ]
		  ifFalse: [ self pointAt: tmp + 1 ]
]

{ #category : 'points accesing' }
Trajectory >> pointAfter: aPoint circular: aBoolean [

	^ aBoolean
		  ifFalse: [ self pointAfter: Point ]
		  ifTrue: [
		  self pointAt:
			  (self indexOfPoint: aPoint) + 1 // self howManyPoints ]
]

{ #category : 'points accesing' }
Trajectory >> pointAt: anIndex [

	^self geoPoints at: anIndex
]
