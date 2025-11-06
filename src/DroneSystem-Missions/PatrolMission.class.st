Class {
	#name : 'PatrolMission',
	#superclass : 'DroneMission',
	#instVars : [
		'wayPoints'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'as yet unclassified' }
PatrolMission >> nextWayPointFor: aDrone [

	| index |
	index := self wayPoints indexOf: aDrone position.
	^ self wayPoints at: (index + 1 % self wayPoints size min: 1)
]

{ #category : 'accessing' }
PatrolMission >> wayPoints [

	^ wayPoints
]

{ #category : 'accessing' }
PatrolMission >> wayPoints: anObject [

	wayPoints := anObject
]
