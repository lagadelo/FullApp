Class {
	#name : 'SecurizationMission',
	#superclass : 'ZoneBasedMission',
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'visiting' }
SecurizationMission >> accept: aVisitor [

^aVisitor visitSecurizationMission: self 
]

{ #category : 'characterization' }
SecurizationMission >> assignment [

	| drones |
	drones := self model allDrones.
	1 to: polygon size do: [ :i | drones at: i put: (polygon at: i) ].
	
]

{ #category : 'characterization' }
SecurizationMission >> computePositions [

	| p nb sort howMany tmp |
	self wayPoints: self polygon.
	p := wayPoints size.
	"how many additional waypoints do i need"
	nb := p < self drones size
		      ifTrue: [ self drones size - p ]
		      ifFalse: [ p \\ self drones size ].



	" I want to split the longuest edges"
	sort := SortedCollection sortBlock: [ :i :j |
			        ((self wayPoints at: i) distanceTo:
				         (self wayPoints at: i % p + 1))
			        <
			        ((self wayPoints at: j) distanceTo:
				         (self wayPoints at: j % p + 1)) ].

	"I add an extra point in the middle of the proper edges"
	[ nb = 0 ] whileFalse: [
			sort addAll: (1 to: wayPoints size).
			"how many point to be added at thi turn"
			howMany := nb min: p.
			tmp := OrderedCollection new.
			1 to: howMany do: [ :a |
				tmp add: (self wayPoints at: a) + (self wayPoints at: a % p + 1) / 2 ].
			"forget sort as this should be recomputed based on the several new points."
			sort removeAll.
			nb := nb - howMany.
			tmp addAll: wayPoints.
			"I ensure I have a convex hull"
			self wayPoints: (ConvexHullCalculator new hullForGeoPoints: tmp) ]
]

{ #category : 'characterization' }
SecurizationMission >> events [
	| drones tmp ratio |
	self computePositions. 
	tmp := OrderedCollection new.
	" should consider already placed drones on the polygon to prevent extra reoganization"
	drones := self model drones.
 
	ratio := (wayPoints size/ drones size).
	
	1 to: drones size  do:   [ :i | tmp add: (MoveStepEvent 
		      drone: (drones at: i)
		       wayPoint: (wayPoints at: 1 + ((i-1)* ratio)) speed:20000 / 3600 "20km/h"  ). ].
 
	^tmp 
]

{ #category : 'characterization' }
SecurizationMission >> generateWaypoints [
	| p nb sort |
	p := polygon size.
	nb := p < self drones size ifTrue:[ self drones size - p] ifFalse:[ p - (p \\ self model size)].

sort := SortedCollection sort:[:i :j| ((self polygon at:i) dist: (self polygon at: i%p+1)) < ((self polygon at:j) dist: (self polygon at: i+1))].
sort addAll: (1 to:p).
1 to: nb do:[:a| wayPoints add: (self polygon at:a) + (self polygon at: a%p +1) /2].
wayPoints addAll: polygon.
self wayPoints: (ConvexHullCalculator new  hullForGeoPoints: self wayPoints)
	
 
	 
]

{ #category : 'characterization' }
SecurizationMission >> isSecurizationMission [ 

^true
]

{ #category : 'as yet unclassified' }
SecurizationMission >> nextWayPointFor: drone [

^nil
]

{ #category : 'strategy' }
SecurizationMission >> responseStrategy [
    ^ HybridStrategy new.
]
