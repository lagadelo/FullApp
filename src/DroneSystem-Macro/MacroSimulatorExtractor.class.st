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

{ #category : 'private - patrol extensions' }
MacroSimulatorExtractor class >> example8WithDilation [
	"Compare la stabilisation pour les périmètres nominal et dilaté, en mètres."

	| contour nominalPerimeter deltaMeters revisitSeconds nominalParams dilatedParams
	  macroMetricsSeries pacingRates outputDirectory |
	contour := MacroSimulatorParameters
		convexHullRouteFromRawPoints: (MacroSimulatorParameters generateRawBrittanyPoints: 100)
		epsilon: 0.
	nominalPerimeter := (1 to: contour size) inject: 0 into: [ :perimeter :index |
		| current next |
		current := contour at: index.
		next := contour at: (index \\ contour size) + 1.
		perimeter + (MacroSimulatorParameters haversineMetersFrom: current to: next) ].
	deltaMeters := 500.
	revisitSeconds := 10.

	nominalParams := MacroSimulatorParameters new
		totalDistance: nominalPerimeter;
		nominalSpeed: 10;
		maxSpeed: 15;
		sensingRadius: 20;
		captureRadius: 20;
		policy: #capingPolicy;
		seed: 3950149054165;
		applyDronesForRevisit: revisitSeconds;
		yourself.
	dilatedParams := nominalParams copy
		totalDistance: (nominalPerimeter + (2.0 * Float pi * deltaMeters));
		applyDronesForRevisit: revisitSeconds;
		yourself.

	Transcript
		show: 'Nominal  ', nominalParams totalDistance printString,
			' m / ', nominalParams numberOfDrones printString, ' drones'; cr;
		show: 'Dilaté   ', dilatedParams totalDistance printString,
			' m / ', dilatedParams numberOfDrones printString, ' drones'; cr;
		show: 'Renfort  +', (dilatedParams numberOfDrones - nominalParams numberOfDrones) printString; cr.

	macroMetricsSeries := MacroSimulatorMetricsSerie new.
	macroMetricsSeries addExtractor: #average -> #stdGap.
	macroMetricsSeries addExtractor: #stabilityRatio -> #maxGap.
	macroMetricsSeries addExtractor: #stabilizationTime -> #maxGap.
	macroMetricsSeries addExtractor: #stabilizationDuration -> #avgSpeed.
	macroMetricsSeries addExtractor: #average -> #avgSpeed.
	macroMetricsSeries parameters: #(hull pacingRate).

	outputDirectory := FileLocator workingDirectory /
		(self timeStampForNaming , '-dilation-' , UUID new asString).
	pacingRates := #(0.90 0.92 0.94 0.96 0.98).
	{ 'nominal' -> nominalParams. 'dilated' -> dilatedParams }
		do: [ :hullCase |
			| label params fleetSize |
			label := hullCase key.
			params := hullCase value.
			fleetSize := params numberOfDrones.
			pacingRates do: [ :pacingRate |
				| simulator exporter data |
				simulator := params initializeSimulator.
				simulator behavior pacingRate: pacingRate.

				"Chaque retrait cible un rang relatif dans la flotte initiale."
				simulator loose: (fleetSize * 0.01) ceiling at: 200.
				simulator loose: (fleetSize * 0.30) ceiling at: 500.
				simulator loose: (fleetSize * 0.80) ceiling at: 800.
				simulator newIncomerAt: 500.
				simulator newIncomerAt: 500.
				simulator newIncomerAt: 1000.
				simulator run: 1500.

				exporter := MacroExporter directoryName:
					(outputDirectory / label / pacingRate printString) fullName.
				data := exporter visit: simulator.
				macroMetricsSeries addToSeries: { label. pacingRate } -> data ] ].

	^ (MacroExporter directoryName: outputDirectory fullName) visit: macroMetricsSeries
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
