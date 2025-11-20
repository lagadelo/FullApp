Class {
	#name : 'ClusterShapes',
	#superclass : 'Shapes',
	#instVars : [
		'mission',
		'hull'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'accessing' }
ClusterShapes >> hull [

	^ hull
]

{ #category : 'accessing' }
ClusterShapes >> hull: anObject [

	hull := anObject
]
