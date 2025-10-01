Class {
	#name : 'InterceptOnDetectionStrategy',
	#superclass : 'Object',
	#category : 'DroneSystem-Simulation Strategy',
	#package : 'DroneSystem-Simulation Strategy'
}

{ #category : 'accessing' }
InterceptOnDetectionStrategy >> generateOrdersFor: aCluster threatAt: aPosition at: aTimestamp [
    ^ aCluster drones collect: [:drone |
        InterceptEvent new
            timestamp: aTimestamp + 2; "délai arbitraire"
            drone: drone;
            targetPosition: aPosition;
            yourself
    ].
]
