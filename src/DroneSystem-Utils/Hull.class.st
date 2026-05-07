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

{ #category : 'refactoring hull' }
Hull >> removeFlatShortBendsRatio: ratio [

"Ignore uselees points (too close)"
    | result toRemove |
  ^ self.
  "result := self points asOrderedCollection.
    [
        toRemove := OrderedCollection new.
        2 to: result size - 1 do: [ :i |
            | a b c ab bc angle |
            a := result at: i - 1.
            b := result at: i.
            c := result at: i + 1.
            ab := self distanceBetween: a and: b.
            bc := self distanceBetween: b and:c.
            angle := self turnAngleDegreesAt: b from: a to: c.
            (bc < (ab * ratio) and: [angle <<> 180]) ifTrue: [
                toRemove add: i ] ].
       
        ""On retire les points marqués""
        toRemove do: [ :i | result removeAt: i ].
   toRemove isEmpty  ] whileFalse.
    ^ result"
]

{ #category : 'refactoring hull' }
Hull >> removeNecksOfIndexGap: k [

"Remove necks (close points at logical distance; ie problematic shpes such as internaal  u turns  "
	| n toRemove r |
	n := self points size.
	r := self searchRadius.
	toRemove := Set new.
	1 to: n do: [ :i |
			i + k + 1 to: n do: [ :j |
					(self distanceBetween: (points at: i) and: (points at: j)) < r
						ifTrue: [ i + 1 to: j - 1 do: [ :idx | toRemove add: idx ] ] ] ].
	^ points copyWithoutAll:
		  (toRemove asArray collect: [ :idx | points at: idx ])
]

{ #category : 'refactoring hull' }
Hull >> removeSharpAngles: maxAngle [
	"We set up a max angle value"

	| result toRemove |
	result := self points asOrderedCollection.
	[
		toRemove := OrderedCollection new.
		2 to: result size - 1 do: [ :i |
				| turn |
				turn := self
					        turnAngleDegreesAt: (result at: i)
					        from: (result at: i - 1)
					        to: (result at: i + 1).
				turn > maxAngle | (turn <0) ifTrue: [   toRemove add: i ] ].
 
		toRemove do: [ :i | result removeAt: i ].
		toRemove isEmpty ] whileFalse.
	self points: result
]

{ #category : 'points functions' }
Hull >> searchRadius [

"This is used to prevent goulets by comparing physical vs logical neighbouring"
	^ self totalDistance / self points size * 3
]

{ #category : 'accessing' }
Hull >> size [

	^ self points size
]

{ #category : 'refactoring hull' }
Hull >> smoothAngle: maxAngle rank: k [

	| lastSize |
	[
		lastSize := self points size.
		self removeSharpAngles: maxAngle.
	"	self removeFlatShortBendsRatio: 0.
		2.
		self removeNecksOfIndexGap: 0." "ignore k at first - debug oriented"
		self points size = lastSize ] whileFalse
]

{ #category : 'accessing' }
Hull >> totalDistance [

	^ totalDistance
]

{ #category : 'accessing' }
Hull >> totalDistance: anObject [

	totalDistance := anObject
]

{ #category : 'points functions' }
Hull >> turnAngleDegreesAt: current from: prev to: next [

	| v1 v2 cross dot angle |
	v1 := current longitude - prev longitude
	      @ (current latitude - prev latitude).
	v2 := next longitude - current longitude
	      @ (next latitude - current latitude).
	cross := v1 x * v2 y - (v1 y * v2 x).
	dot := v1 x * v2 x + (v1 y * v2 y).
	angle := cross arcTan: dot.
	^ angle radiansToDegrees abs
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
