Class {
	#name : 'FleetElement',
	#superclass : 'Object',
	#instVars : [
		'id',
		'capabilities',
		'status',
		'missions'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'initialization' }
FleetElement >> asTarget [

	^ Target new model: self
]

{ #category : 'initialization' }
FleetElement >> beAlly [

	self status set:#role to: #allied
]

{ #category : 'initialization' }
FleetElement >> beHostile [

	self status set:#role to: #hostile
]

{ #category : 'accessing' }
FleetElement >> capabilities [

	^ capabilities
]

{ #category : 'accessing' }
FleetElement >> id [

	^ id
]

{ #category : 'accessing' }
FleetElement >> id: anObject [

	id := anObject
]

{ #category : 'initialization' }
FleetElement >> initialize [

	super initialize.
	missions := MissionsList new.
	capabilities := Capabilities new.
	status  := Status new.
]

{ #category : 'testing' }
FleetElement >> isAlly [

^	(self status get:#role) = #ally
]

{ #category : 'testing' }
FleetElement >> isHostile [

^	(self status get:#role) = #ennemy
]

{ #category : 'accessing' }
FleetElement >> missions [

	^ missions
]

{ #category : 'accessing' }
FleetElement >> status [

	^ status
]

{ #category : 'accessing' }
FleetElement >> status: aStatus [

	status := aStatus
]
