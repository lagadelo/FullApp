Class {
	#name : 'Waypoint',
	#superclass : 'GeoPoint',
	#instVars : [
		'weight'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'accessing' }
Waypoint >> weight [

	^ weight
]

{ #category : 'accessing' }
Waypoint >> weight: anObject [

	weight := anObject
]
