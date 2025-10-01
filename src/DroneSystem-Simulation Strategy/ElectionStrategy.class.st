Class {
	#name : 'ElectionStrategy',
	#superclass : 'Object',
	#category : 'DroneSystem-Simulation Strategy',
	#package : 'DroneSystem-Simulation Strategy'
}

{ #category : 'accessing' }
ElectionStrategy >> generateOrdersFor: aCluster threatAt: aPosition at: aTimestamp [
    self subclassResponsibility.
]

{ #category : 'as yet unclassified' }
ElectionStrategy >> selectLeaderFrom: droneStatusMap [
    "À redéfinir — droneStatusMap est un Dictionary: Drone → StatusData"
    self subclassResponsibility.
]
