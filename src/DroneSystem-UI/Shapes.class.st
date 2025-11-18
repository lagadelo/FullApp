Class {
	#name : 'Shapes',
	#superclass : 'Object',
	#instVars : [
		'model'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'instance creation' }
Shapes class >> newFor: aModel [

	^ self new
		  model: aModel;
		  yourself
]

{ #category : 'accessing' }
Shapes >> model [

	^ model
]

{ #category : 'accessing' }
Shapes >> model: anObject [

	model := anObject
]
