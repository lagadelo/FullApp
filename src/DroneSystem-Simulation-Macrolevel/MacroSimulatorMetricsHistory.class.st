Class {
	#name : 'MacroSimulatorMetricsHistory',
	#superclass : 'Object',
	#instVars : [
		'history'
	],
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
}

{ #category : 'instance cre' }
MacroSimulatorMetricsHistory class >> from: aCollection [

	^ self new
		  history: aCollection;
		  yourself
]

{ #category : 'visit' }
MacroSimulatorMetricsHistory >> accept: aVisitor [

	^ aVisitor visitSimulatorMetricsHistory: self
]

{ #category : 'accessing' }
MacroSimulatorMetricsHistory >> history [

	^ history
]

{ #category : 'accessing' }
MacroSimulatorMetricsHistory >> history: anObject [

	history := anObject
]

{ #category : 'accessing' }
MacroSimulatorMetricsHistory >> initial [

	^self history ifEmpty: [ nil ] ifNotEmpty: [ history first ]
]

{ #category : 'initialize' }
MacroSimulatorMetricsHistory >> initialize [

	self history: OrderedCollection new
]
