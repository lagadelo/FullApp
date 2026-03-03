Class {
	#name : 'MacroSimulatorExample',
	#superclass : 'Object',
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
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
				 	parameters := MacroSimulatorParameters
						              numberOfDrones: 100
						              nominalSpeed: 10
						              maxSpeed: 15
						              sensingRadius: 20
						              captureRadius: 20
						              totalDistance: 10000.
					parameters policy: #capingPolicy.

					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: s;
						pacingRate: p.
					simulator loose: 1 at: 500.
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

	pacingRates do: [ :p |
			sensibilities do: [ :s |
				 	parameters := MacroSimulatorParameters
						              numberOfDrones: 100
						              nominalSpeed: 10
						              maxSpeed: 15
						              sensingRadius: 20
						              captureRadius: 20
						              totalDistance: 10000.
					parameters policy: #capingPolicy.

					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: s;
						pacingRate: p.
				"	simulator loose: 1 at: 500." simulator newIncomerAt: 500.
					simulator run: 1500. 
					exporter visit: simulator ] ]
]

{ #category : 'examples' }
MacroSimulatorExample class >> example7 [
	"Prospection - in/out drone "

	| macroMetrics parameters simulator pacingRates sensibilities exporter |
	
	macroMetrics := OrderedCollection new. 
	exporter := MacroExporter directoryName: self timeStampForNaming. "exporter is Unique to ensure directory consistency"
	pacingRates := { 0.9. 0.91. 0.92. 0.93. 0.94. 0.95. 0.96. 0.97. 0.98.
	               0.99 }.
	sensibilities := { 0.005. 0.01. 0.015. 0.02 }.

	pacingRates do: [ :p |
			sensibilities do: [ :s |
					parameters := MacroSimulatorParameters
						              numberOfDrones: 100
						              nominalSpeed: 10
						              maxSpeed: 15
						              sensingRadius: 20
						              captureRadius: 20
						              totalDistance: 10000.
					parameters policy: #capingPolicy.

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
					macroMetrics add: (Array with:p with:s),( exporter visit: simulator) ] ].
			^macroMetrics
]

{ #category : 'examples' }
MacroSimulatorExample class >> example8 [
	"Prospection - in/out drone "

	| macroMetrics parameters simulator pacingRates sensibilities exporter |
	
	macroMetrics := OrderedCollection new. 
	exporter := MacroExporter directoryName: self timeStampForNaming. "exporter is Unique to ensure directory consistency"
	pacingRates := { 0.9. 0.91. 0.92. 0.93. 0.94. 0.95. 0.96. 0.97. 0.98.
	               0.99 }.
	sensibilities := { 0.005. 0.01. 0.015. 0.02 }.

	pacingRates do: [ :p |
			sensibilities do: [ :s |
					parameters := MacroSimulatorParameters
						              numberOfDrones: 100
						              nominalSpeed: 10
						              maxSpeed: 15
						              sensingRadius: 20
						              captureRadius: 20
						              totalDistance: 10000.
					parameters policy: #capingPolicy.

					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: s;
						pacingRate: p.
					simulator loose: 1 at: 200.
					"simulator loose: 30 at: 500.
					simulator loose: 80 at: 800.
					simulator newIncomerAt: 500.
					simulator newIncomerAt: 500.
					simulator newIncomerAt: 1000."
					simulator run: 1500.
					"macroMetrics add: (Array with:p with:s),(" exporter visit: simulator")" ] ].
			^macroMetrics
]

{ #category : 'naming' }
MacroSimulatorExample class >> timeStampForNaming [

	^ Date today yyyymmdd , '_' , Time now print24
]
