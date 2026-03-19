"
MacroSimulatorDrone

has 9 instance variables as:
- id : a unique identifier starting from 0
- isAlive : a boolean value
- position : this is used to locate the drone, modulo the total mission range (see parameters)
- minSpeed, maxSpeed and nominalSpeed  for drones. These act as constraints. We assume the drones share the same internal characteristics
- currentSpeed : this is bitween minSpeed and maxSpeed and should idealy converge towards nominalSpeed
- captureRadius : this describes the zone under investigation. It is used at runtime to detect gaps into the border's coverage
- sensingRadius ; this describes the distance allowing to perceive other drones (i.e one drone further than sensingRadius is reported missing

is intented to represent drones

"
Class {
	#name : 'MacroSimulatorDrone',
	#superclass : 'Object',
	#instVars : [
		'id',
		'position',
		'sensingRadius',
		'captureRadius',
		'isAlive',
		'nominalSpeed',
		'currentSpeed',
		'maxSpeed',
		'minSpeed'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorDrone class >> id: id position: position sensingRadius: sensingRadius captureRadius: captureRadius nominalSpeed: nominalSpeed maxSpeed: maxSpeed [

	^ self new
		  id: id;
		  position: position;
		  sensingRadius: sensingRadius;
		  captureRadius: captureRadius;
		  nominalSpeed: nominalSpeed;
		  currentSpeed: nominalSpeed;
		  maxSpeed: maxSpeed;
		  isAlive: true;
		  yourself
]

{ #category : 'visiting' }
MacroSimulatorDrone >> accept: aVisitor [

	^ aVisitor visitMacroSimulatorDrone: self
]

{ #category : 'accessing' }
MacroSimulatorDrone >> captureRadius [

	^ captureRadius
]

{ #category : 'accessing' }
MacroSimulatorDrone >> captureRadius: anObject [

	captureRadius := anObject
]

{ #category : 'accessing' }
MacroSimulatorDrone >> currentSpeed [

	^ currentSpeed
]

{ #category : 'accessing' }
MacroSimulatorDrone >> currentSpeed: aSpeed [ 

	currentSpeed ifNil: [ currentSpeed := 0 ].
	currentSpeed := (aSpeed min: self maxSpeed) max: 0
]

{ #category : 'running' }
MacroSimulatorDrone >> die [

	self isAlive: false
]

{ #category : 'accessing' }
MacroSimulatorDrone >> id [

	^ id
]

{ #category : 'accessing' }
MacroSimulatorDrone >> id: anObject [

	id := anObject
]

{ #category : 'accessing' }
MacroSimulatorDrone >> isAlive [

	^ isAlive
]

{ #category : 'accessing' }
MacroSimulatorDrone >> isAlive: anObject [

	isAlive := anObject
]

{ #category : 'accessing' }
MacroSimulatorDrone >> maxSpeed [ 

	maxSpeed ifNil: [ maxSpeed := self nominalSpeed ].
	^ maxSpeed
]

{ #category : 'accessing' }
MacroSimulatorDrone >> maxSpeed: anObject [

	maxSpeed := anObject
]

{ #category : 'accessing' }
MacroSimulatorDrone >> minSpeed [ 

	minSpeed ifNil: [ minSpeed := self nominalSpeed ].
	^ minSpeed
]

{ #category : 'accessing' }
MacroSimulatorDrone >> minSpeed: anObject [

	minSpeed := anObject
]

{ #category : 'accessing' }
MacroSimulatorDrone >> nominalSpeed [

	^ nominalSpeed
]

{ #category : 'accessing' }
MacroSimulatorDrone >> nominalSpeed: anObject [

	nominalSpeed := anObject
]

{ #category : 'accessing' }
MacroSimulatorDrone >> position [

	^ position
]

{ #category : 'accessing' }
MacroSimulatorDrone >> position: anObject [

	position := anObject
]

{ #category : 'printing' }
MacroSimulatorDrone >> printOn: aStream [

	aStream nextPut: $(.
	self id printOn: aStream.
	aStream nextPut: $;.
	self position printOn: aStream.
	aStream nextPut: $;.
	self isAlive printOn: aStream.
	aStream nextPut: $)
]

{ #category : 'accessing' }
MacroSimulatorDrone >> sensingRadius [

	^ sensingRadius
]

{ #category : 'accessing' }
MacroSimulatorDrone >> sensingRadius: anObject [

	sensingRadius := anObject
]

{ #category : 'running' }
MacroSimulatorDrone >> update [ 

	self position: self position + self currentSpeed
]
