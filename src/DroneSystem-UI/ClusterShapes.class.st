Class {
	#name : 'ClusterShapes',
	#superclass : 'Object',
	#instVars : [
		'offset',
		'hull',
		'mission'
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

{ #category : 'accessing' }
ClusterShapes >> mission [

	^ mission
]

{ #category : 'accessing' }
ClusterShapes >> mission: anObject [

	mission := anObject
]

{ #category : 'accessing' }
ClusterShapes >> offset [

	^ offset
]

{ #category : 'accessing' }
ClusterShapes >> offset: anObject [

	offset := anObject
]
