Class {
	#name : 'InterceptHostilesStrategy',
	#superclass : 'Object',
	#instVars : [
		'maxInterceptors',
		'perHostile',
		'fuelReserve'
	],
	#category : 'DroneSystem-Strategies',
	#package : 'DroneSystem-Strategies'
}

{ #category : 'initialization' }
InterceptHostilesStrategy >> applyTo: aSimulation [
    | hostiles allies candidates selected |
    hostiles := aSimulation allHostileDrones select: [:h | h isDestroyed not ].
    allies := aSimulation allAlliedDrones select: [:d | d isDestroyed not and: [ d fuel > fuelReserve ] ].
    (hostiles isEmpty or: [ allies isEmpty ]) ifTrue: [ ^ self ].
    hostiles do: [:h |
        candidates := allies asSortedCollection: [:a :b |
            | ta tb |
            ta := (a distanceToLatitude: h latitude longitude: h longitude altitude: h altitude) / (a speed max: 0.1).
            tb := (b distanceToLatitude: h latitude longitude: h longitude altitude: h altitude) / (b speed max: 0.1).
            ta < tb ].
        selected := (candidates first: (perHostile min: candidates size)).
        selected do: [:d |
            d setBehavior: (PatrolBehavior new initializeWithWaypoints: { { h latitude. h longitude. h altitude } }).
        ].
    ].
    Transcript show: 'InterceptHostilesStrategy dispatched interceptors for ', hostiles size asString, ' hostiles'; cr.
    ^ self.

]

{ #category : 'accessing' }
InterceptHostilesStrategy >> fuelReserve [

	^ fuelReserve
]

{ #category : 'accessing' }
InterceptHostilesStrategy >> fuelReserve: anObject [

	fuelReserve := anObject
]

{ #category : 'initialization' }
InterceptHostilesStrategy >> initialize [
    maxInterceptors := 3. perHostile := 1. fuelReserve := 30. ^ self.
]

{ #category : 'accessing' }
InterceptHostilesStrategy >> maxInterceptors [

	^ maxInterceptors
]

{ #category : 'accessing' }
InterceptHostilesStrategy >> maxInterceptors: anObject [

	maxInterceptors := anObject
]

{ #category : 'accessing' }
InterceptHostilesStrategy >> perHostile [

	^ perHostile
]

{ #category : 'accessing' }
InterceptHostilesStrategy >> perHostile: anObject [

	perHostile := anObject
]
