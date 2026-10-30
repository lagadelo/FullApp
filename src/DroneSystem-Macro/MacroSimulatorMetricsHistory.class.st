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

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> convergenceTimeOf: aField towards: aTarget tolerance: aTolerance [
	"Stronger than stabilizationTime...: first time after which every remaining sample
	is within tolerance."
	| selector |
	selector := aField asSymbol.
	1 to: self history size do: [ :i |
		| converged |
		converged := true.
		i to: self history size do: [ :j |
			(((self history at: j) perform: selector) - aTarget) abs <= aTolerance
				ifFalse: [ converged := false ] ].
		converged ifTrue: [ ^ self timeAtIndex: i ] ].
	^ Float infinity
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> firstTimeOf: aField where: aPredicate [
	| values index |
	values := self valuesOf: aField.
	index := (1 to: values size)
		detect: [ :i | aPredicate value: (values at: i) ]
		ifNone: [ ^ nil ].
	^ self timeAtIndex: index
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

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> intervalsOf: aField where: aPredicate [
	| values result startIndex |
	values := self valuesOf: aField.
	result := OrderedCollection new.
	startIndex := nil.

	1 to: values size do: [ :i |
		(aPredicate value: (values at: i))
			ifTrue: [ startIndex ifNil: [ startIndex := i ] ]
			ifFalse: [
				startIndex ifNotNil: [
					result add: (MacroSimulatorInterval
						fromIndex: startIndex
						toIndex: i - 1
						startTime: (self timeAtIndex: startIndex)
						endTime: (self timeAtIndex: i - 1)).
					startIndex := nil ] ] ].

	startIndex ifNotNil: [
		result add: (MacroSimulatorInterval
			fromIndex: startIndex
			toIndex: values size
			startTime: (self timeAtIndex: startIndex)
			endTime: (self timeAtIndex: values size)) ].
	^ result
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> lastTimeOf: aField where: aPredicate [
	| values index |
	values := self valuesOf: aField.
	index := (values size to: 1 by: -1)
		detect: [ :i | aPredicate value: (values at: i) ]
		ifNone: [ ^ nil ].
	^ self timeAtIndex: index
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> longestDurationOf: aField where: aPredicate [
	| interval |
	interval := self longestIntervalOf: aField where: aPredicate.
	^ interval ifNil: [ 0 ] ifNotNil: [ interval duration ]
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> longestIntervalOf: aField where: aPredicate [
	| intervals |
	intervals := self intervalsOf: aField where: aPredicate.
	intervals ifEmpty: [ ^ nil ].
	^ intervals inject: intervals first into: [ :best :each |
		each duration > best duration ifTrue: [ each ] ifFalse: [ best ] ]
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> numberOfPeriodsOf: aField where: aPredicate [
	^ (self intervalsOf: aField where: aPredicate) size
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> stabilizationTimeOf: aField towards: aTarget tolerance: aTolerance during: aWindow [
	"First time at which a complete window is within tolerance. This is a pragmatic
	stabilization criterion, not a proof that all later values remain stable."
	| selector lastStart |
	selector := aField asSymbol.
	self history ifEmpty: [ ^ Float infinity ].
	aWindow <= 0 ifTrue: [ ^ Float infinity ].
	lastStart := self history size - aWindow + 1.
	lastStart < 1 ifTrue: [ ^ Float infinity ].

	1 to: lastStart do: [ :i |
		(self
			windowFrom: i
			size: aWindow
			satisfies: [ :metric |
				((metric perform: selector) - aTarget) abs <= aTolerance ])
				ifTrue: [ ^ self timeAtIndex: i ] ].
	^ Float infinity
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> timeAtIndex: anIndex [
	| metric |
	metric := self history at: anIndex.
	^ metric timeStep ifNil: [ anIndex - 1 ]
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> times [
	^ (1 to: self history size) collect: [ :i | self timeAtIndex: i ]
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> totalDurationOf: aField where: aPredicate [
	^ (self intervalsOf: aField where: aPredicate)
		inject: 0
		into: [ :sum :interval | sum + interval duration ]
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> valuesOf: aField [
	| selector |
	selector := aField asSymbol.
	^ self history collect: [ :metric | metric perform: selector ]
]

{ #category : 'patrol temporal analysis' }
MacroSimulatorMetricsHistory >> windowFrom: aStart size: aWindow satisfies: aBlock [
	(aWindow <= 0 or: [ aStart + aWindow - 1 > self history size ]) ifTrue: [ ^ false ].
	aStart to: aStart + aWindow - 1 do: [ :i |
		(aBlock value: (self history at: i)) ifFalse: [ ^ false ] ].
	^ true
]
