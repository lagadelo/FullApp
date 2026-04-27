Class {
	#name : 'MissionFactory',
	#superclass : 'Object',
	#instVars : [
		'poi',
		'convexHull',
		'epsilon',
		'maxSpikeAngle',
		'boundingBox',
		'hull',
		'targetCount'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'example' }
MissionFactory class >> example [

	| tmp |
	tmp := self
		       poi:
		       (MacroSimulatorParameters generateRawBrittanyPoints: 100)
		       epsilon: 0.1
		       maxSpikeAngle: 130.
	tmp computeBoundingBox.
	tmp computeConvexHull.
	tmp targetCount: 20.
	tmp computeHull.
	^tmp 
]

{ #category : 'instance creation' }
MissionFactory class >> poi: poi epsilon: epsilon maxSpikeAngle: maxSpikeAngle [

	^ self new
		  poi: poi;
		  epsilon: epsilon;
		  maxSpikeAngle: maxSpikeAngle;
		  yourself
]

{ #category : 'accessing' }
MissionFactory >> boundingBox [

	boundingBox ifNil: [ self computeBoundingBox ].
	^ boundingBox
]

{ #category : 'accessing' }
MissionFactory >> boundingBox: anObject [

	boundingBox := anObject
]

{ #category : 'setter' }
MissionFactory >> computeBoundingBox [

	| latitudes longitudes |
	latitudes := (self poi collect: [ :a | a latitude ])
		             asSortedCollection.

	longitudes := (self poi collect: [ :a | a longitude ]) asSortedCollection.

	^ self boundingBox: (longitudes first @ latitudes first corner:
			   longitudes last @ latitudes last)
]

{ #category : 'setter' }
MissionFactory >> computeConvexHull [

	| sorted cross lower upper |
	sorted := self poi asSortedCollection: [ :a :b |
			          a longitude ~= b longitude
				          ifTrue: [ a longitude < b longitude ]
				          ifFalse: [ a latitude < b latitude ] ].

	cross := [ :o :a :b |
		         a longitude - o longitude * (b latitude - o latitude)
		         - (a latitude - o latitude * (b longitude - o longitude)) ].

	lower := OrderedCollection new.
	sorted do: [ :point |
			[
				lower size >= 2 and: [
						(cross
							 value: (lower at: lower size - 1)
							 value: (lower at: lower size)
							 value: point) <= 0 ] ] whileTrue: [ lower removeLast ].
			lower add: point ].

	upper := OrderedCollection new.
	sorted reverseDo: [ :point |
			[
				upper size >= 2 and: [
						(cross
							 value: (upper at: upper size - 1)
							 value: (upper at: upper size)
							 value: point) <= 0 ] ] whileTrue: [ upper removeLast ].
			upper add: point ].

	self convexHull:
		(lower , (upper copyFrom: 2 to: (upper size - 1 max: 1)) collect: [
				 :p |
				 GeoPoint
					 latitude: (p latitude truncateTo: 0.001)
					 longitude: (p longitude truncateTo: 0.001)
					 altitude: p altitude ])
]

{ #category : 'setter' }
MissionFactory >> computeHull [

	| adjustedTarget low high mid result bestResult |
	adjustedTarget := self targetCount + self spikeBuffer.

	(self convexHullRouteFromRawPoints: self poi epsilon: 0) size
	>= adjustedTarget ifTrue: [
		^ self convexHullRouteFromRawPoints: self poi epsilon: 0 ].

	low := 0.0.
	high := 1.0.
	bestResult := self convexHullRouteFromRawPoints: self poi epsilon: 0.

	20 timesRepeat: [
			mid := low + high / 2.0.
			result := self convexHullRouteFromRawPoints: self poi epsilon: mid.
			result size = adjustedTarget ifTrue: [ ^ self hull: result ].
			result size > adjustedTarget
				ifTrue: [ high := mid ]
				ifFalse: [
						low := mid.
						result size > bestResult size ifTrue: [ bestResult := result ] ] ].

	^ self hull: bestResult
]

{ #category : 'accessing' }
MissionFactory >> convexHull [

	^ convexHull
]

{ #category : 'accessing' }
MissionFactory >> convexHull: anObject [

	convexHull := anObject
]

{ #category : 'facilities' }
MissionFactory >> convexHullRouteFromRawPoints: points epsilon: ep [
	"epsilon=0 → hull strict. epsilon>0 → hull relâché (garde plus de points).
     epsilon est en degrés² (produit vectoriel lon/lat).
     Typiquement: 0=strict, 0.0001=léger, 0.001=relâché, 0.01=très relâché."

	| sorted cross lower upper seen result |
	sorted := points asSortedCollection: [ :a :b |
			          a longitude ~= b longitude
				          ifTrue: [ a longitude < b longitude ]
				          ifFalse: [ a latitude < b latitude ] ].

	cross := [ :o :a :b |
		         a longitude - o longitude * (b latitude - o latitude)
		         - (a latitude - o latitude * (b longitude - o longitude)) ].

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

	^ result collect: [ :p |
			  GeoPoint
				  latitude: (p latitude truncateTo: 0.001)
				  longitude: (p longitude truncateTo: 0.001)
				  altitude: p altitude ]
]

{ #category : 'computing' }
MissionFactory >> convexHullRouteWithRatio: aRatio [

	self assert: aRatio < 1.
	self targetCount: self poi size.
	self computeHull.
	self targetCount: self hull size * aRatio.
	self computeHull
]

{ #category : 'accessing' }
MissionFactory >> epsilon [

	^ epsilon
]

{ #category : 'accessing' }
MissionFactory >> epsilon: anObject [

	epsilon := anObject
]

{ #category : 'accessing' }
MissionFactory >> hull [

	^ hull
]

{ #category : 'accessing' }
MissionFactory >> hull: anObject [

	hull := anObject
]

{ #category : 'accessing' }
MissionFactory >> maxSpikeAngle [

	^ maxSpikeAngle
]

{ #category : 'accessing' }
MissionFactory >> maxSpikeAngle: anObject [

	maxSpikeAngle := anObject
]

{ #category : 'accessing' }
MissionFactory >> poi [

	^ poi
]

{ #category : 'accessing' }
MissionFactory >> poi: anObject [

	poi := anObject
]

{ #category : 'setter' }
MissionFactory >> smoothHull [

	| result tmp toRemove |
	tmp := self
		        convexHullRoute asOrderedCollection.

	[
		toRemove := OrderedCollection new.
		2 to: tmp size - 1 do: [ :i |
				| turn |
				turn := self
					        turnAngleDegreesAt: (tmp at: i)
					        from: (tmp at: i - 1)
					        to: (tmp at: i + 1).
				turn > self maxSpikeAngle ifTrue: [ toRemove add: i ] ].

		result := OrderedCollection new.
		tmp keysAndValuesDo: [ :i :p |
			(toRemove includes: i) ifFalse: [ result add: p ] ].
		tmp := result.
		toRemove notEmpty ] whileTrue.

	self hull: result
]

{ #category : 'facilities' }
MissionFactory >> spikeBuffer [
    "Estime le nombre de points supprimés par maxSpikeAngle."
    self maxSpikeAngle >= 160 ifTrue: [ ^ 1 ].
    self maxSpikeAngle >= 140 ifTrue: [ ^ 2 ].
    self maxSpikeAngle >= 120 ifTrue: [ ^ 4 ].
    self maxSpikeAngle >= 100 ifTrue: [ ^ 6 ].
    ^ 8
]

{ #category : 'accessing' }
MissionFactory >> targetCount [

	targetCount ifNil: [ targetCount := 0 ].
	^ targetCount
]

{ #category : 'accessing' }
MissionFactory >> targetCount: anObject [

	targetCount := anObject
]
