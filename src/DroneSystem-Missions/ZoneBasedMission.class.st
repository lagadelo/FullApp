Class {
	#name : 'ZoneBasedMission',
	#superclass : 'ClusterMission',
	#instVars : [
		'wayPoints',
		'polygon',
		'hasDeployed'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'visiting' }
ZoneBasedMission >> accept: aVisitor [

^aVisitor visitZoneBasedMission: self 
]

{ #category : 'assignments' }
ZoneBasedMission >> assignBehaviors [ 
  ^self assignBehaviors: self assignedCluster drones
]

{ #category : 'assignments' }
ZoneBasedMission >> assignBehaviors:someDrones [ 
    | segments |
    segments := self generateExtraWaypointsForDrones.
    self assignedCluster drones withIndexDo: [:drone :i |
        drone setBehavior: (PatrolBehavior new initializeWithWaypoints: (segments at: i)).
    ].
    ^ self.
]

{ #category : 'resolution' }
ZoneBasedMission >> battleZone [

^self polygon
]

{ #category : 'private - utility' }
ZoneBasedMission >> generateExtraWaypointsForDrones [

	| nWaypoints segments neededWaypoints result newPoint fraction nDrones |
	nWaypoints := wayPoints size.
	nDrones := self model drones size.
	"Si on a déjà assez de waypoints, on retourne la liste telle quelle"
	nWaypoints >= nDrones ifTrue: [ ^ wayPoints copy ].

	result := OrderedCollection new.

	"Nombre de waypoints supplémentaires à générer"
	neededWaypoints := nDrones - nWaypoints.

	"Ajouter d’abord les waypoints existants"
	result addAll: wayPoints.

	"Interpolation entre les points existants"
	segments := (1 to: nWaypoints) collect: [ :i |
		            | start end |
		            start := wayPoints at: i.
		            end := i = nWaypoints
			                   ifTrue: [ wayPoints first ]
			                   ifFalse: [ wayPoints at: i + 1 ].
		            {
			            start.
			            end } ].

	"Générer les nouveaux waypoints"
	1 to: neededWaypoints do: [ :k |
		| start end i |
		i := k - 1 \\ segments size + 1.
		start := (segments at: i) at: 1.
		end := (segments at: i) at: 2.
		fraction := k - 1 // neededWaypoints + 0.5. "Point au milieu du segment pour régularité"
		newPoint := {
			            ((start at: 1) + ((end at: 1) - (start at: 1))
			             * fraction).
			            ((start at: 2) + ((end at: 2) - (start at: 2))
			             * fraction).
			            ((start at: 3) + ((end at: 3) - (start at: 3))
			             * fraction) }.
		result add: newPoint ].

	^ result
]

{ #category : 'accessing' }
ZoneBasedMission >> hasDeployed [

hasDeployed 	ifNil:[hasDeployed := false].
	^ hasDeployed
]

{ #category : 'accessing' }
ZoneBasedMission >> hasDeployed: anObject [

	hasDeployed := anObject
]

{ #category : 'characterization' }
ZoneBasedMission >> isZoneBasedMission [ 

^true
]

{ #category : 'accessing' }
ZoneBasedMission >> polygon [

	^ polygon
]

{ #category : 'accessing' }
ZoneBasedMission >> polygon: anObject [

	polygon := (ConvexHullCalculator new  hullForGeoPoints: anObject)
]

{ #category : 'accessing' }
ZoneBasedMission >> wayPoints [

	^ wayPoints
]

{ #category : 'accessing' }
ZoneBasedMission >> wayPoints: anObject [

	wayPoints := anObject
]
