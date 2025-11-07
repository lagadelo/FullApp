Class {
	#name : 'StationaryMission',
	#superclass : 'DroneMission',
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'as yet unclassified' }
StationaryMission >> nextWayPoint [

	^ self model == self waypoint
		  ifFalse: [ "On going" self waypoint ]
		  ifTrue: [ "Has ended" nil ]
]

{ #category : 'as yet unclassified' }
StationaryMission >> wayPoint [

^self wayPoints first
]

{ #category : 'as yet unclassified' }
StationaryMission >> wayPoint: aPoint [

	self wayPoints: { aPoint }
]
