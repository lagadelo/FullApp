Class {
	#name : 'MissionShapes',
	#superclass : 'Shapes',
	#instVars : [
		'hull'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'accessing' }
MissionShapes >> hull [

	^ hull
]

{ #category : 'accessing' }
MissionShapes >> hull: anObject [

	hull := anObject
]
