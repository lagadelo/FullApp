Class {
	#name : 'MacroSimulatorEvent',
	#superclass : 'Object',
	#instVars : [
		'timeStep',
		'label',
		'actionBlock'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorEvent class >> at: aTimeStep label: aLabel do: aTwoArgumentBlock [
	^ self new
		timeStep: aTimeStep;
		label: aLabel;
		actionBlock: aTwoArgumentBlock;
		yourself
]

{ #category : 'accessing' }
MacroSimulatorEvent >> actionBlock [
	^ actionBlock
]

{ #category : 'accessing' }
MacroSimulatorEvent >> actionBlock: aBlock [
	actionBlock := aBlock
]

{ #category : 'running' }
MacroSimulatorEvent >> applyTo: aStep simulator: aSimulator [
	^ self actionBlock value: aStep value: aSimulator
]

{ #category : 'accessing' }
MacroSimulatorEvent >> label [
	^ label ifNil: [ 'event' ]
]

{ #category : 'accessing' }
MacroSimulatorEvent >> label: aString [
	label := aString
]

{ #category : 'printing' }
MacroSimulatorEvent >> printOn: aStream [
	aStream
		nextPutAll: self label;
		nextPutAll: '@';
		print: self timeStep
]

{ #category : 'accessing' }
MacroSimulatorEvent >> timeStep [
	^ timeStep
]

{ #category : 'accessing' }
MacroSimulatorEvent >> timeStep: anInteger [
	timeStep := anInteger
]
