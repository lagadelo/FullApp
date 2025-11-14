Class {
	#name : 'Waypoint',
	#superclass : 'GeoPoint',
	#instVars : [
		'weight'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'accessing' }
Waypoint >> weight [

	^ weight
]

{ #category : 'accessing' }
Waypoint >> weight: anObject [

	weight := anObject
]
