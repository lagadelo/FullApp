Class {
	#name : 'FleetElement',
	#superclass : 'Object',
	#instVars : [
		'id',
		'capabilities',
		'hostile',
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

	hostile := false
]

{ #category : 'initialization' }
FleetElement >> beHostile [

	hostile := true
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
	capabilities := Capabilities new
]

{ #category : 'testing' }
FleetElement >> isHostile [

	^ hostile
]

{ #category : 'accessing' }
FleetElement >> missions [

	^ missions
]
