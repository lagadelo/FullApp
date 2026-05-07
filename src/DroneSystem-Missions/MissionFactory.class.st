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
		'targetCount',
		'pointsRatio',
		'perimeterRatio',
		'hullPolicy'
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

	self convexHull: (Hull with: self poi epsilon: 0)
]

{ #category : 'setter' }
MissionFactory >> computeHull [

	^ self computeHull: self hullPolicy
]

{ #category : 'setter' }
MissionFactory >> computeHull: aPolicy [

self assert: ((Array with: #targetCount with: #pointsRatio with: #perimeterRation) includes: aPolicy). 
	aPolicy = #targetCount ifTrue: [
		 self computeHullByTargetCount: self targetCount ].
	aPolicy= #pointsRatio ifTrue: [
		 self computeHullByPointRatio: self pointsRatio ].
	aPolicy = #perimeterRatio ifTrue: [
		 self computeHullByPerimeterRatio:  self perimeterRatio ].
	self smoothHull 
]

{ #category : 'setter' }
MissionFactory >> computeHullByPerimeterRatio: aPerimeterRatio [

	| strictHull strictPerimeter targetPerimeter low high mid result bestResult ignoreThreshold |
	self assert: aPerimeterRatio >= 1.
	"Hull strict = référence"
	strictHull := Hull with: self poi epsilon: 0.
	strictHull compute.

	strictPerimeter := strictHull totalDistance.
	targetPerimeter := strictPerimeter * aPerimeterRatio.
	ignoreThreshold := targetPerimeter /100.



	low := 0.0.
	high := 1.0.
	bestResult := strictHull.

	20 timesRepeat: [
			| p |
			mid := low + high / 2.0.
			result := Hull with: self poi epsilon: mid.
			result compute.
			p := result totalDistance.
			(p - targetPerimeter) abs < ignoreThreshold ifTrue: [ "< 500m de tolérance"
					self hull: result.
					^ self smoothHull ].
			p < targetPerimeter
				ifTrue: [ low := mid. (targetPerimeter - p ) abs < (bestResult totalDistance - targetPerimeter) abs ifTrue: [
							bestResult := result ] ]
				ifFalse: [
						high := mid.
						 ] .
					
					"(targetPerimeter - p ) abs < (bestResult totalDistance - targetPerimeter) abs ifTrue: [
							bestResult := result ]"].

	self hull: bestResult.
	
]

{ #category : 'setter' }
MissionFactory >> computeHullByPointRatio: pointRatio [
	"pointRatio: 
	<1 would mean to ignore some convex hull points ie: getting points outside os the hull.
	=1 does nothing
	>1 accept relaxing hull, ie supporting non convex shapes"
	 

	self assert: pointRatio > 1.

	^ self computeHullByTargetCount:
		  (((Hull with: self poi epsilon: 0) points size * pointRatio)
			   rounded max: 3)
]

{ #category : 'setter' }
MissionFactory >> computeHullByTargetCount: aTargetCount [

	| adjustedTarget low high mid result bestResult |
	adjustedTarget := aTargetCount   + self spikeBuffer.

	bestResult := Hull with: self poi epsilon: 0.
	bestResult compute.
	bestResult points size >= adjustedTarget ifTrue: [
			self hull: bestResult.
			^ self smoothHull ].

	low := 0.0.
	high := 1.0.

	20 timesRepeat: [
			mid := low + high / 2.0.
			result := Hull with: self poi epsilon: mid.
			result compute.
			result points size = adjustedTarget ifTrue: [
					self hull: result.
					^ self smoothHull ].
			result points size > adjustedTarget
				ifTrue: [ high := mid ]
				ifFalse: [
						low := mid.
						result points size > bestResult points size ifTrue: [
							bestResult := result ] ] ].

	self hull: bestResult. 
 
]

{ #category : 'accessing' }
MissionFactory >> convexHull [

	^ convexHull
]

{ #category : 'accessing' }
MissionFactory >> convexHull: anObject [

	convexHull := anObject
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

{ #category : 'policy' }
MissionFactory >> hullPolicy [
    ^ hullPolicy ifNil: [ #pointsRatio ]
    "ou #targetCount"
]

{ #category : 'policy' }
MissionFactory >> hullPolicy: aPolicy [

	self assert:
		(aPolicy in: { #perimeterRatio. #pointsRatio. #targetPoints }).
	hullPolicy := aPolicy
]

{ #category : 'initialize' }
MissionFactory >> initialize [

	super initialize.
	maxSpikeAngle := 130. "Max bound for internal angles"
	pointsRatio := 3. "expand by +200% the # points vs pure   convex hull"
	perimeterRatio := 2. "accept a *2 length vs convex hull perimeter"
	targetCount := 20 "targets keeping +- 20 points"
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
MissionFactory >> perimeterRatio [

	^ perimeterRatio
]

{ #category : 'accessing' }
MissionFactory >> perimeterRatio: anObject [

	perimeterRatio := anObject
]

{ #category : 'accessing' }
MissionFactory >> poi [

	^ poi
]

{ #category : 'accessing' }
MissionFactory >> poi: anObject [

	poi := anObject
]

{ #category : 'accessing' }
MissionFactory >> pointsRatio [

	^ pointsRatio
]

{ #category : 'accessing' }
MissionFactory >> pointsRatio: anObject [

	pointsRatio := anObject
]

{ #category : 'setter' }
MissionFactory >> smoothHull [


	| result tmp toRemove |
	tmp := self hull points.
	
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
			(toRemove includes: i) ifFalse: [ result add: p ] ]. self halt. 
		tmp := result.
		toRemove notEmpty ] whileTrue.

	self halt. "self   hull: (Hull with:result epsilon:1). "   "keep all points, 1 is an impossidble value hence ensure noto alter the hull still using the common API"
	self hull: Hull new.
	self hull points: result.
	self hull compute
]

{ #category : 'setter' }
MissionFactory >> smoothHullLegacy [


	| result tmp toRemove |
	tmp := self hull points.
	
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
			(toRemove includes: i) ifFalse: [ result add: p ] ]. self halt. 
		tmp := result.
		toRemove notEmpty ] whileTrue.

	self halt. "self   hull: (Hull with:result epsilon:1). "   "keep all points, 1 is an impossidble value hence ensure noto alter the hull still using the common API"
	self hull: Hull new.
	self hull points: result.
	self hull compute
]

{ #category : 'setter' }
MissionFactory >> smoothHullNew [
self hull smoothAngle: self maxSpikeAngle rank: 10
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

{ #category : 'facilities' }
MissionFactory >> turnAngleDegreesAt: current from: prev to: next [

"self error:'shoiuld use the Hull method instead'.
	"| v1 v2 cross dot angle |
	v1 := current longitude - prev longitude
	      @ (current latitude - prev latitude).
	v2 := next longitude - current longitude
	      @ (next latitude - current latitude).
	cross := v1 x * v2 y - (v1 y * v2 x).
	dot := v1 x * v2 x + (v1 y * v2 y).
	angle := cross arcTan: dot.
	^ angle radiansToDegrees abs
]
