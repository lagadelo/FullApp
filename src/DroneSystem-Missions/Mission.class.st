Class {
	#name : 'Mission',
	#superclass : 'Object',
	#instVars : [
		'model',
		'status'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'accessing' }
Mission >> model [

	^ model
]

{ #category : 'accessing' }
Mission >> model: anObject [

	model := anObject
]

{ #category : 'simulation' }
Mission >> startEvent [

	^ MissionStartEvent new
		  mission: self;
		  yourself
]

{ #category : 'accessing' }
Mission >> status [

	^ status
]

{ #category : 'accessing' }
Mission >> status: anObject [

	status := anObject
]
