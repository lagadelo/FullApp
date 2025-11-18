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

	| drones nb extra |
	drones := self model drones.
wayPoints := OrderedCollection new.

	nb := (drones size / polygon size - 1) floor. " how many full rounds"
	extra := drones size - (nb + 1 * polygon size). "which vertices receives an extra drone"
	1 to: polygon size do: [ :i |
			| src dest nbPoints |
			src := polygon at: i.
			dest := polygon at: (i + 1 \\ polygon size max: 1).
 
			nbPoints := i <= extra
				            ifTrue: [ nb + 1 ]
				            ifFalse: [ nb ].
			1 to: nbPoints do: [ :j |
					wayPoints add:
						src   * (nbPoints +1 - j) + (dest   * j)
						/ (nbPoints + 1) ] ]
]

{ #category : 'characterization' }
SecurizationMission >> events [
	| drones tmp |
	self computePositions. 
	tmp := OrderedCollection new.
	" should consider already placed drones on the polygon to prevent extra reoganization"
	drones := self model drones.
	1 to: polygon size do: [ :i | tmp add: (MoveStepEvent 
		      drone: (drones at: i)
		       wayPoint: (polygon at: i) speed:20000 / 3600 "20km/h"  ). ].
	1 to: wayPoints size do:[:i| tmp add: (MoveStepEvent 
		      drone: (drones at: polygon size+i)
		       wayPoint: (wayPoints at: i ) speed:20000 / 3600 "20km/h"  ). ].
	^tmp 
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
