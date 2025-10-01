Class {
	#name : 'ClosestDroneInterceptStrategy',
	#superclass : 'ResponseStrategy',
	#category : 'DroneSystem-Simulation Strategy',
	#package : 'DroneSystem-Simulation Strategy'
}

{ #category : 'accessing' }
ClosestDroneInterceptStrategy >> generateOrdersFor: aCluster threatAt: aPosition at: aTimestamp [
    | bestDrone |
    bestDrone := aCluster drones
        min: [:d1 :d2 | 
            (d1 position distanceTo: aPosition) <= (d2 position distanceTo: aPosition)
        ].
    
    ^ Array with: (
        InterceptEvent new
            timestamp: aTimestamp + 1;
            drone: bestDrone;
            targetPosition: aPosition;
            yourself
    ).
]
