"
has 3 instance variables
	- series : a collection of MacroSimulationMetricsHistory
	- parameters : a collection of parameters that identify one serie among others (ie. MacroSimulationBehavior)
	- extractors : a list of DataExtractor instances to be evaluated on the  series
	- data : the current data to be processed
	
is intented to generate meta data (see compute protocol) overs series of metrics
"
Class {
	#name : 'MacroSimulatorMetricsSerie',
	#superclass : 'Object',
	#instVars : [
		'parameters',
		'fields',
		'extractors',
		'series',
		'behavior',
		'data',
		'label',
		'handoffExtractor'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'visiting' }
MacroSimulatorMetricsSerie >> accept: aVisitor [ 

	^ aVisitor visitMacroSimulatorMetricsSeries: self
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> addExtractor: anExtractorOrAssociation [
	| extractor |
	extractor := (anExtractorOrAssociation isKindOf: Association)
		ifTrue: [
			MacroSimulatorExtractor
				process: anExtractorOrAssociation key
				overField: anExtractorOrAssociation value ]
		ifFalse: [ anExtractorOrAssociation ].
	self extractors add: extractor.
	^ extractor
]

{ #category : 'handoff' }
MacroSimulatorMetricsSerie >> addHandoffExtractor: aHandoffMetricsExtractor [
	"======================================================"

	"Extension MacroSimulatorMetricsSerie"

	"pour accueillir les métriques handoff"

	"======================================================"

	"Enregistre l'extracteur handoff — appelé lors de chaque addToSeries:"

	handoffExtractor := aHandoffMetricsExtractor
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> addToSeries: anArray [ 

	self series add: anArray
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> average [

	^ data average
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> data [

	^ data
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> data: anObject [

	data := anObject
]

{ #category : 'processing' }
MacroSimulatorMetricsSerie >> extractData: p [

	data := self series collect: [ :s |
			        s value collect: [ :aMacroSimulatorMetrics |
				        aMacroSimulatorMetrics perform: p ] ]
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> extractors [

	^ extractors
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> extractors: anObject [

	extractors := anObject
]

{ #category : 'compute - patrol temporal' }
MacroSimulatorMetricsSerie >> firstIndexWhere: aPredicate [
	^ (1 to: data size)
		detect: [ :i | aPredicate value: (data at: i) ]
		ifNone: [ nil ]
]

{ #category : 'initialization' }
MacroSimulatorMetricsSerie >> initialize [

	super initialize.
	extractors := OrderedCollection new.
	self initializeSeries
]

{ #category : 'initialization' }
MacroSimulatorMetricsSerie >> initializeSeries [

	series := OrderedCollection new
]

{ #category : 'compute - patrol temporal' }
MacroSimulatorMetricsSerie >> intervalsWhere: aPredicate [
	| result startIndex |
	result := OrderedCollection new.
	startIndex := nil.
	1 to: data size do: [ :i |
		(aPredicate value: (data at: i))
			ifTrue: [ startIndex ifNil: [ startIndex := i ] ]
			ifFalse: [
				startIndex ifNotNil: [
					result add: (MacroSimulatorInterval
						fromIndex: startIndex
						toIndex: i - 1
						startTime: startIndex
						endTime: i - 1).
					startIndex := nil ] ] ].
	startIndex ifNotNil: [
		result add: (MacroSimulatorInterval
			fromIndex: startIndex
			toIndex: data size
			startTime: startIndex
			endTime: data size) ].
	^ result
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> label [

	label ifNil: [ label := 'summary' ].
	^ label
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> label: anObject [

	label := anObject
]

{ #category : 'compute - patrol temporal' }
MacroSimulatorMetricsSerie >> lastIndexWhere: aPredicate [
	^ (data size to: 1 by: -1)
		detect: [ :i | aPredicate value: (data at: i) ]
		ifNone: [ nil ]
]

{ #category : 'compute - patrol temporal' }
MacroSimulatorMetricsSerie >> longestDurationWhere: aPredicate [
	| intervals |
	intervals := self intervalsWhere: aPredicate.
	intervals ifEmpty: [ ^ 0 ].
	^ (intervals collect: [ :each | each duration ]) max
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> max [
	"	| max |
	max := data first.
	data do: [ :d | d < max ifTrue: [ max := d ] ].
	^ max"

	^ data max
]

{ #category : 'handoff' }
MacroSimulatorMetricsSerie >> mergeHandoffMetrics: handoffResult into: aDataDict [
	"Fusionne les métriques handoff dans le dictionnaire de données existant."

	handoffExtractor metricsKeys do: [ :k |
		aDataDict at: ('handoff_' , k) asSymbol put: (handoffResult at: k) ]
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> min [ 
	"	| min |
	min := data first.
	data do: [ :d | d < min ifTrue: [ min := d ] ].
	^ min"

	^ data min
]

{ #category : 'compute - patrol temporal' }
MacroSimulatorMetricsSerie >> numberOfPeriodsWhere: aPredicate [
	^ (self intervalsWhere: aPredicate) size
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> parameters [

	^ parameters
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> parameters: anObject [

	parameters := anObject
]

{ #category : 'processing' }
MacroSimulatorMetricsSerie >> process [
	"	^ self series collect: [ :aSerie |
			  aSerie key , (self extractors collect: [ :anAssociation |
					   self
						   process: anAssociation key
						   overField: anAssociation value
						   ofData: aSerie value ]) ]	 "

	^ self series collect: [ :aSerie |
			  | tmp |
			  parameters size = 1 ifTrue:[tmp := OrderedCollection with: aSerie key ] ifFalse:[tmp := OrderedCollection withAll: aSerie key].

			  self extractors do: [ :a | tmp add: (a evaluateOn: aSerie value) ].
			  tmp ]
]

{ #category : 'processing' }
MacroSimulatorMetricsSerie >> process: aProcessing overField: p ofData: d [

"Simple processidng as described as symbols; the methods are implement in MacroSimulatorMetricsSerie"
"More complex processing are encoded as Block instances, with self as the firsdt parameter, and the extracted data as the second parameter."


	data := d collect: [ :aMacroSimulatorMetrics |
		        aMacroSimulatorMetrics perform: p ].
	^(aProcessing isKindOf: Symbol)
		ifTrue: [  (self perform: aProcessing) asFloat ]
		ifFalse: [  aProcessing value: self value: data ]
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> series [

	^ series
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> series: anObject [

	series := anObject
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> stabilityRatio [ 

	^ data asSet size / data size
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> stabilizationDuration [ 

	| tmp |
	tmp := self stabilizationFrame.
	^ tmp last - tmp first
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> stabilizationFrame [

	| e s |
	s := (1 to: data size - 1)
		     detect: [ :i | (data at: i) ~= (data at: i + 1) ]
		     ifNone: [ Float infinity ].
	e := (s to: data size - 1)
		     detect: [ :i | (data at: i) = (data at: i + 1) ]
		     ifNone: [ Float infinity ].
	^ Array with: s with: e
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> stabilizationTime [

	^ self stabilizationFrame last
]

{ #category : 'compute - patrol temporal' }
MacroSimulatorMetricsSerie >> stabilizationTimeTowards: aTarget tolerance: aTolerance during: aWindow [
	| lastStart |
	data ifEmpty: [ ^ Float infinity ].
	aWindow <= 0 ifTrue: [ ^ Float infinity ].
	lastStart := data size - aWindow + 1.
	lastStart < 1 ifTrue: [ ^ Float infinity ].
	1 to: lastStart do: [ :i |
		| ok |
		ok := true.
		i to: i + aWindow - 1 do: [ :j |
			((data at: j) - aTarget) abs <= aTolerance
				ifFalse: [ ok := false ] ].
		ok ifTrue: [ ^ i ] ].
	^ Float infinity
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> standardDeviation [ 

	^ data standardDeviation
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> sum [

	^ data inject: 0 into: [ :s :d | s + d ]
]

{ #category : 'compute - patrol temporal' }
MacroSimulatorMetricsSerie >> totalDurationWhere: aPredicate [
	^ (self intervalsWhere: aPredicate)
		inject: 0
		into: [ :sum :interval | sum + interval duration ]
]
