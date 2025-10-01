Class {
	#name : 'ClosestToTargetStrategy',
	#superclass : 'ElectionStrategy',
	#instVars : [
		'targetPosition'
	],
	#category : 'DroneSystem-Simulation Strategy',
	#package : 'DroneSystem-Simulation Strategy'
}

{ #category : 'initialization' }
ClosestToTargetStrategy >> initializeWith: aPosition [
    targetPosition := aPosition.
]

{ #category : 'as yet unclassified' }
ClosestToTargetStrategy >> selectLeaderFrom: droneStatusMap [
    ^ droneStatusMap keysAndValuesDo: [:drone :status |
        (status position distanceTo: targetPosition)
    ] min: [:a :b | a value >= b value ] key.
]

{ #category : 'accessing' }
ClosestToTargetStrategy >> targetPosition [

	^ targetPosition
]
