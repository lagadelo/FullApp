Class {
	#name : 'MacroSimulatorExtractor',
	#superclass : 'Object',
	#instVars : [
		'block',
		'label'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'private - patrol extensions' }
MacroSimulatorExtractor class >> aggregate: aProcessing values: values [
	| selector |
	selector := aProcessing asSymbol.
	selector = #average ifTrue: [ ^ values average asFloat ].
	selector = #min ifTrue: [ ^ values min asFloat ].
	selector = #max ifTrue: [ ^ values max asFloat ].
	selector = #sum ifTrue: [ ^ (values inject: 0 into: [ :s :v | s + v ]) asFloat ].
	selector = #standardDeviation ifTrue: [
		^ values size < 2
			ifTrue: [ 0.0 ]
			ifFalse: [ values standardDeviation asFloat ] ].
		
		selector = #stabilityRatio ifTrue:[ |admissibleDifference| admissibleDifference := 0.01 "1%".   ^(((1 to: values size -1) select:[:i| " On cherche le nombre de de valeurs qui ne varient que de max admissibleDifference par rapport à la voisine" (((values at:i) - (values at:i+1)) / (values at:i) )abs < admissibleDifference]) size / (values size -1))asFloat]. 	
	
			selector = #stabilizationTime ifTrue:[ |admissibleDifference default| admissibleDifference := 0.01 "1%".   default := ( values size -1 to: 1 by: -1) detect:[:i| " On cherche la date de la derniere valeur qui  ne varie que de max admissibleDifference par rapport à la voisine" (((values at:i) - (values at:i+1)) / (values at:i) ) abs  > admissibleDifference] ifNone: [^0]. ^values size -1 - default  ]. 	

 
			selector = #stabilizationDuration ifTrue:[  
				
				|admissibleDifference default defaultStable| admissibleDifference := 0.01 "1%".   default := ( 1 to:  values size -1  ) detect:[:i| " On cherche la date de la premiere valeur qui    varie de plusque   admissibleDifference par rapport à la voisine" (((values at:i) - (values at:i+1)) / (values at:i) ) abs  > admissibleDifference] ifNone: [^0].  defaultStable := (default    to:  values size -1  ) detect:[:i| " On cherche la date de la premiere valeur qui  ne   varie pas de que   admissibleDifference par rapport à la voisine" (((values at:i) - (values at:i+1)) / (values at:i) ) abs  < admissibleDifference] ifNone: [^Number infinity ]. ^defaultStable - default.
				
				]. 
				



		
	(values respondsTo: selector) ifTrue: [ ^ (values perform: selector) asFloat ].

		
		
			self error: 'Unsupported aggregation: ', selector asString  
]

