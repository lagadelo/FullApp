Class {
	#name : 'ClusterShapes',
	#superclass : 'Object',
	#instVars : [
		'mission',
		'hull',
		'model'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'instance creation' }
ClusterShapes class >> newFor: aModel [

	^ self new
		  model: aModel;
		  yourself
]

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
ClusterShapes >> model [

	^ model
]

{ #category : 'accessing' }
ClusterShapes >> model: anObject [

	model := anObject
]
