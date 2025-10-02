Class {
	#name : 'AllInterceptStrategy',
	#superclass : 'ResponseStrategy',
	#category : 'DroneSystem-Simulation Strategy',
	#package : 'DroneSystem-Simulation Strategy'
}

{ #category : 'accessing' }
AllInterceptStrategy >> generateOrdersFor: aCluster threatAt: aPosition at: aTimestamp [
    | dronesByDistance interceptor others |

    dronesByDistance := aCluster drones
        asSortedCollection: [:a :b |
            (a position distanceTo: aPosition) < (b position distanceTo: aPosition)
        ].

    interceptor := dronesByDistance first.
    others := dronesByDistance allButFirst.

    ^ (Array with: (
        InterceptEvent new
            timestamp: aTimestamp + 1;
            drone: interceptor;
            targetPosition: aPosition;
            yourself
    )) , (others collect: [:drone |
        SurveillanceHoldPositionEvent new
            timestamp: aTimestamp + 1;
            drone: drone;
            yourself
    ]).
]
