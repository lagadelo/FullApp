Class {
	#name : 'SetDroneStatusOrCapabilityEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'data'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
SetDroneStatusOrCapabilityEvent >> affectedEntities [
    ^ Set with: self model
]

{ #category : 'accessing' }
SetDroneStatusOrCapabilityEvent >> data [

	^ data
]

{ #category : 'accessing' }
SetDroneStatusOrCapabilityEvent >> data: anObject [

	data := anObject
]

{ #category : 'executing' }
SetDroneStatusOrCapabilityEvent >> executeOn: aSimulator [

	self data keysAndValuesDo: [ :k :v | "We support non existng fields"
		self target basicSet: k to: v ]
]

{ #category : 'initialization' }
SetDroneStatusOrCapabilityEvent >> initialize [

	super initialize.
	self data: Dictionary new
]

{ #category : 'initialization' }
SetDroneStatusOrCapabilityEvent >> set: aField to: aValue [

	self data add: aField -> aValue
]

{ #category : 'executing' }
SetDroneStatusOrCapabilityEvent >> target [

	^ self subclassResponsibility
]
