Class {
	#name : 'ClusterMission',
	#superclass : 'Object',
	#instVars : [
		'missionType',
		'zoneParameters'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'as yet unclassified' }
ClusterMission >> assignSecuringBehaviorsTo: aCluster [
    | positions |
    positions := self computeSecuringPositionsFor: aCluster.
    aCluster drones withIndexDo: [:drone :i |
        drone setBehavior: (StaticPositionBehavior new initializeWithLatitude: ((positions at: i) at: 1) longitude: ((positions at: i) at: 2) altitude: ((positions at: i) at: 3)).
    ].
    ^ self.

]

{ #category : 'as yet unclassified' }
ClusterMission >> assignSurveillanceBehaviorsTo: aCluster [
    | segments |
    segments := self computeSurveillanceWaypointsFor: aCluster.
    aCluster drones withIndexDo: [:drone :i |
        drone setBehavior: (PatrolBehavior new initializeWithWaypoints: (segments at: i)).
    ].
    ^ self.

]

{ #category : 'as yet unclassified' }
ClusterMission >> assignToCluster: aCluster [
    aCluster currentMission: self.
    (missionType = #surveillance) ifTrue: [ self assignSurveillanceBehaviorsTo: aCluster ].
    (missionType = #securisation) ifTrue: [ self assignSecuringBehaviorsTo: aCluster ].
]

{ #category : 'as yet unclassified' }
ClusterMission >> computeSecuringPositionsFor: aCluster [
    | polygon n positions |
    polygon := zoneParameters at: #polygon.
    n := aCluster drones size.
    positions := (1 to: n) collect: [:i | polygon at: i ].
    ^ positions.

]

{ #category : 'as yet unclassified' }
ClusterMission >> computeSurveillanceWaypointsFor: aCluster [
    | polygon n segments |
    polygon := zoneParameters at: #polygon.
    n := aCluster drones size.
    segments := (1 to: n) collect: [:i | { (polygon at: i) } ].
    ^ segments.

]

{ #category : 'accessing' }
ClusterMission >> missionType [

	^ missionType
]

{ #category : 'accessing' }
ClusterMission >> missionType: anObject [

	missionType := anObject
]

{ #category : 'accessing' }
ClusterMission >> zoneParameters [

	^ zoneParameters
]

{ #category : 'accessing' }
ClusterMission >> zoneParameters: anObject [

	zoneParameters := anObject
]
