Class {
	#name : 'HybridStrategy',
	#superclass : 'ResponseStrategy',
	#category : 'DroneSystem-Simulation Strategy',
	#package : 'DroneSystem-Simulation Strategy'
}

{ #category : 'accessing' }
HybridStrategy >> generateOrdersFor: aCluster threatAt: aPosition at: aTimestamp [
    | interceptor others |
    interceptor := aCluster drones min: [:a :b | 
        (a position distanceTo: aPosition) < (b position distanceTo: aPosition)
    ].
    others := aCluster drones reject: [:d | d = interceptor ].

    ^ (Array with: (
        InterceptEvent new
            timestamp: aTimestamp + 1;
            drone: interceptor;
            targetPosition: aPosition;
            yourself
    )) , (others collect: [:d |
        SurveillanceHoldPositionEvent for: d duration: 10 at: aTimestamp + 1
    ]).
]
