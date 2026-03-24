"
This class offers a set of examples as class methods
"
Class {
	#name : 'MacroSimulatorExample',
	#superclass : 'Object',
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'examples' }
MacroSimulatorExample class >> example1 [
	"Simple case - no loss"

	| parameters simulator |
	parameters := MacroSimulatorParameters example1.
	simulator := parameters initializeSimulator.
	simulator run: 50.
	^ simulator inspect
]

{ #category : 'examples' }
MacroSimulatorExample class >> example10 [
	"Prospection - in/out drone "

	"revised capingPolicy"

	" self example10 "

	| macroMetricsSeries parameters simulator pacingRates sensibilities exporter minSpeeds |
	macroMetricsSeries := MacroSimulatorMetricsSerie new.
	macroMetricsSeries addExtractor: #average -> #stdGap.
	macroMetricsSeries addExtractor: #stabilityRatio -> #maxGap.
	macroMetricsSeries addExtractor: #stabilizationTime -> #maxGap.
	macroMetricsSeries addExtractor: #min -> #maxGap.
	macroMetricsSeries addExtractor: #max -> #maxGap.
	macroMetricsSeries addExtractor: #stabilizationDuration -> #avgSpeed.
	macroMetricsSeries addExtractor: #average -> #avgSpeed.
	macroMetricsSeries parameters: #( pacingRate sensibilities ).

	exporter := MacroExporter directoryName: self timeStampForNaming. "exporter is Unique to ensure directory consistency"
	pacingRates := { 0.9. 0.91. 0.92. 0.93. 0.94. 0.95. 0.96. 0.87. 0.98.
	               0.99 }.
	sensibilities := { 0.005. 0.01. 0.015. 0.02 }.
	minSpeeds := { 5. 6. 7. 8. 9. 20 }.
	parameters := MacroSimulatorParameters new
		              numberOfDrones: 100;
		              nominalSpeed: 10;
		              maxSpeed: 15;
		              sensingRadius: 20;
		              captureRadius: 20;
		              totalDistance: 10000;
		              policy: #revisedCapingPolicy;
		              seed: 3950149054165;
		              yourself.

	pacingRates do: [ :p |
			sensibilities do: [ :s |
					minSpeeds do: [ :ms |
							| data |
							parameters minSpeed: ms.

							simulator := parameters initializeSimulator.

							simulator behavior
								sensibility: s;
								pacingRate: p.
							simulator loose: 1 at: 199.
							"simulator loose: 30 at: 500.
					simulator loose: 80 at: 800.
					simulator newIncomerAt: 300.
					simulator newIncomerAt: 400.
					simulator newIncomerAt: 1000."
							simulator run: 1500.


							data := exporter visit: simulator.
							macroMetricsSeries addToSeries:
								(Array with: p with: s with: ms) -> data ")" ] ] ].
	^ exporter visit: macroMetricsSeries
]

{ #category : 'examples' }
MacroSimulatorExample class >> example2 [ 
	"Simple case - one loss"

	| parameters simulator |
	parameters := MacroSimulatorParameters example1.

	simulator := parameters initializeSimulator.
	simulator loose: 1 at: 20.
	simulator run: 50.
	^ simulator inspect
 
]

{ #category : 'examples' }
MacroSimulatorExample class >> example3 [ 
	"Idem example 2 : Simple case - one loss"

	"Change behavior -ie. speed adjustement policy - to be smoother"

	| parameters simulator |
	parameters := MacroSimulatorParameters example1.
	parameters policy: #capingPolicy.
	simulator := parameters initializeSimulator.
	simulator loose: 1 at: 20.
	simulator run: 3000.
	simulator evaluateMetrics inspect.
	^simulator inspect
]

{ #category : 'examples' }
MacroSimulatorExample class >> example4 [ 
	"Idem example 2 : Simple case - one loss"

	"Change behavior -ie. speed adjustement policy - to be smoother"

	| parameters simulator |
	parameters := MacroSimulatorParameters example1.
"	parameters policy: #capingPolicy."
	simulator := parameters initializeSimulator.
	simulator loose: 1 at: 20.
	simulator run: 3000.
	simulator evaluateMetrics inspect.
	^simulator inspect
]

{ #category : 'examples' }
MacroSimulatorExample class >> example5 [ 
	"Prospection"

	| parameters simulator pacingRates sensibilities exporter |
	exporter := MacroExporter directoryName: self timeStampForNaming. "exporter is Unique to ensure directory consistency"
	pacingRates := { 0.9. 0.91. 0.92. 0.93. 0.94. 0.95. 0.96. 0.97. 0.98.
	               0.99 }.
	sensibilities := { 0.005. 0.01. 0.015. 0.02 }.

	pacingRates do: [ :p |
			sensibilities do: [ :s |
					parameters := MacroSimulatorParameters new
						              numberOfDrones: 100;
						              nominalSpeed: 10;
						              maxSpeed: 15;
						              minSpeed: 8;
						              sensingRadius: 20;
						              captureRadius: 20;
						              totalDistance: 10000;
						              yourself.
					parameters policy: #capingPolicy.

					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: s;
						pacingRate: p.
					simulator loose: 1 at: 200.
					simulator run: 1500.
					exporter visit: simulator ] ]
]

{ #category : 'examples' }
MacroSimulatorExample class >> example6 [ 
	"Prospection - incoming drone "

	| parameters simulator pacingRates sensibilities exporter |
	exporter := MacroExporter directoryName: self timeStampForNaming. "exporter is Unique to ensure directory consistency"
	pacingRates := { 0.9. 0.91. 0.92. 0.93. 0.94. 0.95. 0.96. 0.97. 0.98.
	               0.99 }.
	sensibilities := { 0.005. 0.01. 0.015. 0.02 }.
	parameters := MacroSimulatorParameters new
		              numberOfDrones: 100;
		              nominalSpeed: 10;
		              maxSpeed: 15;
		              sensingRadius: 20;
		              captureRadius: 20;
		              totalDistance: 10000;
		              yourself.
	parameters policy: #capingPolicy.
	
	
	
	pacingRates do: [ :p |
			sensibilities do: [ :s |
					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: s;
						pacingRate: p.
					"	simulator loose: 1 at: 500."
					simulator newIncomerAt: 500.
					simulator run: 1500.
					exporter visit: simulator ] ]

]

{ #category : 'examples' }
MacroSimulatorExample class >> example7 [ 
	"Prospection - in/out drone "

	| parameters simulator pacingRates sensibilities exporter |
	exporter := MacroExporter directoryName: self timeStampForNaming. "exporter is Unique to ensure directory consistency"
	pacingRates := { 0.9. 0.91. 0.92. 0.93. 0.94. 0.95. 0.96. 0.97. 0.98.
	               0.99 }.
	sensibilities := { 0.005. 0.01. 0.015. 0.02 }.
	parameters := MacroSimulatorParameters new
		              numberOfDrones: 100;
		              nominalSpeed: 10;
		              maxSpeed: 15;
		              sensingRadius: 20;
		              captureRadius: 20;
		              totalDistance: 10000;
		              yourself.
	parameters policy: #capingPolicy.
	pacingRates do: [ :p |
			sensibilities do: [ :s |
					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: s;
						pacingRate: p.
					simulator loose: 1 at: 200.
					simulator loose: 30 at: 500.
					simulator loose: 10 at: 400.
					simulator loose: 20 at: 500.
					simulator loose: 57 at: 1200.
					simulator loose: 80 at: 800.
					simulator newIncomerAt: 550.
					simulator newIncomerAt: 500.
					simulator newIncomerAt: 1000.
					simulator run: 3000.
					exporter visit: simulator ] ]
]

{ #category : 'examples' }
MacroSimulatorExample class >> example8 [ 
	"Prospection - in/out drone "

	" self example8"

	| macroMetricsSeries parameters simulator pacingRates sensibilities exporter |
	macroMetricsSeries := MacroSimulatorMetricsSerie new.
	macroMetricsSeries addExtractor: #average -> #stdGap.
	macroMetricsSeries addExtractor: #stabilityRatio -> #maxGap.
	macroMetricsSeries addExtractor: #stabilizationTime -> #maxGap.

	macroMetricsSeries addExtractor: #stabilizationDuration -> #avgSpeed.
	macroMetricsSeries addExtractor: #average -> #avgSpeed.
	macroMetricsSeries parameters: #( pacingRate sensibilities ).

	exporter := MacroExporter directoryName: self timeStampForNaming. "exporter is Unique to ensure directory consistency"
	pacingRates := { 0.9. 0.91. 0.92. 0.93. 0.94. 0.95. 0.96. 0.87. 0.98.
	               0.99 }.
	sensibilities := { 0.005. 0.01. 0.015. 0.02 }.
	parameters := MacroSimulatorParameters new
		              numberOfDrones: 100;
		              nominalSpeed: 10;
		              maxSpeed: 15;
		              sensingRadius: 20;
		              captureRadius: 20;
		              totalDistance: 10000;
		              policy: #capingPolicy;
		              seed: 3950149054165;
		              yourself.

	pacingRates do: [ :p |
			sensibilities do: [ :s |
					| data |
					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: s;
						pacingRate: p.
					simulator loose: 1 at: 200.
					simulator loose: 30 at: 500.
					simulator loose: 80 at: 800.
					simulator newIncomerAt: 500.
					simulator newIncomerAt: 500.
					simulator newIncomerAt: 1000.
					simulator run: 1500.


					data := exporter visit: simulator.
					macroMetricsSeries addToSeries: (Array with: p with: s) -> data ")" ] ].
	^ exporter visit: macroMetricsSeries
]

{ #category : 'examples' }
MacroSimulatorExample class >> example8b [
	"Idem example8 plus complex extractor "

	" self example8b"

	| macroMetricsSeries parameters simulator pacingRates sensibilities exporter |
	macroMetricsSeries := MacroSimulatorMetricsSerie new.
	macroMetricsSeries addExtractor: [:a :b| a average]   -> #stdGap.
	macroMetricsSeries addExtractor: #stabilityRatio -> #maxGap.
	macroMetricsSeries addExtractor: #stabilizationTime -> #maxGap.

	macroMetricsSeries addExtractor: #stabilizationDuration -> #avgSpeed.
	macroMetricsSeries addExtractor: #average -> #avgSpeed.
	macroMetricsSeries parameters: #( pacingRate sensibilities ).

	exporter := MacroExporter directoryName: self timeStampForNaming. "exporter is Unique to ensure directory consistency"
	pacingRates := { 0.9. 0.91. 0.92. 0.93. 0.94. 0.95. 0.96. 0.87. 0.98.
	               0.99 }.
	sensibilities := { 0.005. 0.01. 0.015. 0.02 }.
	parameters := MacroSimulatorParameters new
		              numberOfDrones: 100;
		              nominalSpeed: 10;
		              maxSpeed: 15;
		              sensingRadius: 20;
		              captureRadius: 20;
		              totalDistance: 10000;
		              policy: #capingPolicy;
		              seed: 3950149054165;
		              yourself.

	pacingRates do: [ :p |
			sensibilities do: [ :s |
					| data |
					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: s;
						pacingRate: p.
					simulator loose: 1 at: 200.
					simulator loose: 30 at: 500.
					simulator loose: 80 at: 800.
					simulator newIncomerAt: 500.
					simulator newIncomerAt: 500.
					simulator newIncomerAt: 1000.
					simulator run: 1500.


					data := exporter visit: simulator.
					macroMetricsSeries addToSeries: (Array with: p with: s) -> data ")" ] ].
	^ exporter visit: macroMetricsSeries
]

{ #category : 'examples' }
MacroSimulatorExample class >> example9 [ 
	"Prospection - in/out drone "

	"revised capingPolicy"

	" self example9"

	| macroMetricsSeries parameters simulator pacingRates sensibilities exporter |
	macroMetricsSeries := MacroSimulatorMetricsSerie new.
	macroMetricsSeries addExtractor: #average -> #stdGap.
	macroMetricsSeries addExtractor: #stabilityRatio -> #maxGap.
	macroMetricsSeries addExtractor: #stabilizationTime -> #maxGap.

	macroMetricsSeries addExtractor: #stabilizationDuration -> #avgSpeed.
	macroMetricsSeries addExtractor: #average -> #avgSpeed.
	macroMetricsSeries parameters: #( pacingRate sensibilities ).

	exporter := MacroExporter directoryName: self timeStampForNaming. "exporter is Unique to ensure directory consistency"
	pacingRates := { 0.9. 0.91. 0.92. 0.93. 0.94. 0.95. 0.96. 0.87. 0.98.
	               0.99 }.
	sensibilities := { 0.005. 0.01. 0.015. 0.02 }.
	parameters := MacroSimulatorParameters new
		              numberOfDrones: 100;
		              nominalSpeed: 10;
		              maxSpeed: 15;
		              sensingRadius: 20;
		              captureRadius: 20;
		              totalDistance: 10000;
		              policy: #revisedCapingPolicy;
		              seed: 3950149054165;
		              yourself.

	pacingRates do: [ :p |
			sensibilities do: [ :s |
					| data |
					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: s;
						pacingRate: p.
					simulator loose: 1 at: 200.
					simulator loose: 30 at: 500.
					simulator loose: 80 at: 800.
					simulator newIncomerAt: 500.
					simulator newIncomerAt: 500.
					simulator newIncomerAt: 1000.
					simulator run: 1500.


					data := exporter visit: simulator.
					macroMetricsSeries addToSeries: (Array with: p with: s) -> data ")" ] ].
	^ exporter visit: macroMetricsSeries
]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> exampleISSE [
	"self exampleISSE"

	"100 random scenarios. For each, measure max(maxgap), average(sandart deviation of gap) and number of steps when a least one gap leads to a hole"

	| simulator macroMetricsSeries data exporter |
	macroMetricsSeries := MacroSimulatorMetricsSerie new.
	macroMetricsSeries addExtractor:
		(MacroSimulatorExtractor process: #max overField: #maxGap).
	macroMetricsSeries addExtractor:
		(MacroSimulatorExtractor process: #min overField: #maxGap).
	macroMetricsSeries addExtractor:
		(MacroSimulatorExtractor process: #average overField: #stdGap).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 350'
			 block: [ :a | (a select: [ :v | v maxGap > 350 ]) size ]).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 325'
			 block: [ :a | (a select: [ :v | v maxGap > 325 ]) size ]).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 300'
			 block: [ :a | (a select: [ :v | v maxGap > 300 ]) size ]).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 275'
			 block: [ :a | (a select: [ :v | v maxGap > 275 ]) size ]).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 250'
			 block: [ :a | (a select: [ :v | v maxGap > 250 ]) size ]).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 225'
			 block: [ :a | (a select: [ :v | v maxGap > 225 ]) size ]).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 200'
			 block: [ :a | (a select: [ :v | v maxGap > 200 ]) size ]).
	macroMetricsSeries parameters: #( #run ).
	exporter := MacroExporter directoryName: self timeStampForNaming.
	1 to: 100 do: [ :seedIndex |
			simulator := self generateScenario: seedIndex.
			simulator run: 1500.
			simulator evaluateMetrics.


			data := exporter visit: simulator.
			macroMetricsSeries addToSeries: (Array with: seedIndex) -> data ")" ].
	^ exporter visit: macroMetricsSeries
]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> exampleISSE2 [
	"self exampleISSE2"

	"100 random scenarios. For each, measure max(maxgap), average(sandart deviation of gap) and number of steps when a least one gap leads to a hole"

	| simulator macroMetricsSeries data exporter |
	macroMetricsSeries := MacroSimulatorMetricsSerie new.
	macroMetricsSeries addExtractor:
		(MacroSimulatorExtractor process: #max overField: #maxGap).
	macroMetricsSeries addExtractor:
		(MacroSimulatorExtractor process: #min overField: #maxGap).
			macroMetricsSeries addExtractor:
		(MacroSimulatorExtractor process: #average overField: #stdGap).
			macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 250'
			 block: [ :a | (a select: [ :v | v maxGap > 250 ]) size ]).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 240'
			 block: [ :a | (a select: [ :v | v maxGap > 240 ]) size ]).
				macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 230'
			 block: [ :a | (a select: [ :v | v maxGap > 230 ]) size ]).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 220'
			 block: [ :a | (a select: [ :v | v maxGap > 220 ]) size ]).
	macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 210'
			 block: [ :a | (a select: [ :v | v maxGap > 210 ]) size ]).
				macroMetricsSeries addExtractor: (MacroSimulatorExtractor
			 label: 'Violations 200'
			 block: [ :a | (a select: [ :v | v maxGap > 200 ]) size ]).
	macroMetricsSeries parameters: #( #agressivity #run ).

	exporter := MacroExporter directoryName: self timeStampForNaming.
	0 to:30 by: 5 do:[:agressivity|
		#(10 20 30 40 50) do:[:seedIndex|
			simulator := self generateScenario: seedIndex withThreshold: (50-agressivity)/100.
			simulator run: 1500.
			simulator evaluateMetrics.


			data := exporter visit: simulator.
			macroMetricsSeries addToSeries: (Array with: agressivity with: seedIndex) -> data ")" ]].
	^ exporter visit: macroMetricsSeries
]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> exampleISSE3 [
	"self exampleISSE3"

	"100 random scenarios. For each, measure max(maxgap), average(sandart deviation of gap) and number of steps when a least one gap leads to a hole"

	| simulator macroMetricsSeries data exporter |

			macroMetricsSeries := MacroSimulatorMetricsSerie new.
			macroMetricsSeries addExtractor:
				(MacroSimulatorExtractor process: #max overField: #maxGap).
 
 			macroMetricsSeries addExtractor:
				(MacroSimulatorExtractor process: #min overField: #fleetSize).
			macroMetricsSeries addExtractor: (MacroSimulatorExtractor
					 label: 'Violations 400'
					 block: [ :a | (a select: [ :v | v maxGap > 400 ]) size ]).
			macroMetricsSeries addExtractor: (MacroSimulatorExtractor
					 label: 'Violations 300'
					 block: [ :a | (a select: [ :v | v maxGap > 300 ]) size ]).
			macroMetricsSeries addExtractor: (MacroSimulatorExtractor
					 label: 'Violations 200'
					 block: [ :a | (a select: [ :v | v maxGap > 200 ]) size ]).
			macroMetricsSeries parameters: #( #agressivity ).
			exporter := MacroExporter directoryName: self timeStampForNaming.
				#( 11 12 13 14 15 16 ) do: [ :seedIndex |
			macroMetricsSeries label: seedIndex printString.
macroMetricsSeries initializeSeries.
	
			0 to: 30 do: [ :agressivity |
					 
					simulator := self
						             generateScenario: seedIndex
						             withThreshold: 50 - agressivity / 100.
					simulator run: 1500.
					simulator evaluateMetrics.


					data := exporter visit: simulator.
					macroMetricsSeries addToSeries: (Array with: agressivity) -> data "agressivity with:" ")" ].
			exporter visit: macroMetricsSeries ]
]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> exampleISSEBaseline [

	| simulator |
	simulator := self generateScenario: 10.
	simulator run: 1500.
		simulator evaluateMetrics inspect.
	^simulator
]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> generateScenario [
	"Consider the 100th seed from the isseRandomSequence"

	^ self generateScenario: 100
]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> generateScenario: n [

	^ self generateScenario: n withThreshold: 0.4
]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> generateScenario: n on: simulator [

	^ self generateScenario: n on: simulator withThreshold: 0.4
]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> generateScenario: n on: simulator withThreshold: aValue [

"Generate scenarios. 
any rand > aValue leads to drone loss. 
any rand < aValue leads to drone insertion.

The lower aValue, the more aggressive environment"



	| rand prev dates indexes index |
	indexes := (0 to: simulator current maxID - 1) asOrderedCollection.
	rand := Random seed: (self isseRandomSequence at: n).
	prev := 1.
	" We compute a sequence of event"
	dates := (1 to: 100) collect: [ :a |
		         prev := prev + (rand next * 10) asInteger ].
	"We qualify events"
	dates do: [ :d |
			rand next > aValue
				ifTrue: [
						index := indexes atRandom: rand.
						[ "We shall prevent inserting and removing the same drone at the same date"
							((simulator incomersAt: d) collect: [ :anIncomer |
								 anIncomer id ]) includes: index ] whileTrue: [
							index := indexes atRandom: rand ].
						simulator loose: index at: d.
						indexes remove: index ]
				ifFalse: [ indexes add: (simulator newIncomerAt: d) ] ].
	"we return a scenario tagged simulator"
	
	 
	^ simulator
]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> generateScenario: n withThreshold: aValue [

"Generate scenario.

The lower aValue, the more aggressive environment"

	^ self generateScenario: n on: (MacroSimulatorParameters new
			   seed: (self isseRandomSequence at: n);
			   numberOfDrones: 100;
			   minSpeed: 5;
			   nominalSpeed: 10;
			   maxSpeed: 15;
			   sensingRadius: 200;
			   captureRadius: 200;
			   totalDistance: 10000;
			   policy: #capingPolicy;
			   yourself) initializeSimulator withThreshold: aValue

]

{ #category : 'ISSE EXAMPLES' }
MacroSimulatorExample class >> isseRandomSequence [


^{ .73948044 .745767308 .25859468 .715024268 .691660684 .835003788 .461410700 .268565388 .934814604 .464419212 .238230924 .126934924 .765390732 .411245964 .399382924 .398668684 .930491276 .590295436 .29975948 .23402380 .643168140 .908252556 .655188364 .1044802444 .1059206028 .997321100 .414051724 .536563596 .584515468 .648318348 .886499724 .1024908 .639384460 .87204236 .761034124 .66291596 .1049216908 .847791500 .953053580 .565648268 .6554508 .211392908 .807206284 .701366156 .220647308 .516832652 .41417100 .257971084 .486149004 .916345228 .275465612 .172373900 .1035327372 .530183564 .348864908 .703564684 .863900556 .1068042636 .1023921548 .298086284 .936304524 .629386636 .1009568140 .962380684 .856693644 .529908108 .709776780 .415541132 .997828492 .1030710668 .656167308 .181156748 .875815820 .736147852 .256302476 .734470028 .61779852 .719150476 .165534092 .849441676 .88206220 .873558412 .1072506252 .793466764 .401979276 .191698316 .334045580 .752135052 .513667980 .631253388 .717335948 .334598028 .801554316 .111070604 .604154252 .848159628 .524811148 .269803916 .473970060 .301582220 .856262540 .496141708 .713699724 .807754636 .859816844 .149674380 .261143948 .769671052 .87461772 .482901388 .981711244 .496931724 .218483596 .125866380 .877593996 .275543948 .890607500 .343946636 .937886092 .339594124 .756667276 .895175052 .637242764 .630894476 .188653452 .700312972 .223906188 .865797004 .714857356 .917766540 .598873484 .243984268 .641296268 .809084300 .655888780 .1027242892 .285975436 .62060940 .286956940 .532504460 .1040084876 .479698316 .615094668 .144683916 .338275212 .13873548 .506520972 .886151052 .831879052 .131552652 .549773708 .589491084 .452309900 .252864908 .167079308 .927453068 .628522892 .511249804 .734947724 .478684044 .823114636 .385294732 .868742540 .662439820 .537479052 .880592268 .952758668 .500407180 .242713484 .477763980 .803503500 .18251660 .696668044 .172146060 .397375884 .331142028 .1043172236 .469946764 .483575180 .968013708 .963991436 .621442444 .184729996 .768084876 .1001493388 .718113164 .925846924 .684781452 .451829644 .886320524 .390351244 .626606988 .243506060 .282476940 .762959244 .1072768908 .427370380 .239330700 .462934412 .921222028 .511927180 .46479756 .263085452 .580099980 .948842380 .970055052 .397760908 .914224012 .590441356 .85324172 .752133516 .305649548 .204814220 .671192460 .715170188 .816917388 .598569868 .944023948 .828976524 .173674380 .258359180 .156454284 .272247180 .772170636 .393706380 .484008332 .466335116 .878856076 .227084172 .642188684 .595964300 .255974284 .638534540 .189553036 .276315532 .67944332 .244715404 .459079052 .83573132 .14357388 .393563020 .470094220 .775325068 .106493836 .433395596 .221558156 .591298956 .186010508 .313086860 .335530380 .344133004 .1072115596 .652091276 .198077836 .1039141260 .513246092 .789273484 .989364620 .331191692 .750217100 .758704012 .476718476 .278106508 .467073932 .547038092 .362248588 .241311116 .290054028 .868347788 .854072716 .453056908 .794309516 .983116684 .13906316 .611870092 .983177100 .919926668 .936105356 .815554956 .295660428 .344273804 .1027008908 .219999628 .684740492 .765067148 .269323660 .485091724 .721724300 .910113676 .45851020 .340751756 .82347916 .461948812 .735135116 .247558540 .139205516 .977732492 .165583244 .693108108 .983760780 .946458508 .64437644 .243726732 .569987980 .152898444 .126308748 .798639500 .788477836 .724883340 .750712204 .1062879628 .539265932 .297866124 .544082316 .519490956 .574451596 .531750796 .644394380 .486525324 .592823180 .137567116 .874168716 .174151052 .486385548 .762881932 .632579468 .40849804 .1015364492 .387113868 .69843340 .498720140 .666640268 .126988172 .790781324 .57465228 .875983756 .1054927756 .873886092 .538715532 .48256908 .712292236 .724702604 .863510924 .107850636 .981267340 .426322316 .766553484 .791056268 .478789516 .308792716 .500541836 .126018444 .493288332 .1000202636 .359871884 .351192972 .34113420 .356222348 .245182860 .83516300 .455000972 .399563148 .180600204 .945373068 .645500812 .600931724 .886225292 .907514766 .799329166 .914985358 .301860238 .914716558 .278173582 .128529806 .745931150 .678611854 .838390670 .402672014 .363498894 .871608206 .14786446 .872607118 .812353934 .663749518 .297458574 .154993038 .296031630 .212068238 .507013006 .442410382 .275452302 .552827790 .644522894 .435943822 .894279054 .353525646 .606171022 .855416206 .267950478 .202683278 .1061727118 .584626574 .279176590 .709269390 .974419854 .33314190 .374858126 .108784526 .341095310 .215705998 .379874702 .213700494 .406421390 .937299342 .394357134 .595665806 .623819662 .410788238 .519501198 .605357966 .554190734 .696632718 .584642958 .552115086 .72778638 .94574990 .953646478 .433029006 .952717198 .1001110926 .939424142 .909497230 .239897486 .688640398 .205899150 .506181518 .183785358 .835941774 .831897998 .536939406 .839947150 .464685454 .882789774 .554299278 .105996174 .1035808142 .672614798 .732840846 .1000512398 .895435150 .560518542 .1072048014 .662185870 .854123918 .451334542 .614579086 .501375886 .990525838 .830561678 .977837966 .284241806 .1043783054 .214194574 .938668942 .944794510 .18542990 .893887886 .1034737550 .649344910 .874943886 .775135630 .298199950 .588018574 .403548558 .802696590 .229838734 .271138702 .20467086 .768420238 .1059021710 .152468366 .543056270 .888845710 .924534670 .814221198 .636224910 .999600526 .471260046 .577651600 .313874832 .866860432 .518373264 .265883536 .715521424 .185219472 .558896016 .362040208 .185209232 .799638928 .552728464 .424941456 .1004385680 .1068597648 .196037520 .453530512 .581224848 .946998672 .836513680 .276897680 .307719568 .75696528 .250381200 .237656976 .962691472 .632067472 .783050640 .960227216 .582165904 .568496528 .200276880 .368714640 .802978192 .106241424 .725540752 .503377808 .485563792 .105912720 .785462160 .641215376 .786248080 .317416848 .70457232 .525858704 .1032902032 .443507088 .819227536 .442774416 .1056958864 .164621712 .571035536 .609812368 .898796944 .1018751376 .975020944 .433994640 .807444880 .394163600 .25266064 .1015793552 .158746000 .349204880 .453319568 .346424208 .856136080 .515833232 .1058799504 .799592336 .1027358096 .47839632 .5133200 .1035733904 .478957968 .856507792 .185874320 .414701456 .625472912 .506282384 .578653072 .211817360 .483854736 .816434576 .638742416 .1064361872 .720481680 .898550160 .497730448 .416422800 .344179088 .571495824 .412264336 .796632976 .366830992 .561926544 .777665424 .242606992 .946780560 .1005116816 .991240080 .332443536 .722165136 .482335120 .831484816 .671345552 .1008693648 .747578768 .773412752 .553105296 .853218704 .717955472 .597863312 .434107280 .623782288 .1013165456 .572493712 .88653712 .298634640 .65317264 .278651792 .722074512 .184738192 .979514768 .327665552 .353077136 .339772816 .988557712 .296967056 .996262800 .991549840 .238206352 .1057898384 .465080208 .1060535696 .526760336 .317494160 .29870992 .697209232 .185664912 .490370960 .873961360 .1045312912 .482935184 .344705936 .308007824 .382290320 .488476050 .908636050 .379625362 .451669394 .1060800914 .334037906 .341695378 .195166610 .525604242 .173598610 .238774162 .350725522 .91885970 .478706578 .256746386 .471923090 .566009234 .717971346 .643854226 .415604114 .789289362 .200127378 .518761362 .885109138 .584246674 .872388498 .647460754 .193287570 .472310162 .766569362 .1043837842 .176187794 .924282258 .227921810 .922255250 .363269522 .726690194 .1050026898 .552713106 .904208786 .1038742930 .755632018 .1040926610 .187352466 .757854610 .1067555730 .716800914 .182983058 .33979794 .514097042 .544658 .280018322 .741439890 .478860178 .384797586 .573624722 .938788242 .641775506 .477583250 .184055186 .879018386 .777390994 .217289618 .813402514 .40979858 .561966994 .437280658 .570568082 .623266194 .27739026 .742759314 .298074514 .1025234322 .664741778 .91957138 .791799186 .502911378 .309771154 .684024722 .460536210 .871390610 .975282066 .19935122 .639622546 .840391058 .1028387730 .166947730 .889450898 .368485778 .80074642 .288831378 .466589074 .629318034 .1059007378 .988771218 .603105682 .311111058 .216534930 .1021853586 .8474002 .932981138 .873751442 .993622930 .1070031250 .971879826 .1043351442 .1066076050 .557122962 .199733650 .355457938 .644957074 .771381650 .714751378 .425377682 .85462930 .764083602 .828193170 .237573010 .540494738 .775098770 .618169746 .191297426 .282531730 .518174098 .33170 .870599570 .468407186 .627952018 .69537170 .808791954 .440410002 .758934930 .659687826 .652575634 .550329234 .669417874 .123704722 .272983954 .221964178 .953689490 .250974610 .598014866 .383591314 .772110738 .377757074 .345497490 .1011085202 .651566482 .98769298 .379990930 .626731922 .1019359634 .18507154 .698881938 .1071052690 .599381394 .670982546 .409824146 .63386514 .547678610 .46067090 .796807058 .924581778 .393973138 .340519314 .1024631698 .971062162 .698982802 .772896146 .179734418 .696960914 .379536786 .186872210 .500833170 .512295826 .743217554 .127008146 .1005649810 .720097170 .369442194 .526973330 .717706130 .970918802 .498422162 .515655058 .529348498 .104257426 .980219282 .817643922 .347245458 .855839634 .832309650 .572050834 .575369106 .389275538 .123121042 .977389970 .933479314 .569711506 .1023984018 .302208402 .210478996 .561686420 .40002964 .477188500 .1260436 .961864596 .72858004 .433839508 .650780564 .605269908 .521166228 .567204244 .990147476 .497216404 .738488724 .557720980 .1032738708 .930527124 .48240020 .442114452 .888908692 .901706644 .144124308 .114470292 .695504788 .436977556 .492162452 .163031444 .361816980 .958987156 .42721684 .51721620 .113035156 .873105300 .535397780 .788476308 .709385108 .323011476 .912185748 .90553748 .635912084 .888901524 .840924564 .968145300 .660968340 .812043156 .146248084 .612369812 .592672660 .597071764 .420951444 .89653652 .415288212 .926602132 .361646484 .483167636 .1006743444 .1013161876 .292613524 .1036880276 .939393940 .595385236 .841679252 .491197844 .946988948 .909797268 .789357972 .105714068 .809597844 .749511572 .443152788 .368024980 .278945684 .950235028 .791322004 .106600852 .1063433108 .906668948 .113684884 .893773204 .18126740 .991328148 .631920020 .498721172 .818539412 .462861204 .944335252 .801533332 .181063572 .633044884 .856427924 .660826516 .1039082388 .613464980 .795484564 .681112980 .304285588 .252331924 .477349268 .658174356 .846633876 .815301524 .600906132 .796491156 .119373716 .592138132 .832159124 .473987476 .587453332 .923700116 .792318356 .929547668 .922335124 .972445588 .931231124 .49791380 .485428116 .391287700 .287345044 .270552468 .693628820 .299065236 .451620244 .167332244 .666649492 .694459284 .978141588 .17487252 .397682580 .863643540 .56026516 .751358356 .806337428 .1009017748 .599275924 .170089876 .764845972 .158543764 .375709076 .1000757652 .583070612 .387083156 .554234260 .40478100 .343594900 .464926612 .395613588 .152412564 .206842772 .172913556 .867936660 .427437460 .935399316 .296435604 .140922260 .296692116 .896361364 .752384916 .860643732 .983348628 .690571156 .847906708 .341443988 .334934420 .367319956}


]

{ #category : 'timeStamping' }
MacroSimulatorExample class >> timeStampForNaming [ 

	^ Date today yyyymmdd , '_' , Time now print24
]
