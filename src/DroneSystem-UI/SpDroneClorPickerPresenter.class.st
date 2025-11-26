Class {
	#name : 'SpDroneClorPickerPresenter',
	#superclass : 'SpColorPickerPresenter',
	#instVars : [
		'colorSelector',
		'target'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'accessing' }
SpDroneClorPickerPresenter >> colorSelector [

	^ colorSelector
]

{ #category : 'accessing' }
SpDroneClorPickerPresenter >> colorSelector: anObject [

	colorSelector := anObject
]

{ #category : 'initialization' }
SpDroneClorPickerPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		whenClosedDo: [  self target perform:colorSelector with: colorPickerPresenter color ]
]
