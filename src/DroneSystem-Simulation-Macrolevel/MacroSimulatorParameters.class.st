Class {
	#name : 'MacroSimulatorParameters',
	#superclass : 'Object',
	#instVars : [
		'nominalSpeed',
		'maxSpeed',
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
^self  numberOfDrones:100 nominalSpeed: 10 maxSpeed: 15 sensingRadius: 20 captureRadius: 20 totalDistance: 10000
]

{ #category : 'examples' }
MacroSimulatorParameters class >> example2 [
"medium, *1,5 redundancy"
^self  numberOfDrones:100 nominalSpeed: 10 maxSpeed: 15 sensingRadius: 15 captureRadius: 15 totalDistance: 10000
]

{ #category : 'examples' }
MacroSimulatorParameters class >> example3 [
"medium, *1,5 redundancy, *2 neighbours detection"
^self  numberOfDrones:100 nominalSpeed: 10 maxSpeed: 15 sensingRadius: 20 captureRadius: 15 totalDistance: 1000
]

{ #category : 'examples' }
MacroSimulatorParameters class >> example4 [
	"medium, *1,5 redundancy, *2 neighbours detection"

	| tmp simulator |
	tmp := self
		       numberOfDrones: 100
		       nominalSpeed: 10
		       maxSpeed: 15
		       sensingRadius: 20
		       captureRadius: 15
		       totalDistance: 1000.
	simulator := tmp initializeSimulator.
	simulator losses at: 10 put: 1.
	tmp losses at: 34 put: 2.
	^ simulator
]

{ #category : 'instance creation' }
MacroSimulatorParameters class >> numberOfDrones: numberOfDrones nominalSpeed: nominalSpeed maxSpeed: maxSpeed sensingRadius: sensingRadius captureRadius: captureRadius totalDistance: totalDistance [

	| tmp |
	tmp := self new.
	tmp
		numberOfDrones: numberOfDrones;
		nominalSpeed: nominalSpeed;
		maxSpeed: maxSpeed;
		sensingRadius: sensingRadius;
		captureRadius: captureRadius;
		totalDistance: totalDistance.
	^ tmp
]

{ #category : 'instance creation' }
MacroSimulatorParameters class >> numberOfDrones: numberOfDrones nominalSpeed: nominalSpeed maxSpeed: maxSpeed sensingRadius: sensingRadius captureRadius: captureRadius totalDistance: totalDistance initialGap: gap [


"This method is used to stress non stabilized starting situations "
	| tmp |
	tmp := self
		       numberOfDrones: numberOfDrones
		       nominalSpeed: nominalSpeed
		       maxSpeed: maxSpeed
		       sensingRadius: sensingRadius
		       captureRadius: captureRadius
		       totalDistance: totalDistance.
	tmp initialGap: gap.
	^ tmp
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

	^ (1 to: self numberOfDrones) collect: [ :i |
			  | tmp |
			  tmp := MacroSimulatorDrone new.
			  tmp id: i-1.
			  tmp nominalSpeed: self nominalSpeed.
			  tmp maxSpeed: self maxSpeed.
			  tmp currentSpeed: self nominalSpeed.

			  tmp sensingRadius: self sensingRadius.
			  tmp captureRadius: captureRadius.
			  tmp position: numberOfDrones - i * self initialGap ]
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
