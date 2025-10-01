Class {
	#name : 'BestPerceptionStrategy',
	#superclass : 'ElectionStrategy',
	#category : 'DroneSystem-Simulation Strategy',
	#package : 'DroneSystem-Simulation Strategy'
}

{ #category : 'as yet unclassified' }
BestPerceptionStrategy >> selectLeaderFrom: droneStatusMap [
    ^ droneStatusMap keysAndValuesDo: [:drone :status | status perceptionRange ]
        max: [:a :b | a value <= b value ]
        key.
]
