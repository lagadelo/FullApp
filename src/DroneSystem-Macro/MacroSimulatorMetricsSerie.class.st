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
		'label'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'visiting' }
MacroSimulatorMetricsSerie >> accept: aVisitor [ 

	^ aVisitor visitMacroSimulatorMetricsSeries: self
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> addExtractor: anAssociation [

	self extractors add: anAssociation
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

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> label [

	label ifNil: [ label := 'summary' ].
	^ label
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> label: anObject [

	label := anObject
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> max [
	"	| max |
	max := data first.
	data do: [ :d | d < max ifTrue: [ max := d ] ].
	^ max"

	^ data max
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> min [ 
	"	| min |
	min := data first.
	data do: [ :d | d < min ifTrue: [ min := d ] ].
	^ min"

	^ data min
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

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> standardDeviation [ 

	^ data standardDeviation
]

{ #category : 'compute' }
MacroSimulatorMetricsSerie >> sum [

	^ data inject: 0 into: [ :s :d | s + d ]
]
