Extension { #name : 'MacroSimulatorExtractor' }

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExtractor class >> label: aLabel chain: stages [
	"Each unary block receives the output of the preceding block."
	| blocks |
	blocks := stages asArray copy.
	(blocks notEmpty and: [ blocks allSatisfy: [ :stage | stage isBlock and: [ stage numArgs = 1 ] ] ])
		ifFalse: [ self error: 'Une chaîne d’extraction exige des blocs à un argument.' ].
	^ self label: aLabel block: [ :history |
		blocks inject: history into: [ :value :stage | stage value: value ] ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExtractor class >> process: aProcessing overField: aField [
	| fieldSelector |
	fieldSelector := aField asSymbol.
	aProcessing isBlock ifTrue: [
		(#(1 2) includes: aProcessing numArgs)
			ifFalse: [ self error: 'Un bloc d’agrégation prend les valeurs ou la série et les valeurs.' ].
		^ self label: 'bloc(', fieldSelector asString, ')' block: [ :metrics |
			| values |
			values := metrics collect: [ :metric | metric perform: fieldSelector ].
			aProcessing numArgs = 1
				ifTrue: [ aProcessing value: values ]
				ifFalse: [ aProcessing
					value: (MacroSimulatorMetricsSerie new data: values; yourself)
					value: values ] ] ].
	^ self label: (aProcessing asString, '(', fieldSelector asString, ')')
		block: [ :metrics |
			self aggregate: aProcessing values: (metrics collect: [ :metric | metric perform: fieldSelector ]) ]
]
