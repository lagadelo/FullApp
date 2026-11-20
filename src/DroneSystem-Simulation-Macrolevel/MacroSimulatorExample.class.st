"
This class offers a set of examples as class methods
"
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
MacroSimulatorExample class >> example8GUI [
	"Prospection - in/out drone "

	" self example8GUI"

	| parameters simulator pacingRates sensibilities observer view kit ground geometry wayPoints timeAtTick |
	"definition des waypoints et du terrain"
	"On utilise le mnt autour de Valence dans un premier temps"
	timeAtTick :=[:t| t *100].
	kit := FileLocator home "/ 'Téléchargements' / 'couplage-perception-roassal'".
	ground := FileLocator home / 'terrain-valence'.
	geometry := STONJSON fromString:
		            (kit / 'exemple-valence.geojson') contents.
	"wayPoints := (geometry at: 'coordinates') first collect: [ :pair |
		             pair first @ pair second ].
	"
	
	wayPoints := (0 to: 11) collect: [ :i |
    | angle |
    angle := i * 2 * Float pi / 30.
    (4.8875 + (0.00508 * angle cos)) @
        (44.9386 + (0.00360 * angle sin)) ].
	pacingRates := { 0.9. 0.95. 0.99 }.
	sensibilities := { 0.01 }.
	parameters := MacroSimulatorParameters new
		              numberOfDrones: 10;
		              nominalSpeed: 10;
		              maxSpeed: 15;
		              sensingRadius: 20;
		              captureRadius: 20;
		              totalDistance: 10000;
		              policy: #capingPolicy;
		              seed: 3950149054165;
		              yourself.

	 
					simulator := parameters initializeSimulator.
					simulator behavior
						sensibility: sensibilities first;
						pacingRate: pacingRates first.
					simulator loose: 1 at: 200.
				"	simulator loose: 30 at: 500.
					simulator loose: 80 at: 800.
					simulator newIncomerAt: 500."
					simulator newIncomerAt: 500.
				"	simulator newIncomerAt: 1000."
					 
	 

	15 timesRepeat: [ simulator run: 100 ].
 
	observer := self observerPerceptionOver: ground wayPoints: wayPoints.
	1 to: 1500 by:100 do:[:i| |step| step := simulator history at:i. 
			view := observer
				        value: step
				        value: (timeAtTick value: step timeStep).
			PNGReadWriter
        putForm: view asForm
        onFileNamed: 'valence-',step timeStep printString ,'.png'].
	view open
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

{ #category : 'examples' }
MacroSimulatorExample class >> observerPerceptionOver: ground wayPoints: wayPoints [

	| source points segments perimeter perception view |
	source := PerceptionAdapter fromDirectory: ground.
	points := source projectPolygon: wayPoints.
	segments := OrderedCollection new.
	perimeter := 0.0.

	"Chaque segment contient ses extrémités et ses deux distances cumulées."
	points withIndexDo: [ :a :i |
			| b fin |
			b := points at: i \\ points size + 1.
			fin := perimeter + (a distanceTo: b).
			fin > perimeter ifTrue: [
					segments add: {
							a.
							b.
							perimeter.
							fin }.
					perimeter := fin ] ].

	perception := PerceptionAdapter on: source terrain.
	perception cameraHalfFieldTangent: 0.4 sensorSidePixels: 2000.
	view := PerceptionRoassalView on: perception.

	^ [ :etape :secondes |
		  | tour poses |
		  tour := etape range.
		  poses := etape drones collect: [ :drone |
				           | distance segment fraction |
				           distance := drone position \\ tour / tour * perimeter.
				           segment := segments
					                      detect: [ :chacun |
					                      distance < chacun fourth ]
					                      ifNone: [ segments last ].
				           fraction := distance - segment third
				                       / (segment fourth - segment third).
				           PerceptionDronePose
					           id: drone id
					           position:
					           (segment first
						            interpolateTo: segment second
						            at: fraction)
					           heightAboveGround: 200 ].
		  perception recordAt: secondes polygon: points drones: poses.
		  view ]
]

{ #category : 'naming' }
MacroSimulatorExample class >> timeStampForNaming [

	^ Date today yyyymmdd , '_' , Time now print24
]
