Class {
	#name : 'MaxFuelStrategy',
	#superclass : 'ElectionStrategy',
	#category : 'DroneSystem-Simulation Strategy',
	#package : 'DroneSystem-Simulation Strategy'
}

{ #category : 'as yet unclassified' }
MaxFuelStrategy >> selectLeaderFrom: droneStatusMap [
    ^ droneStatusMap keysAndValuesDo: [:drone :status | status fuel ]
        max: [:a :b | a value <= b value ]
        key.
]
