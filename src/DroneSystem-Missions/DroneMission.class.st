Class {
	#name : 'DroneMission',
	#superclass : 'Mission',
	#instVars : [
		'wayPoints'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'as yet unclassified' }
DroneMission >> nextWayPointFor: aDrone [

	aDrone == self model ifFalse: [ self error ].
	^ self nextWayPoint
]

{ #category : 'accessing' }
DroneMission >> wayPoints [

	^ wayPoints
]

{ #category : 'accessing' }
DroneMission >> wayPoints: anObject [

	wayPoints := anObject
]
