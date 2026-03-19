"
has ine instance variable :
	- history  
 
that represents a collection of MacroSimùulatorMetrics.
This is useful for the visitor
"
Class {
	#name : 'MacroSimulatorMetricsHistory',
	#superclass : 'Object',
	#instVars : [
		'history'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorMetricsHistory class >> from: aCollection [

	^ self new
		  history: aCollection;
		  yourself
]

{ #category : 'visiting' }
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

	^ self history ifEmpty: [ nil ] ifNotEmpty: [ history first ]
]

{ #category : 'initialization' }
MacroSimulatorMetricsHistory >> initialize [

	super initialize.
	self history: OrderedCollection new
]
