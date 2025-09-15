Class {
	#name : 'ReinforceWeakestClusterStrategy',
	#superclass : 'Object',
	#instVars : [
		'maxReinforcements'
	],
	#category : 'DroneSystem-Strategies',
	#package : 'DroneSystem-Strategies'
}

{ #category : 'initialization' }
ReinforceWeakestClusterStrategy >> applyTo: aSimulation [
    | alliedClusters vulnScores targetCluster centerPt centerLat centerLon donorPool donors |
    alliedClusters := (aSimulation allFleets select: [:f | f isHostile not ]) collectMany: [:f | f clusters ].
    alliedClusters isEmpty ifTrue: [ ^ self ].
    vulnScores := alliedClusters collect: [:c |
        | aliveCount totalFuel avgFuel score |
        aliveCount := (c drones select: [:d | d isDestroyed not ]) size.
        totalFuel := (c drones inject: 0 into: [:sum :d | sum + (d fuel ifNil: [0]) ]).
        avgFuel := (aliveCount > 0) ifTrue: [ totalFuel / aliveCount ] ifFalse: [ 0 ].
        score := (aliveCount = 0) ifTrue: [ 1.0e6 ] ifFalse: [ (1.0 / (avgFuel + 1e-6)) * (1.0 + (1.0 / aliveCount)) ].
        { c . score } ].
    targetCluster := (vulnScores asSortedCollection: [:a :b | (a second) > (b second)]) first first.
    targetCluster ifNil: [ ^ self ].
    centerPt := targetCluster clusterCenter.
    centerLat := centerPt y. centerLon := centerPt x.
    donorPool := (aSimulation allAlliedDrones select: [:d | (targetCluster drones includes: d) not and: [ d isDestroyed not and: [ d fuel > 30 ] ] ]).
    donorPool isEmpty ifTrue: [ ^ self ].
    donors := donorPool asSortedCollection: [:a :b |
        (a distanceToLatitude: centerLat longitude: centerLon altitude: 0) < (b distanceToLatitude: centerLat longitude: centerLon altitude: 0) ].
    (donors first: (maxReinforcements min: donors size)) do: [:d |
        d setBehavior: (StaticPositionBehavior new initializeWithLatitude: centerLat longitude: centerLon altitude: 120).
    ].
    Transcript show: 'ReinforceWeakestClusterStrategy applied to cluster ', (targetCluster clusterId asString), ' donors=', (maxReinforcements min: donors size) asString; cr.
    ^ self.

]

{ #category : 'initialization' }
ReinforceWeakestClusterStrategy >> initialize [
    maxReinforcements := 2. ^ self.


]

{ #category : 'initialization' }
ReinforceWeakestClusterStrategy >> initializeWithMax: n [
    maxReinforcements := n. ^ self.
]

{ #category : 'accessing' }
ReinforceWeakestClusterStrategy >> maxReinforcements [

	^ maxReinforcements
]

{ #category : 'accessing' }
ReinforceWeakestClusterStrategy >> maxReinforcements: anObject [

	maxReinforcements := anObject
]
