Class {
	#name : 'Mission',
	#superclass : 'Object',
	#instVars : [
		'model',
		'status',
		'id',
		'borderColor',
		'color'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'accessing' }
Mission >> borderColor [

	^ borderColor
]

{ #category : 'accessing' }
Mission >> borderColor: anObject [

	borderColor := anObject
]

{ #category : 'accessing' }
Mission >> color [

	^ color
]

{ #category : 'accessing' }
Mission >> color: anObject [

	color := (anObject alpha:0.1)
]

{ #category : 'as yet unclassified' }
Mission >> getBorderColor [

	borderColor ifNil: [ borderColor := (Color red alpha: 0.4) ].
	^ self borderColor
]

{ #category : 'as yet unclassified' }
Mission >> getColor [

	color ifNil: [ color := Color blue alpha: 0.07 ].
	^ self color
]

{ #category : 'accessing' }
Mission >> id [

	^ id
]

{ #category : 'accessing' }
Mission >> id: anObject [

	id := anObject
]

{ #category : 'initialize' }
Mission >> initialize [

	id := 0
]

{ #category : 'accessing' }
Mission >> model [

	^ model
]

{ #category : 'accessing' }
Mission >> model: anObject [

	model := anObject
]

{ #category : 'printing' }
Mission >> printOn: aStream [

	self class  printOn: aStream.
	aStream space.
	self id printOn: aStream
]

{ #category : 'simulation' }
Mission >> startEvent [

	^ MissionStartEvent model: self
]

{ #category : 'accessing' }
Mission >> status [

	^ status
]

{ #category : 'accessing' }
Mission >> status: anObject [

	status := anObject
]
