"
MacroSimulatorMetricsSerie

has 3 instance variables
	- series : a collection of MacroSimulationMetricsHistory
	- parameters : a collection of parameters that identify one serie among others (ie. MacroSimulationBehavior)
	 
	- extractors : a list of DataExtractor instances to be evaluated on the  series
	
is intented to generate meta data overs series of metrics
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
		'data'
	],
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
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
	"^ (self sum: data) / data size"

	^ data average
]

{ #category : 'processing' }
MacroSimulatorMetricsSerie >> extractData: p [

	data := self series collect: [ :s |
			         (s value collect: [ :aMacroSimulatorMetrics |
				         aMacroSimulatorMetrics perform: p ]) ]
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> extractors [

	^ extractors
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> fields [

	^ fields
]

{ #category : 'accessing' }
MacroSimulatorMetricsSerie >> fields: anObject [

	fields := anObject
]

{ #category : 'initializing' }
MacroSimulatorMetricsSerie >> initialize [

	super initialize.
	extractors := OrderedCollection new.
	series := OrderedCollection new
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
MacroSimulatorMetricsSerie >> max: data [

	| max |
	max := data first.
	data do: [ :d | d < max ifTrue: [ max := d ] ].
	^ max
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

	^ self series  collect:[:aSerie| aSerie key,( self extractors collect: [ :anAssociation |
		  self
			  process: anAssociation key
			  overField:anAssociation value ofData: aSerie value ])]
]

{ #category : 'processing' }
MacroSimulatorMetricsSerie >> process: aSymbol overField: p ofData: d [

	data := d collect: [ :aMacroSimulatorMetrics |
		        aMacroSimulatorMetrics perform: p ].
	^ (self perform: aSymbol) asFloat
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
MacroSimulatorMetricsSerie >> stabilityRatio: data [

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
		     detect: [ :i | ((data at: i) = (data at: i + 1)) not ]
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
MacroSimulatorMetricsSerie >> sum: data [

	^ data inject: 0 into: [ :s :d | s + d ]
]
