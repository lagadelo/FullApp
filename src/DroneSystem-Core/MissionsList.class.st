Class {
	#name : 'MissionsList',
	#superclass : 'Object',
	#instVars : [
		'assignedMissions',
		'activeMissions'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'missions' }
MissionsList >> activateMission: aMission [

	(assignedMissions includes: aMission) ifFalse: [
		^ self error: 'Cannot acivate a non-existing mission' ].
	(activeMissions includes: aMission) ifTrue: [
		^ self error: 'Cannot activate twice the same mission' ].
	activeMissions add: aMission
]

{ #category : 'accessing' }
MissionsList >> activeMissions [

	^ activeMissions
]

{ #category : 'missions' }
MissionsList >> assignMission: aMission [

	(assignedMissions includes: aMission) ifTrue: [
		^ self error: 'Cannot assign twice the same mission' ].
	assignedMissions add: aMission
]

{ #category : 'accessing' }
MissionsList >> assignedMissions [

	^ assignedMissions
]

{ #category : 'missions' }
MissionsList >> disableMission: aMission [

 
	(activeMissions includes: aMission) ifFalse: [
		^ self error: 'Cannot disable  a non-enabled mission' ].
	(activeMissions remove: aMission)
]

{ #category : 'initialize' }
MissionsList >> initialize [

	assignedMissions := OrderedCollection new.
	activeMissions := OrderedCollection new
]

{ #category : 'missions' }
MissionsList >> removeMission: aMission [

	assignedMissions remove: aMission ifAbsent:[^self error:'Cannot remove a non-existing mission'].
	activeMissions remove: aMission ifAbsent:[]
]