{ #category : 'instance creation' }
MacroSimulatorExtractor class >> block: aBlock [


^self new block: aBlock; yourself 
]

{ #category : 'instance creation - patrol temporal' }
MacroSimulatorExtractor class >> convergenceTimeOf: aField towards: aTarget tolerance: aTolerance [
	^ self
		label: 'convergence(', aField asString, ')'
		block: [ :metrics |
			(MacroSimulatorMetricsHistory from: metrics)
				convergenceTimeOf: aField
				towards: aTarget
				tolerance: aTolerance ]
]

{ #category : 'instance creation - patrol temporal' }
MacroSimulatorExtractor class >> field: aField longestDurationWhere: aPredicate label: aLabel [
	^ self
		label: aLabel
		block: [ :metrics |
			(MacroSimulatorMetricsHistory from: metrics)
				longestDurationOf: aField
				where: aPredicate ]
]

{ #category : 'instance creation - patrol temporal' }
MacroSimulatorExtractor class >> field: aField numberOfPeriodsWhere: aPredicate label: aLabel [
	^ self
		label: aLabel
		block: [ :metrics |
			(MacroSimulatorMetricsHistory from: metrics)
				numberOfPeriodsOf: aField
				where: aPredicate ]
]

{ #category : 'instance creation - patrol temporal' }
MacroSimulatorExtractor class >> field: aField totalDurationWhere: aPredicate label: aLabel [
	^ self
		label: aLabel
		block: [ :metrics |
			(MacroSimulatorMetricsHistory from: metrics)
				totalDurationOf: aField
				where: aPredicate ]
]

{ #category : 'instance creation' }
MacroSimulatorExtractor class >> label: aLabel block: aBlock [

	^ (self block: aBlock)
		  label: aLabel;
		  yourself
]

{ #category : 'instance creation - patrol temporal' }
MacroSimulatorExtractor class >> longestDurationOf: aField above: aThreshold [
	^ self
		field: aField
		longestDurationWhere: [ :value | value > aThreshold ]
		label: 'longest(', aField asString, '>', aThreshold printString, ')'
]

{ #category : 'instance creation - patrol temporal' }
MacroSimulatorExtractor class >> longestDurationOf: aField below: aThreshold [
	^ self
		field: aField
		longestDurationWhere: [ :value | value < aThreshold ]
		label: 'longest(', aField asString, '<', aThreshold printString, ')'
]

{ #category : 'instance creation - perception patrol v0.2' }
MacroSimulatorExtractor class >> longestOutOfRangeDuration [
	^ self
		label: 'longest(outOfRangePerceptionRatio > 0)'
		block: [ :history |
			history longestDurationOf: #outOfRangePerceptionRatio where: [ :v | v > 0.0 ] ]
]

{ #category : 'instance creation - perception patrol v0.2' }
MacroSimulatorExtractor class >> longestUnobservableDuration [
	^ self
		label: 'longest(unobservablePerceptionRatio > 0)'
		block: [ :history |
			history longestDurationOf: #unobservablePerceptionRatio where: [ :v | v > 0.0 ] ]
]

{ #category : 'instance creation - perception patrol v0.2' }
MacroSimulatorExtractor class >> maxGapEstimationError [
	^ self process: #max overField: #maxGapEstimationError
]

{ #category : 'instance creation - perception patrol v0.2' }
MacroSimulatorExtractor class >> meanAngularPerceptionRatio [
	^ self process: #average overField: #angularPerceptionRatio
]

{ #category : 'instance creation - patrol temporal' }
MacroSimulatorExtractor class >> numberOfPeriodsOf: aField above: aThreshold [
	^ self
		field: aField
		numberOfPeriodsWhere: [ :value | value > aThreshold ]
		label: 'periods(', aField asString, '>', aThreshold printString, ')'
]

{ #category : 'as yet unclassified' }
MacroSimulatorExtractor class >> process: aProcessing overField: aField [
	| processingSelector fieldSelector labelString |
	processingSelector := aProcessing asSymbol.
	fieldSelector := aField asSymbol.
	labelString := processingSelector asString, '(', fieldSelector asString, ')'.  
	^ self
		label: labelString
		block: [ :metrics |
			| values |
			values := metrics collect: [ :metric | metric perform: fieldSelector ].
			self aggregate: processingSelector values: values ]
]

{ #category : 'instance creation - patrol temporal' }
MacroSimulatorExtractor class >> stabilizationTimeOf: aField towards: aTarget tolerance: aTolerance during: aWindow [
	^ self
		label: 'stabilization(', aField asString, ')'
		block: [ :metrics |
			(MacroSimulatorMetricsHistory from: metrics)
				stabilizationTimeOf: aField
				towards: aTarget
				tolerance: aTolerance
				during: aWindow ]
]

{ #category : 'instance creation - patrol temporal' }
MacroSimulatorExtractor class >> totalDurationOf: aField above: aThreshold [
	^ self
		field: aField
		totalDurationWhere: [ :value | value > aThreshold ]
		label: 'total(', aField asString, '>', aThreshold printString, ')'
]

{ #category : 'visiting' }
MacroSimulatorExtractor >> accept: aVisitor [

	^ aVisitor visitMacroSimulatorExtractor: self
]

{ #category : 'accessing' }
MacroSimulatorExtractor >> block [

	^ block
]

{ #category : 'accessing' }
MacroSimulatorExtractor >> block: anObject [

	block := anObject
]

{ #category : 'eval' }
MacroSimulatorExtractor >> evaluateOn: aValue [

	^ self block value: aValue
]

{ #category : 'accessing' }
MacroSimulatorExtractor >> label [

	label ifNil: [ self label: 'Block based processing' ].
	^ label
]

{ #category : 'accessing' }
MacroSimulatorExtractor >> label: anObject [

	label := anObject
]
