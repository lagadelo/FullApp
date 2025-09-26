Class {
	#name : 'MixedMission',
	#superclass : 'ClusterMission',
	#instVars : [
		'subMissions',
		'totalWeight'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'visiting' }
MixedMission >> accept: aVisitor [

^aVisitor visitMixedMission: self 
]

{ #category : 'accessing' }
MixedMission >> addSubMission: aMission weight: aValue [

self subMissions at: aMission put: aValue
]

{ #category : 'accessing' }
MixedMission >> allMissions [

^self subMissions keys sortingBlock: [ :a :b| a className < b className ]
]

{ #category : 'as yet unclassified' }
MixedMission >> assignBehaviors [

	| nDrones availableDrones sortedByWeightMissions  |
	nDrones := self assignedCluster drones size.
	availableDrones := self assignedCluster drones copy.
	sortedByWeightMissions := self subMissions associations sort: [ :a :b |
		                          a weight < b weight ].
	sortedByWeightMissions do: [ :a |
		| howMany d |
		howMany := (a weight * nDrones / self totalWeight) rounded min: 1. "all missions must be served"
		d := availableDrones removeFirst: howMany.
		a key assignBehaviors: d ]
]

{ #category : 'as yet unclassified' }
MixedMission >> assignMixedBehaviors [ 
  

| nDrones nZone |
nDrones := self assignedCluster drones size.

"self subMissions self subMissions keys detect: [ :k| k isKindOf:ZoneBasedMission ]
	
 
    nZone := (total / totalWeight ) rounded.

    dronesSurveillance := aCluster drones first: nZone.
    dronesStrike := aCluster drones allButFirst: nZone.
 ]"
]

{ #category : 'accessing' }
MixedMission >> battleZone [
^ self subMissions values collectMany:[:m| m battleZone ] 
]

{ #category : 'characterization' }
MixedMission >> isMixedMission [ 

^true
]

{ #category : 'accessing' }
MixedMission >> recomputeTotalWeight [ 

totalWeight := self subMissions values inject:0 into:[:a :b| a +b]
]

{ #category : 'accessing' }
MixedMission >> removeSubMission: aMission [

self subMissions removeKey: aMission
]

{ #category : 'accessing' }
MixedMission >> subMissions [

	^ subMissions
]

{ #category : 'accessing' }
MixedMission >> subMissions: anObject [

	subMissions ifNil:[subMissions := Dictionary new].
	subMissions := anObject
]

{ #category : 'accessing' }
MixedMission >> totalWeight [

 
	totalWeight ifNil: [ self recomputeTotalWeight ].
	^ totalWeight
]
