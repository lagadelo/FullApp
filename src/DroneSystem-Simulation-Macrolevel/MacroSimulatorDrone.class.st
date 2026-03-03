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
		'maxSpeed'
	],
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
}

{ #category : 'instance cretion' }
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
MacroSimulatorDrone >> beAlive [

	isAlive := true
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
MacroSimulatorDrone >> initialize [

	self beAlive
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

	^ maxSpeed
]

{ #category : 'accessing' }
MacroSimulatorDrone >> maxSpeed: anObject [

	maxSpeed := anObject
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
aStream nextPut:$(.
self id printOn: aStream.
aStream nextPut:$;.
self position printOn: aStream.
aStream nextPut:$;.
self isAlive printOn: aStream.
aStream nextPut:$).
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
