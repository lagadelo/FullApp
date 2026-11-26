Extension { #name : 'MacroExporter' }

{ #category : '*DroneSystem-Macro' }
MacroExporter >> columnNamesFor: aClass [
	aClass = MacroSimulatorPassageMetrics ifTrue: [ ^ aClass exportFieldNames ].
	^ aClass instanceVariables collect: #name
]

{ #category : '*DroneSystem-Macro' }
MacroExporter >> visitSimulatorMetricsHistory: aHistory [
	| rows |
	aHistory initial ifNil: [ ^ self ].
	rows := OrderedCollection with: (self columnNamesFor: aHistory initial class).
	rows addAll: aHistory history.
	^ rows
]

{ #category : '*DroneSystem-Macro' }
MacroExporter >> visitMacroSimulatorWithFreshness: simulator [
	| data summary label |
	data := self visitMacroSimulator: simulator.
	label := simulator behavior exportName.
	summary := MacroSimulatorMetricsSerie new
		label: label, '-freshness';
		parameters: #(simulation);
		yourself.
	summary addExtractor: (MacroSimulatorExtractor label: 'ticksEnRupture' chain: {
		[ :rows | rows collect: #minFreshness ].
		[ :values | values collect: [ :value | value <= 0 ] ].
		[ :ruptures | ruptures count: #yourself ] }).
	summary addExtractor: (MacroSimulatorExtractor
		field: #freshnessRupture numberOfPeriodsWhere: #yourself label: 'episodesDeRupture').
	summary addToSeries: label -> data.
	self visit: summary.
	^ data
]
