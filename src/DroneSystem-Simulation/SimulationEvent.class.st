Class {
	#name : 'SimulationEvent',
	#superclass : 'Object',
	#instVars : [
		'task',
		'parents'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'dependencie' }
SimulationEvent >> addToParents: aDependency [

	parents add: aDependency
]

{ #category : 'initialize-release' }
SimulationEvent >> initialize [

	parents := OrderedCollection new
]

{ #category : 'dependencie' }
SimulationEvent >> parents [

	^ parents
]

{ #category : 'dependencie' }
SimulationEvent >> removeFromParents: aDependency [

	parents remove: aDependency
]

{ #category : 'accessing' }
SimulationEvent >> task [

	^ task
]

{ #category : 'accessing' }
SimulationEvent >> task: anObject [

	task := anObject
]
