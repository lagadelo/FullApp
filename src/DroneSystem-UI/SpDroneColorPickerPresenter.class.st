Class {
	#name : 'SpDroneColorPickerPresenter',
	#superclass : 'SpColorPickerPresenter',
	#instVars : [
		'colorSelector',
		'target'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'accessing' }
SpDroneColorPickerPresenter >> colorSelector [

	^ colorSelector
]

{ #category : 'accessing' }
SpDroneColorPickerPresenter >> colorSelector: anObject [

	colorSelector := anObject
]

{ #category : 'initialization' }
SpDroneColorPickerPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		whenClosedDo: [  self target perform:colorSelector with: colorPickerPresenter color ]
]

{ #category : 'accessing' }
SpDroneColorPickerPresenter >> target [

	^ target
]

{ #category : 'accessing' }
SpDroneColorPickerPresenter >> target: anObject [

	target := anObject
]
