Class {
	#name : 'PatrolMission',
	#superclass : 'DroneMission',
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'as yet unclassified' }
PatrolMission >> nextWayPoint [

	| index |
	index := self wayPoints indexOf: self position.
	^ self wayPoints at: (index + 1 % self wayPoints size min: 1)
]
