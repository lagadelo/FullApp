"
MacroSimulatorParametere

has 6 instance variables as:
	- totalDistance : the span of the mission
	- numberOfDrones : an integer defining the number of drones at first  
	- minSpeed, maxSpeed and nominalSpeed  for drones. We assume the drones share the same internal cgaracteristics
	- captureRadius : this describes the zone under investigation. It is used at runtime to detect gaps into the border's coverage
	- sensingRadius ; this describes the distance allowing to perceive other drones (i.e one drone further than sensingRadius is reported missing
	
is intented to initialize the MacroSimulator
"
Class {
	#name : 'MacroSimulatorParameters',
	#superclass : 'Object',
	#instVars : [
		'nominalSpeed',
		'maxSpeed',
		'minSpeed',
		'sensingRadius',
		'captureRadius',
		'numberOfDrones',
		'totalDistance',
		'initialGap',
		'policy'
	],
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
}

{ #category : 'examples' }
MacroSimulatorParameters class >> example1 [
	"easy, *2 redundancy"
	"+50% max speed, non speed under nominal"

	| tmp |
	tmp := self new.
	tmp
		numberOfDrones: 100;
		nominalSpeed: 10;
		minSpeed: 10;
		maxSpeed: 15;
		sensingRadius: 20;
		captureRadius: 20;
		totalDistance: 10000.
	^ tmp
]

{ #category : 'examples' }
MacroSimulatorParameters class >> example2 [
"medium, *1,5 redundancy"

	| tmp |
	tmp := self new.
	tmp
		numberOfDrones: 100;
		nominalSpeed: 10;
		minSpeed: 10;
		maxSpeed: 15;
		sensingRadius: 15;
		captureRadius: 20;
		totalDistance: 10000.
	^ tmp
]

{ #category : 'examples' }
MacroSimulatorParameters class >> example3 [
"medium, *1,5 redundancy, *2 neighbours detection"
	| tmp |
	tmp := self new.
	tmp
		numberOfDrones: 100;
		nominalSpeed: 10;
		minSpeed: 10;
		maxSpeed: 15;
		sensingRadius: 20;
		captureRadius: 15;
		totalDistance: 10000.
	^ tmp
]

{ #category : 'visiting' }
MacroSimulatorParameters >> accept: aVisitor [

	^ aVisitor visitMacroSimulatorParameters: self
]

{ #category : 'accessing' }
MacroSimulatorParameters >> captureRadius [

	^ captureRadius
]

{ #category : 'accessing' }
MacroSimulatorParameters >> captureRadius: anObject [

	captureRadius := anObject
]

{ #category : 'running' }
MacroSimulatorParameters >> generate [
	"Generate a collection of drones "

	^ (1 to: self numberOfDrones) collect: [ :i |
			  | tmp |
			  tmp := self generateDrone.
			  tmp id: i - 1.
			  tmp position: numberOfDrones - i * self initialGap ]
]

{ #category : 'running' }
MacroSimulatorParameters >> generateDrone [
	"Generate a drone with no meaning id nor position"

	| tmp |
	tmp := MacroSimulatorDrone new.
	tmp id: Float infinity.
	tmp nominalSpeed: self nominalSpeed.
	tmp maxSpeed: self maxSpeed.
	tmp minSpeed: self minSpeed.
	tmp currentSpeed: self nominalSpeed.
	tmp sensingRadius: self sensingRadius.
	tmp captureRadius: self captureRadius.
	tmp position: Float infinity.
	^ tmp
]

{ #category : 'accessing' }
MacroSimulatorParameters >> initialGap [

	initialGap ifNil: [ "Assume homogeneous dispatch omong the perimeter"
		self initialGap: self totalDistance / self numberOfDrones ].
	^ initialGap
]

{ #category : 'accessing' }
MacroSimulatorParameters >> initialGap: anObject [

	initialGap := anObject
]

{ #category : 'running' }
MacroSimulatorParameters >> initializeSimulator [

  ^MacroSimulator new startWith: self.
 
]

{ #category : 'accessing' }
MacroSimulatorParameters >> maxSpeed [

	^ maxSpeed
]

{ #category : 'accessing' }
MacroSimulatorParameters >> maxSpeed: anObject [

	maxSpeed := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> minSpeed [

	^ minSpeed
]

{ #category : 'accessing' }
MacroSimulatorParameters >> minSpeed: anObject [

	minSpeed := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> nominalSpeed [

	^ nominalSpeed
]

{ #category : 'accessing' }
MacroSimulatorParameters >> nominalSpeed: anObject [

	nominalSpeed := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> numberOfDrones [

	^ numberOfDrones
]

{ #category : 'accessing' }
MacroSimulatorParameters >> numberOfDrones: anObject [

	numberOfDrones := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> policy [

	policy ifNil: [ self policy: #default ].
	^ policy
]

{ #category : 'accessing' }
MacroSimulatorParameters >> policy: anObject [

	policy := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> sensingRadius [

	^ sensingRadius
]

{ #category : 'accessing' }
MacroSimulatorParameters >> sensingRadius: anObject [

	sensingRadius := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> totalDistance [

	^ totalDistance
]

{ #category : 'accessing' }
MacroSimulatorParameters >> totalDistance: anObject [

	totalDistance := anObject
]
