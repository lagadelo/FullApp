Class {
	#name : 'SecurizationMission',
	#superclass : 'ZoneBasedMission',
	#instVars : [
		'counter'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'visiting' }
SecurizationMission >> accept: aVisitor [

^aVisitor visitSecurizationMission: self 
]

{ #category : 'characterization' }
SecurizationMission >> computePositions [

	| p nb sort balancing tmp |
	p := polygon size.
	"how many additional waypoints do i need"
	nb := self howManyAdditionalVertices.
nb = 0 ifTrue:[self wayPoints: self polygon. ^self].
 
	"I assign an initial number of segments to 1 per edge"
	balancing := (1 to: p) collect: [ :i |
			             Array
				             with:
				             ((self polygon at: i) distanceTo:
					              (self polygon at: i % p + 1))
				             with: i
				             with: 1 ].
	" I want to split the longuest edge"
	sort := SortedCollection sortBlock: [ :a :b |
		        a first / a last > (b first / b last) ].
	sort addAll: balancing.
	nb timesRepeat: [ " I split the longuest edge; its weight is lowered, as its number of segments is goes up"
			sort first at:3 put: sort first last + 1.
			"I need to update my list to reflect my new weight"
			sort reSort  ]. 


	tmp := OrderedCollection new.

	"Now, I consider the edges"
	balancing do: [ :elt |
			| i |
			"I first add the source vertice"
			i := elt at: 2.
			tmp add: (self polygon at: i).
			"I find the number of vectices to be added on this edge"
			nb := elt last.
			1 to: nb - 1 do: [ :j | " I add a vertice based on a barycenter nb -1, 1 till 1, n-1"
					tmp add:
						(self polygon at: i) * (nb - j)
						+ ((self polygon at: i % p + 1) * j) / nb ].

			"I cannot recompute a hull as the vertices   are now partially aligned"
			self wayPoints: tmp ]
]

{ #category : 'characterization' }
SecurizationMission >> events [

	| drones tmp ratio |
	counter := self model drones size.
	self computePositions.
	tmp := OrderedCollection new.
	" should consider already placed drones on the polygon to prevent extra reoganization"
	drones := self model drones.

	ratio := wayPoints size / drones size.

	1 to: drones size do: [ :i | " tmp add: (MoveStepEvent 
		      drone: (drones at: i)
		       wayPoint: (wayPoints at: 1 + ((i-1)* ratio)) speed:20000 / 3600)"
			tmp
				add: (MoveToWaypointEvent new
						 model: (drones at: i);
						 wayPoint: (wayPoints at: 1 + (i - 1 * ratio));
						 speed: 20000 / 3600;
				yourself) ].

	^ tmp
]

{ #category : 'characterization' }
SecurizationMission >> howManyAdditionalVertices [

	| p |
	p := polygon size.
	"how many additional waypoints do i need"
	^ p < self drones size
		  ifTrue: [ "ensure two slots per drone" self drones size * 2 - p ]
		  ifFalse: [ "get a multiple"
		  self drones size - (p \\ self drones size) ]
]

{ #category : 'characterization' }
SecurizationMission >> isSecurizationMission [ 

^true
]

{ #category : 'as yet unclassified' }
SecurizationMission >> nextWayPointFor: drone [
self isActive ifFalse:[ ^nil].

	counter > 1 ifTrue: [ "Hold on until full deployment"
			counter := counter - 1.
			^ nil ].
	counter = 1 ifTrue: [ "End on round #1; all drones on place, re-dispach"
			counter := counter - 1.
			self model drones do: [ :aDrone |
					| tmp speed |
					speed := 20000 / 3600.
					tmp := self nextWayPointFor: aDrone.

					DroneSimulator uniqueInstance
						scheduleEvent: (MoveToWaypointEvent new
								 
								 model: aDrone;
								 wayPoint: tmp; speed: speed;
								 yourself)
						at: DroneSimulator uniqueInstance currentTime
							"20km/h" ].
			^ nil ].
	counter = 0 ifTrue: [  "Nominal case. Next waypoint on the convex hull"
			^ self wayPoints at:
				  (self wayPoints indexOf:  drone position)
				  % self wayPoints size + 1 ]
]

{ #category : 'strategy' }
SecurizationMission >> responseStrategy [
    ^ HybridStrategy new.
]
