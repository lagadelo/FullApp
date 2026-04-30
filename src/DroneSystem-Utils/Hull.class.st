Class {
	#name : 'Hull',
	#superclass : 'Object',
	#instVars : [
		'points',
		'totalDistance',
		'distanceFromOrigin'
	],
	#category : 'DroneSystem-Utils',
	#package : 'DroneSystem-Utils'
}

{ #category : 'examples' }
Hull class >> with: somePoints epsilon: ep [

	^ self new with: somePoints epsilon: ep
]

{ #category : 'accessing' }
Hull >> at: index [

	^ self points at: index
]

{ #category : 'computing' }
Hull >> compute [

	| d |
	d := OrderedCollection new.
	d add: 0.
self distanceFromOrigin at: self points first put: d last.

	2 to: self points size do: [ :i |
			| previous current |
			current := self points at: i.
			previous := self points at: i - 1.
			d add: d last + (previous haversineMetersTo: current).
			self distanceFromOrigin at: current put: d last ].
	"Then total distance as this is mandatory to compute ratios"
	self totalDistance: d last
	                 +
	                 (self points last haversineMetersTo:
		                  self points first)
]

{ #category : 'points functions' }
Hull >> distanceBetween: aPoint and: anotherPoint [

	^ aPoint haversineMetersTo: anotherPoint
]

{ #category : 'accessing' }
Hull >> distanceFromOrigin [

	^ distanceFromOrigin
]

{ #category : 'points functions' }
Hull >> findDistanceFromPoint: aPoint [

	^ (1 to: self points size)
		  detect: [ :i |
				  | start end |
				  start := self points at: i.
				  end := self points at: i \\ self points size + 1.

				  (LineSegment from: start to: aPoint) length
				  / (LineSegment from: start to: end) length ]
		  ifNone: [ self error: 'Point is not part of the hull' ]
]

{ #category : 'initialize' }
Hull >> initialize [

	super initialize.

	distanceFromOrigin := Dictionary new
]

{ #category : 'points functions' }
Hull >> locatePointFromDistance: aDistance [

	| tmp ratio distances startIndex start stop distanceFromStartPoint |
	"Ignore multiple rounds"
	tmp := aDistance \\ self totalDistance.


	"start point index"
	distances := (2 to: points size) collect: [ :a |
		             self distanceFromOrigin at: a ].
	distances add: self totalDistance.
	startIndex := distances index detect: [ :i | (distances at: i) > tmp ].




	start := points at: startIndex.
	stop := points at: start \\ points size + 1.

	distanceFromStartPoint := tmp - (self distanceFromOrigin at: start).

	ratio := distanceFromStartPoint
	         / (self distanceBetween: start and: stop).

"	^ start moveTo: stop ratio: ratio" (LineSegment from: start to: stop) valueAt: ratio
]

{ #category : 'accessing' }
Hull >> points [

	^ points
]

{ #category : 'accessing' }
Hull >> points: anObject [

	points := anObject
]

{ #category : 'accessing' }
Hull >> size [

	^ self points size
]

{ #category : 'accessing' }
Hull >> totalDistance [

	^ totalDistance
]

{ #category : 'accessing' }
Hull >> totalDistance: anObject [

	totalDistance := anObject
]

{ #category : 'examples' }
Hull >> with: somePoints epsilon: ep [
	"epsilon=0 → hull strict. epsilon>0 → hull relâché (garde plus de points).
     epsilon est en degrés² (produit vectoriel lon/lat).
     Typiquement: 0=strict, 0.0001=léger, 0.001=relâché, 0.01=très relâché."

	| sorted cross lower upper seen result |
	sorted := somePoints asSortedCollection: [ :a :b |
			          a longitude ~= b longitude
				          ifTrue: [ a longitude < b longitude ]
				          ifFalse: [ a latitude < b latitude ] ].

	cross := [ :o :a :b |
		         (a longitude - o longitude) * (b latitude - o latitude)
		         - ((a latitude - o latitude) * (b longitude - o longitude)) ].

	lower := OrderedCollection new.
	sorted do: [ :point |
			[
				lower size >= 2 and: [
						(cross
							 value: (lower at: lower size - 1)
							 value: lower last
							 value: point) <= ep negated ] ] whileTrue: [ lower removeLast ].
			lower add: point ].

	upper := OrderedCollection new.
	sorted reverseDo: [ :point |
			[
				upper size >= 2 and: [
						(cross
							 value: (upper at: upper size - 1)
							 value: upper last
							 value: point) <= ep negated ] ] whileTrue: [
				upper removeLast ].
			upper add: point ].

	upper removeFirst.
	upper removeLast.

	seen := Set new.
	result := OrderedCollection new.
	lower , upper do: [ :p |
			| key |
			key := p longitude @ p latitude.
			(seen includes: key) ifFalse: [
					seen add: key.
					result add: p ] ].

	^   self points: (result collect: [ :p |
			  GeoPoint
				  latitude: (p latitude truncateTo: 0.001)
				  longitude: (p longitude truncateTo: 0.001)
				  altitude: p altitude ])
]
