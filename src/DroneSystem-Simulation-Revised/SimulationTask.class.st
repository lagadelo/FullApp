Class {
	#name : 'SimulationTask',
	#superclass : 'Object',
	#instVars : [
		'predecessors',
		'condition',
		'minStartTime',
		'actualStartTime',
		'duration',
		'successors',
		'process',
		'status'
	],
	#category : 'DroneSystem-Simulation-Revised',
	#package : 'DroneSystem-Simulation-Revised'
}

{ #category : 'visiting' }
SimulationTask >> accept: aVisitor [

	^ aVisitor visitSimulationTask: self
]

{ #category : 'accessing' }
SimulationTask >> actualStartTime [

	actualStartTime ifNil: [ self computeActualStartTime ]. "lazzy solution. But what about the simulator itself?"
	^ actualStartTime
]

{ #category : 'accessing' }
SimulationTask >> actualStartTime: anObject [

	actualStartTime := anObject
]

{ #category : 'accessing' }
SimulationTask >> addPredecessor: aPredecessor [

	^ predecessors add: aPredecessor
]

{ #category : 'registration' }
SimulationTask >> addSuccessors: aSuccessor [

	self successors add: aSuccessor
]

{ #category : 'processing' }
SimulationTask >> cannotStartBefore: aDependencyEndTime [

	self minStartTime: (self minStartTime max: aDependencyEndTime)
]

{ #category : 'accessing' }
SimulationTask >> condition [

	^ condition
]

{ #category : 'accessing' }
SimulationTask >> condition: anObject [

	condition := anObject
]

{ #category : 'accessing' }
SimulationTask >> duration [

	^ duration
]

{ #category : 'accessing' }
SimulationTask >> duration: anObject [

	duration := anObject
]

{ #category : 'processing' }
SimulationTask >> evaluateConditionFor: aClient [

	^ self condition value: aClient value: self 
]

{ #category : 'computed values' }
SimulationTask >> expectedEndTime [

	^ self actualStartTime + self duration
]

{ #category : 'initialize' }
SimulationTask >> initialize [

	condition := [ :aClient | true ].
	minStartTime := 0.

	predecessors := OrderedCollection enw.
	successors := OrderedCollection new.
	status := false. "Not completed yet"
	process := nil
]

{ #category : 'accessing' }
SimulationTask >> minStartTime [

	^ minStartTime
]

{ #category : 'accessing' }
SimulationTask >> minStartTime: anObject [

	minStartTime := anObject
]

{ #category : 'computed values' }
SimulationTask >> percentageDoneAt: aTime [

	aTime < self actualStartTime ifTrue: [ ^ 0 ].
	^aTime - self actualStartTime / self duration min: 1
	
 
 
]

{ #category : 'accessing' }
SimulationTask >> predecessors [

	^ predecessors
]

{ #category : 'accessing' }
SimulationTask >> predecessors: anObject [

	predecessors := anObject
]

{ #category : 'processing' }
SimulationTask >> proceedFor: aClient [

	| result |
	result := self process value: aClient value: self. "Do what I have to do"
	self status: true. "Mark as completed"
	^ result
]

{ #category : 'accessing' }
SimulationTask >> process [

	^ process
]

{ #category : 'accessing' }
SimulationTask >> process: aBlock [

"in the form of ”[:aClient :self|]"
process := aBlock
]

{ #category : 'accessing' }
SimulationTask >> removePredecessor: aPredecessor [

	^ predecessors remove: aPredecessor ifAbsent:[self error:'Attempt to remove a non existing predecessor']
]

{ #category : 'registration' }
SimulationTask >> removeSuccessors: aSuccessor [

	self error: 'This should never happen'
]

{ #category : 'accessing' }
SimulationTask >> status [

	^ status
]

{ #category : 'accessing' }
SimulationTask >> status: anObject [

	status := anObject
]

{ #category : 'accessing' }
SimulationTask >> successors [

	^ successors
]

{ #category : 'accessing' }
SimulationTask >> successors: anObject [

	successors := anObject
]
