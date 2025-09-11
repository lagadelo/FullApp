Class {
	#name : 'StaticPositionBehavior',
	#superclass : 'Object',
	#instVars : [
		'sLat',
		'sLon',
		'sAlt'
	],
	#category : 'DroneSystem-Behaviors',
	#package : 'DroneSystem-Behaviors'
}

{ #category : 'initialization' }
StaticPositionBehavior >> executeFor: aDrone atTime: aTime [
    aDrone moveToLatitude: sLat longitude: sLon altitude: sAlt.
    ^ self.

]

{ #category : 'initialization' }
StaticPositionBehavior >> initializeWithLatitude: lat longitude: lon altitude: alt [
    sLat := lat. sLon := lon. sAlt := alt. ^ self.

]

{ #category : 'accessing' }
StaticPositionBehavior >> sAlt [

	^ sAlt
]

{ #category : 'accessing' }
StaticPositionBehavior >> sAlt: anObject [

	sAlt := anObject
]

{ #category : 'accessing' }
StaticPositionBehavior >> sLat [

	^ sLat
]

{ #category : 'accessing' }
StaticPositionBehavior >> sLat: anObject [

	sLat := anObject
]

{ #category : 'accessing' }
StaticPositionBehavior >> sLon [

	^ sLon
]

{ #category : 'accessing' }
StaticPositionBehavior >> sLon: anObject [

	sLon := anObject
]
