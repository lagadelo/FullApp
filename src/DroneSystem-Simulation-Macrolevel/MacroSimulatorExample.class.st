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

	| parameters simulator pacingRates sensibilities |
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
					simulator loose: 1 at: 1500.
					simulator run: 3000.
					(MacroExporter new
						 directoryName: DateAndTime now
						 fileName: s printString , '_' , p printString) visit: simulator ] ]
]
