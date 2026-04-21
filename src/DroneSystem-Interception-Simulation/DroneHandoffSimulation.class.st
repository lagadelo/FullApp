"
This class is the high level simulator, that manipulates the DroneHandofModel.

His instances variables are: 
- model
Baseline scenario (DroneHandoffModel) used as the center of all random trials.

- sampleCount
Number of Monte Carlo runs.
More runs = more stable percentiles/on-time estimate (1,000 quick, 10,000 robust).

- results
Collected trial outputs, each typically:

#totalSeconds
#onTime (boolean vs SLA)

- random, a Random generator used by vary:ratio: to perturb baseline values.


"
Class {
	#name : 'DroneHandoffSimulation',
	#superclass : 'Object',
	#instVars : [
		'model',
		'sampleCount',
		'results',
		'random',
		'regime',
		'stealthPolicy'
	],
	#classInstVars : [
		'model'
	],
	#category : 'DroneSystem-Interception-Simulation',
	#package : 'DroneSystem-Interception-Simulation'
}

{ #category : 'accessing' }
DroneHandoffSimulation class >> default [

	^ self new
		  initializeDefaults;
		  initializeRandom;
		  yourself
]

{ #category : 'initialization' }
DroneHandoffSimulation class >> defaultStealthPolicy [
    ^ Dictionary new
        at: #rfAllowed put: false;
        at: #rfMaxPings put: 2;
        at: #rfPingSeconds put: 0.10;
        at: #rfAcquireBaseProbability put: 0.45;
        at: #rfAcquireGainPerPing put: 0.20;
        at: #visionFallbackSeconds put: 18.0;
        at: #visionFallbackJitterRatio put: 0.25;
        at: #rfDetectRiskPerPing put: 0.015;
        at: #missionDropProbabilityIfNoAcquire put: 0.25;
        yourself
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example [
    | model sim |
    model := DroneHandoffModel default.
    model
        distanceKm: 10;
        slaSeconds: 420.

    sim := self default.
    sim
        model: model;
        sampleCount: 10000.

    sim printReport.
^sim
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example10 [
	"Sweep all tXxx for multiple targets"""

	self sweepAllTParametersTargets: #( 90 95 99 ) regime: #stress
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example11 [
	"Which tXxx hurts max distance most at 99%?"

	self rankTParametersByImpactAtTarget: 99 regime: #baseline
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example2 [

	| sim speedNeeded |
	sim := self default.

	^ speedNeeded := sim
		                 requiredSpeedKmhForDistanceKm: 40
		                 targetOnTimePercent: 95
		                 sampleCount: 5000
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example3 [

	| sim maxKm |
	sim := self default.

	^ maxKm := sim
		           maxDistanceKmForSpeedKmh: 130
		           targetOnTimePercent: 95
		           sampleCount: 5000
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example4 [

	| sim |
	sim := self default.

	^ (200 to: 100 by: -10) collect: [ :speed |
			  Array with: speed with: (sim
					   maxDistanceKmForSpeedKmh: speed
					   targetOnTimePercent: 95
					   sampleCount: 5000) ]
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example5 [

	| sim |
	sim := self default.

	^ (90 to: 99 by: 1) collect: [ :percent |
			  Array with: percent with: (sim
					   maxDistanceKmForSpeedKmh: 130
					   targetOnTimePercent: percent
					   sampleCount: 5000) ]
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example6 [ 

"95% curve in baseline vs stress"
{
    #baseline -> (self sweepKneeDemo95InRegime: #baseline).
    #stress   -> (self sweepKneeDemo95InRegime: #stress)
}

]

{ #category : 'examples' }
DroneHandoffSimulation class >> example7 [
	"Targets: 90 / 95 / 98 / 99"

	^self sweepKneeDemoTargetsInRegime: #baseline
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example8 [
	"Single target (95%), stress regime"

	self sweepTParameter: #tLaunch regime: #stress
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example9 [
	"Same stage, multiple targets, baseline regime"

	self
		sweepTParameter: #tLaunch
		targets: #( 90 95 99 )
		regime: #baseline
]

{ #category : 'publishing' }
DroneHandoffSimulation class >> publicationComparisonExample [
    | sim |
    sim := self new
        model: DroneHandoffModel scenarioKneeDemo;
        sampleCount: 10000;
        regime: #furtiveHybrid;
        initializeRandom;
        yourself.
    ^ sim evaluatePureVisionVsFurtiveSampleCount: 10000
]

{ #category : 'ranking' }
DroneHandoffSimulation class >> rankTParametersByImpact [
	"Rank tXxx by max-distance loss when stage latency increases from x1.0 to x1.3."
	| curves impacts |
	curves := self sweepAllTParameters.
	impacts := curves associations collect: [ :assoc |
		| curve at1 at13 |
		curve := assoc value.
		at1 := (curve detect: [ :entry | entry first = 1.00 ] ifNone: [ nil ]) ifNotNil: [ :entry | entry second ] ifNil: [ 0.0 ].
		at13 := (curve detect: [ :entry | entry first = 1.30 ] ifNone: [ nil ]) ifNotNil: [ :entry | entry second ] ifNil: [ 0.0 ].
		Array with: assoc key with: (at1 - at13) ].
	^ impacts asSortedCollection: [ :a :b | a second > b second ]

]

{ #category : 'ranking' }
DroneHandoffSimulation class >> rankTParametersByImpactAtTarget: target [
	"Rank tXxx by distance loss when moving from factor x1.0 to x1.3 at a given target."
	| parameters impacts |
	parameters := #(tDetect tClassify tAlert tAck tHandoff tLaunch).
	impacts := parameters collect: [ :parameter |
		| targetCurve at1 at13 |
		targetCurve := (self sweepTParameter: parameter targets: { target }) first second.
		at1 := (targetCurve detect: [ :entry | entry first = 1.00 ] ifNone: [ {1.00. 0.0} ]) second.
		at13 := (targetCurve detect: [ :entry | entry first = 1.30 ] ifNone: [ {1.30. 0.0} ]) second.
		Array with: parameter with: (at1 - at13) ].
	^ impacts asSortedCollection: [ :a :b | a second > b second ]

]

{ #category : 'ranking' }
DroneHandoffSimulation class >> rankTParametersByImpactAtTarget: target regime: regimeSymbol [
    | parameters impacts |
    parameters := #(tDetect tClassify tAlert tAck tHandoff tLaunch).
    impacts := parameters collect: [ :parameter |
        | targetCurve at1 at13 |
        targetCurve := (self sweepTParameter: parameter targets: { target } regime: regimeSymbol) first second.
        at1 := (targetCurve detect: [ :entry | entry first = 1.00 ] ifNone: [ {1.00. 0.0} ]) second.
        at13 := (targetCurve detect: [ :entry | entry first = 1.30 ] ifNone: [ {1.30. 0.0} ]) second.
        Array with: parameter with: (at1 - at13) ].
    ^ impacts asSortedCollection: [ :a :b | a second > b second ]
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepAllTParameters [
	"Return a dictionary of sensitivity curves for all tXxx stages."
	| parameters |
	parameters := #(tDetect tClassify tAlert tAck tHandoff tLaunch).
	^ Dictionary newFromPairs: (parameters flatCollect: [ :parameter |
		{ parameter. (self sweepTParameter: parameter) } ])

]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepAllTParametersTargets [
	"Return one curve per tXxx and per target (90/95/99 by default)."
	^ self sweepAllTParametersTargets: #(90 95 99)
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepAllTParametersTargets: targets [
	| parameters |
	parameters := #(tDetect tClassify tAlert tAck tHandoff tLaunch).
	^ Dictionary newFromPairs: (parameters flatCollect: [ :parameter |
		{ parameter. (self sweepTParameter: parameter targets: targets) } ])

]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepAllTParametersTargets: targets regime: regimeSymbol [
    | parameters |
    parameters := #(tDetect tClassify tAlert tAck tHandoff tLaunch).
    ^ Dictionary newFromPairs: (parameters flatCollect: [ :parameter |
        { parameter. (self sweepTParameter: parameter targets: targets regime: regimeSymbol) } ])
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepKneeDemo95 [
	| sim |
	sim := self new
		model: DroneHandoffModel scenarioKneeDemo;
		sampleCount: 8000;
		initializeRandom;
		yourself.

	^ (220 to: 80 by: -5) collect: [ :speed |
		Array
			with: speed
			with: (sim
				maxDistanceKmForSpeedKmh: speed
				targetOnTimePercent: 95
				sampleCount: 8000) ]
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepKneeDemo95InRegime: regimeSymbol [
    | sim |
    sim := self new
        model: DroneHandoffModel scenarioKneeDemo;
        sampleCount: 8000;
        regime: regimeSymbol;
        initializeRandom;
        yourself.

    ^ (220 to: 80 by: -5) collect: [ :speed |
        Array
            with: speed
            with: (sim
                maxDistanceKmForSpeedKmh: speed
                targetOnTimePercent: 95
                sampleCount: 8000) ]
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepKneeDemoTargets [
	| sim targets |
	sim := self new
		model: DroneHandoffModel scenarioKneeDemo;
		sampleCount: 8000;
		initializeRandom;
		yourself.
	targets := #(90 95 98 99).

	^ targets collect: [ :target |
		Array
			with: target
			with: ((220 to: 80 by: -5) collect: [ :speed |
				Array
					with: speed
					with: (sim
						maxDistanceKmForSpeedKmh: speed
						targetOnTimePercent: target
						sampleCount: 8000) ]) ]
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepKneeDemoTargetsInRegime: regimeSymbol [
    | sim targets |
    sim := self new
        model: DroneHandoffModel scenarioKneeDemo;
        sampleCount: 8000;
        regime: regimeSymbol;
        initializeRandom;
        yourself.
    targets := #(90 95 98 99).

    ^ targets collect: [ :target |
        Array
            with: target
            with: ((220 to: 80 by: -5) collect: [ :speed |
                Array
                    with: speed
                    with: (sim
                        maxDistanceKmForSpeedKmh: speed
                        targetOnTimePercent: target
                        sampleCount: 8000) ]) ]
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepSpeedForMaxDistance [
	| sim |
	sim := self new
		model: DroneHandoffModel scenarioElbow;
		sampleCount: 3000;
		initializeRandom;
		yourself.

	^ (200 to: 100 by: -10) collect: [ :speed |
		Array
			with: speed
			with: (sim
				maxDistanceKmForSpeedKmh: speed
				targetOnTimePercent: 95
				sampleCount: 3000) ]

]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepSpeedForMaxDistanceInRegime: regimeSymbol [
    | sim |
    sim := self new
        model: DroneHandoffModel scenarioElbow;
        sampleCount: 3000;
        regime: regimeSymbol;
        initializeRandom;
        yourself.

    ^ (200 to: 100 by: -10) collect: [ :speed |
        Array
            with: speed
            with: (sim
                maxDistanceKmForSpeedKmh: speed
                targetOnTimePercent: 95
                sampleCount: 3000) ]
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepSpeedForMaxDistanceTargets [
	| sim targets |
	sim := self new
		model: DroneHandoffModel scenarioElbow;
		sampleCount: 3000;
		initializeRandom;
		yourself.
	targets := #(90 95 99).

	^ targets collect: [ :target |
		Array
			with: target
			with: ((200 to: 100 by: -10) collect: [ :speed |
				Array
					with: speed
					with: (sim
						maxDistanceKmForSpeedKmh: speed
						targetOnTimePercent: target
						sampleCount: 3000) ]) ]
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepSpeedForMaxDistanceTargetsInRegime: regimeSymbol [
    | sim targets |
    sim := self new
        model: DroneHandoffModel scenarioElbow;
        sampleCount: 3000;
        regime: regimeSymbol;
        initializeRandom;
        yourself.
    targets := #(90 95 99).

    ^ targets collect: [ :target |
        Array
            with: target
            with: ((200 to: 100 by: -10) collect: [ :speed |
                Array
                    with: speed
                    with: (sim
                        maxDistanceKmForSpeedKmh: speed
                        targetOnTimePercent: target
                        sampleCount: 3000) ]) ]
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepSuccessRateForMaxDistance [
    "Sweep on-time % 98→99.9%, return (percent, maxDistanceKm) pairs."
    | sim |
    sim := self new
        model: DroneHandoffModel scenarioCoastalPatrol;
        sampleCount: 3000;
        initializeRandom;
        yourself.

    ^ (98.0 to: 99.9 by: 0.2) collect: [ :percent |
        Array
            with: percent
            with: (sim
                maxDistanceKmForSpeedKmh: 130
                targetOnTimePercent: percent
                sampleCount: 3000) ]
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepTParameter: parameterSymbol [
	"Sweep one tXxx parameter by multiplicative factor and return (factor, maxDistanceKm) at 95% on-time and 130 km/h."
	| sim baseValue setterSymbol factors curve |
	sim := self new
		model: DroneHandoffModel scenarioKneeDemo;
		sampleCount: 6000;
		initializeRandom;
		yourself.

	baseValue := sim model perform: parameterSymbol.
	setterSymbol := (parameterSymbol asString, ':') asSymbol.
	factors := #(0.60 0.70 0.80 0.90 1.00 1.10 1.20 1.30 1.40 1.50 1.60).

	[
		curve := factors collect: [ :factor |
			sim model perform: setterSymbol with: (baseValue * factor).
			Array
				with: factor
				with: (sim
					maxDistanceKmForSpeedKmh: 130
					targetOnTimePercent: 95
					sampleCount: 6000) ].
	] ensure: [
		sim model perform: setterSymbol with: baseValue
	].

	^ curve

]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepTParameter: parameterSymbol regime: regimeSymbol [
    | sim baseValue setterSymbol factors curve |
    sim := self new
        model: DroneHandoffModel scenarioKneeDemo;
        sampleCount: 6000;
        regime: regimeSymbol;
        initializeRandom;
        yourself.

    baseValue := sim model perform: parameterSymbol.
    setterSymbol := (parameterSymbol asString, ':') asSymbol.
    factors := #(0.60 0.70 0.80 0.90 1.00 1.10 1.20 1.30 1.40 1.50 1.60).

    [
        curve := factors collect: [ :factor |
            sim model perform: setterSymbol with: (baseValue * factor).
            Array
                with: factor
                with: (sim
                    maxDistanceKmForSpeedKmh: 130
                    targetOnTimePercent: 95
                    sampleCount: 6000) ].
    ] ensure: [
        sim model perform: setterSymbol with: baseValue
    ].

    ^ curve
]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepTParameter: parameterSymbol targets: targets [
	"Sweep one tXxx parameter for multiple on-time targets.
	Returns: { targetPercent. { {factor. maxDistanceKm}. ... } }"
	| sim baseValue setterSymbol factors |
	sim := self new
		model: DroneHandoffModel scenarioKneeDemo;
		sampleCount: 6000;
		initializeRandom;
		yourself.

	baseValue := sim model perform: parameterSymbol.
	setterSymbol := (parameterSymbol asString, ':') asSymbol.
	factors := #(0.60 0.70 0.80 0.90 1.00 1.10 1.20 1.30 1.40 1.50 1.60).

	^[
		targets collect: [ :target |
			Array
				with: target
				with: (factors collect: [ :factor |
					sim model perform: setterSymbol with: (baseValue * factor).
					Array
						with: factor
						with: (sim
							maxDistanceKmForSpeedKmh: 130
							targetOnTimePercent: target
							sampleCount: 6000) ]) ]
	] ensure: [
		sim model perform: setterSymbol with: baseValue
	]

]

{ #category : 'sweeping' }
DroneHandoffSimulation class >> sweepTParameter: parameterSymbol targets: targets regime: regimeSymbol [
    | sim baseValue setterSymbol factors |
    sim := self new
        model: DroneHandoffModel scenarioKneeDemo;
        sampleCount: 6000;
        regime: regimeSymbol;
        initializeRandom;
        yourself.

    baseValue := sim model perform: parameterSymbol.
    setterSymbol := (parameterSymbol asString, ':') asSymbol.
    factors := #(0.60 0.70 0.80 0.90 1.00 1.10 1.20 1.30 1.40 1.50 1.60).

    ^[
        targets collect: [ :target |
            Array
                with: target
                with: (factors collect: [ :factor |
                    sim model perform: setterSymbol with: (baseValue * factor).
                    Array
                        with: factor
                        with: (sim
                            maxDistanceKmForSpeedKmh: 130
                            targetOnTimePercent: target
                            sampleCount: 6000) ]) ]
    ] ensure: [
        sim model perform: setterSymbol with: baseValue
    ]
]

{ #category : 'initialization' }
DroneHandoffSimulation >> averageExposureRisk [
    | total |
    results ifEmpty: [ ^ 0.0 ].
    total := results inject: 0.0 into: [ :sum :each | sum + (each at: #exposureRisk ifAbsent: [ 0.0 ]) ].
    ^ total / results size asFloat
]

{ #category : 'initialization' }
DroneHandoffSimulation >> averageRfPingsUsed [

	| total |
	results ifEmpty: [ ^ 0.0 ].
	total := results
		         inject: 0.0
		         into: [ :sum :each |
		         sum + (each at: #rfPingsUsed ifAbsent: [ 0 ]) ].
	^ total / results size asFloat
]

{ #category : 'initialization' }
DroneHandoffSimulation >> defaultStealthPolicy [
    ^ Dictionary new
        at: #rfAllowed put: false;
        at: #rfMaxPings put: 2;
        at: #rfPingSeconds put: 0.10;
        at: #rfAcquireBaseProbability put: 0.45;
        at: #rfAcquireGainPerPing put: 0.20;
        at: #visionFallbackSeconds put: 18.0;
        at: #visionFallbackJitterRatio put: 0.25;
        at: #rfDetectRiskPerPing put: 0.015;
        at: #missionDropProbabilityIfNoAcquire put: 0.25;
        yourself
]

{ #category : 'accessing' }
DroneHandoffSimulation >> evaluatePureVisionVsFurtiveSampleCount: n [
    | oldPolicy visionPolicy furtivePolicy visionMetrics furtiveMetrics |
    oldPolicy := stealthPolicy.
    visionPolicy := self defaultStealthPolicy
        at: #rfAllowed put: false;
        yourself.
    furtivePolicy := self defaultStealthPolicy
        at: #rfAllowed put: true;
        yourself.

    [
        stealthPolicy := visionPolicy.
        visionMetrics := self evaluateRegime: #furtiveHybrid sampleCount: n.
        stealthPolicy := furtivePolicy.
        furtiveMetrics := self evaluateRegime: #furtiveHybrid sampleCount: n.
    ] ensure: [
        stealthPolicy := oldPolicy
    ].

    ^ Dictionary new
        at: #pureVision put: visionMetrics;
        at: #furtiveHybrid put: furtiveMetrics;
        yourself
]

{ #category : 'initialization' }
DroneHandoffSimulation >> evaluateRegime: regimeSymbol sampleCount: n [

	| oldRegime oldSampleCount oldResults metrics |
	oldRegime := self regime.
	oldSampleCount := sampleCount.
	oldResults := results.
	[
		self regime: regimeSymbol.
		sampleCount := n.
		self run.
		metrics := self summaryMetrics ] ensure: [
			self regime: oldRegime.
			sampleCount := oldSampleCount.
			results := oldResults ].
	^ metrics
]

{ #category : 'metrics computations' }
DroneHandoffSimulation >> frontierForTargetOnTimePercent: target distancesKm: distances sampleCount: n [
    "Return a table: for each distance, minimum required speed to reach target on-time %."
    ^ distances collect: [ :d |
        | speed |
        speed := self
            requiredSpeedKmhForDistanceKm: d
            targetOnTimePercent: target
            sampleCount: n.
        Dictionary new
            at: #distanceKm put: d asFloat;
            at: #targetOnTimePercent put: target asFloat;
            at: #requiredSpeedKmh put: speed;
            at: #feasible put: speed notNil;
            yourself ]
]

{ #category : 'initialization' }
DroneHandoffSimulation >> handoffSuccessPercent [
    | okCount |
    results ifEmpty: [ ^ 0.0 ].
    okCount := results count: [ :each | each at: #handoffSuccess ifAbsent: [ true ] ].
    ^ (okCount asFloat / results size asFloat) * 100.0
]

{ #category : 'initialization' }
DroneHandoffSimulation >> initialize [
    super initialize.
    sampleCount := 3000.
    results := #().
    random := Random new.
    regime := #stress.
    stealthPolicy := self defaultStealthPolicy
]

{ #category : 'initialization' }
DroneHandoffSimulation >> initializeDefaults [

	model := DroneHandoffModel default.
	sampleCount := 1000.
	results := #(  )
]

{ #category : 'initialization' }
DroneHandoffSimulation >> initializeRandom [
	random ifNil: [ random := Random new ].
	^ self
]

{ #category : 'default values' }
DroneHandoffSimulation >> maxDistanceKmForSpeedKmh: speedKmh targetOnTimePercent: targetPercent sampleCount: n [
    | low high best mid rate i |
    low := 0.0.
    high := self maxDistanceSearchInitialHighKm.
    best := 0.0.

    "Expand upper bound until infeasible (or safety cap)."
    [ (self onTimeRateForDistanceKm: high speedKmh: speedKmh sampleCount: n) >= targetPercent and: [ high < self maxDistanceSearchUpperCapKm ] ] whileTrue: [
        best := high.
        high := high * self maxDistanceSearchExpandFactor
    ].

    1 to: self maxDistanceSearchIterationCount do: [ :idx |
        i := idx.
        mid := (low + high) / 2.0.
        rate := self onTimeRateForDistanceKm: mid speedKmh: speedKmh sampleCount: n.
        rate >= targetPercent
            ifTrue: [ best := mid. low := mid ]
            ifFalse: [ high := mid ].
        ((high - low) < self maxDistanceSearchToleranceKm and: [ i > self maxDistanceSearchMinIterationsBeforeEarlyStop ]) ifTrue: [ ^ best ]
    ].

    ^ best
]

{ #category : 'default values' }
DroneHandoffSimulation >> maxDistanceSearchExpandFactor [
    "Geometric growth factor for upper bound expansion."
    ^ 1.6
]

{ #category : 'default values' }
DroneHandoffSimulation >> maxDistanceSearchInitialHighKm [
    "Initial upper bound (km) before bracket expansion."
    ^ 120.0
]

{ #category : 'default values' }
DroneHandoffSimulation >> maxDistanceSearchIterationCount [
    "Maximum bisection iterations."
    ^ 28
]

{ #category : 'default values' }
DroneHandoffSimulation >> maxDistanceSearchMinIterationsBeforeEarlyStop [
    "Prevent too-early stop when Monte Carlo noise is high."
    ^ 12
]

{ #category : 'default values' }
DroneHandoffSimulation >> maxDistanceSearchToleranceKm [
    "Convergence tolerance on [low, high] interval width in km."
    ^ 0.01
]

{ #category : 'default values' }
DroneHandoffSimulation >> maxDistanceSearchUpperCapKm [
    "Safety cap for upper bound growth (km)."
    ^ 600.0
]

{ #category : 'initialization' }
DroneHandoffSimulation >> missionContinuityPercent [

	| okCount |
	results ifEmpty: [ ^ 0.0 ].
	okCount := results count: [ :each |
		           each at: #missionContinues ifAbsent: [ true ] ].
	^ okCount asFloat / results size asFloat * 100.0
]

{ #category : 'accessing' }
DroneHandoffSimulation >> model [

	^ model
]

{ #category : 'accessing' }
DroneHandoffSimulation >> model: aValue [

	model := aValue
]

{ #category : 'running' }
DroneHandoffSimulation >> onTimeRate [

	results isEmpty ifTrue: [ ^ 0.0 ].
	^ (results count: [ :each | each at: #onTime ]) asFloat
	  / results size asFloat * 100.0
]

{ #category : 'default values' }
DroneHandoffSimulation >> onTimeRateForDistanceKm: distanceKm speedKmh: speedKmh sampleCount: n [
    | oldDistance oldSpeed oldSampleCount oldResults rate |
    oldDistance := model distanceKm.
    oldSpeed := model speedKmh.
    oldSampleCount := sampleCount.
    oldResults := results.
    [
        model distanceKm: distanceKm.
        model speedKmh: speedKmh.
        sampleCount := n.
        self run.
        rate := self onTimeRatePercent.
    ] ensure: [
        model distanceKm: oldDistance.
        model speedKmh: oldSpeed.
        sampleCount := oldSampleCount.
        results := oldResults.
    ].
    ^ rate
]

{ #category : 'initialization' }
DroneHandoffSimulation >> onTimeRatePercent [
	| onTimeCount |
	results ifEmpty: [ ^ 0.0 ].
	onTimeCount := results count: [ :each | each at: #onTime ].
	^ (onTimeCount asFloat / results size asFloat) * 100.0

]

{ #category : 'running' }
DroneHandoffSimulation >> percentile: p [

	| sorted index |
	sorted := self sortedTotals.
	sorted isEmpty ifTrue: [ ^ 0.0 ].
	index := ((p * sorted size) ceiling max: 1) min: sorted size.
	^ sorted at: index
]

{ #category : 'metrics computations' }
DroneHandoffSimulation >> printFrontierForTargetOnTimePercent: target distancesKm: distances sampleCount: n [
    | table |
    table := self frontierForTargetOnTimePercent: target distancesKm: distances sampleCount: n.
    Transcript
        cr;
        show: '=== Frontier target=', target asString, '% ==='; cr.
    table do: [ :row |
        Transcript
            show: 'd=', (row at: #distanceKm) asString, ' km'
                , '  speed>=',
                ((row at: #requiredSpeedKmh)
                    ifNil: [ 'N/A' ]
                    ifNotNil: [ :v | v printShowingDecimalPlaces: 1 ]),
                ' km/h'
                , '  feasible=', (row at: #feasible) asString;
            cr ].
    Transcript show: '==============================='; cr.
    ^ table
]

{ #category : 'printing' }
DroneHandoffSimulation >> printReport [
    | report |
    report := self summary.
    Transcript
        cr;
        show: '=== Drone Handoff Simulation ==='; cr;
        show: 'Samples   : ', (report at: #sampleCount) asString; cr;
        show: 'P50       : ', ((report at: #p50) printShowingDecimalPlaces: 1), ' s'; cr;
        show: 'P90       : ', ((report at: #p90) printShowingDecimalPlaces: 1), ' s'; cr;
        show: 'P95       : ', ((report at: #p95) printShowingDecimalPlaces: 1), ' s'; cr;
        show: 'On time   : ', ((report at: #onTimeRate) printShowingDecimalPlaces: 1), ' %'; cr;
        show: '==============================='; cr
]

{ #category : 'initialization' }
DroneHandoffSimulation >> publicationComparisonExample [
    | sim |
    sim := self new
        model: DroneHandoffModel scenarioKneeDemo;
        sampleCount: 10000;
        regime: #furtiveHybrid;
        initializeRandom;
        yourself.
    ^ sim evaluatePureVisionVsFurtiveSampleCount: 10000
]

{ #category : 'accessing' }
DroneHandoffSimulation >> random [

	^ random
]

{ #category : 'accessing' }
DroneHandoffSimulation >> random: anObject [

	random := anObject
]

{ #category : 'accessing' }
DroneHandoffSimulation >> randomFactorAroundOne: ratio [
	^ 1.0 + (((random next * 2.0) - 1.0) * ratio)
]

{ #category : 'accessing' }
DroneHandoffSimulation >> regime [

	^ regime
]

{ #category : 'accessing' }
DroneHandoffSimulation >> regime: anObject [

	regime := anObject
]

{ #category : 'metrics computations' }
DroneHandoffSimulation >> requiredSpeedKmhForDistanceKm: aDistance targetOnTimePercent: target sampleCount: n [
	"Inverse solver:  For this distance, what minimum speed gives at least target success %?
	Uses binary search over speed.
	Returns nil if target is unreachable even at upper speed bound"

	| low high mid rate |
	low := 30.0.
	high := 600.0.

	"Feasibility quick checks"


	(self
		 onTimeRateForDistanceKm: aDistance
		 speedKmh: high
		 sampleCount: n) < target ifTrue: [ ^ nil ].

	1 to: 20 do: [ :i |
			mid := low + high / 2.0.
			rate := self
				        onTimeRateForDistanceKm: aDistance
				        speedKmh: mid
				        sampleCount: n.
			rate >= target
				ifTrue: [ high := mid ]
				ifFalse: [ low := mid ] ].

	^ high
]

{ #category : 'accessing' }
DroneHandoffSimulation >> results [

	^ results
]

{ #category : 'accessing' }
DroneHandoffSimulation >> results: anObject [

	results := anObject
]

{ #category : 'initialization' }
DroneHandoffSimulation >> run [
	results := (1 to: sampleCount) collect: [ :i | self runOneTrial ].
	^ results
]

{ #category : 'initialization' }
DroneHandoffSimulation >> runOneTrial [

	regime = #baseline ifTrue: [ ^ self runOneTrialBaseline ].
	regime = #stress ifTrue: [ ^ self runOneTrialStress ].
	^ self runOneTrialFurtiveHybrid
]

{ #category : 'running' }
DroneHandoffSimulation >> runOneTrialBaseline [
    | detect classify alert ack handoff launch stageFixedSeconds baseTransitSeconds distancePenaltySeconds randomShockSeconds totalSeconds onTime |

    detect := model tDetect * (self randomFactorAroundOne: 0.12).
    classify := model tClassify * (self randomFactorAroundOne: 0.14).
    alert := model tAlert * (self randomFactorAroundOne: 0.10).
    ack := model tAck * (self randomFactorAroundOne: 0.18).
    handoff := model tHandoff * (self randomFactorAroundOne: 0.18).
    launch := model tLaunch * (self randomFactorAroundOne: 0.15).
    stageFixedSeconds := detect + classify + alert + ack + handoff + launch.

    baseTransitSeconds := (model distanceKm / model speedKmh) * 3600.0.
    baseTransitSeconds := baseTransitSeconds * (self randomFactorAroundOne: 0.12).

    distancePenaltySeconds := (model distanceKm squared) * 0.05.

    randomShockSeconds := 0.0.
    (random next < 0.03) ifTrue: [
        randomShockSeconds := 10 + (random next * 40)
    ].

    totalSeconds := stageFixedSeconds + baseTransitSeconds + distancePenaltySeconds + randomShockSeconds.
    onTime := totalSeconds <= model slaSeconds.

    ^ Dictionary new
        at: #totalSeconds put: totalSeconds;
        at: #onTime put: onTime;
        yourself
]

{ #category : 'initialization' }
DroneHandoffSimulation >> runOneTrialFurtiveHybrid [

	| detect classify alert ack handoff launch stageFixedSeconds baseTransitSeconds distancePenaltySeconds rfAllowed rfMaxPings rfPingSeconds rfAcquireBase rfAcquireGain rfDetectRiskPerPing visionFallbackSeconds visionFallbackJitter missionDropProbability rfPingsUsed rfAcquireSuccess acquisitionDelaySeconds fallbackDelaySeconds exposureRisk missionContinues handoffSuccess totalSeconds onTime |
	detect := model tDetect * (self randomFactorAroundOne: 0.12).
	classify := model tClassify * (self randomFactorAroundOne: 0.14).
	alert := model tAlert * (self randomFactorAroundOne: 0.10).
	ack := model tAck * (self randomFactorAroundOne: 0.18).
	handoff := model tHandoff * (self randomFactorAroundOne: 0.18).
	launch := model tLaunch * (self randomFactorAroundOne: 0.15).
	stageFixedSeconds := detect + classify + alert + ack + handoff
	                     + launch.

	baseTransitSeconds := model distanceKm / model speedKmh * 3600.0.
	baseTransitSeconds := baseTransitSeconds
	                      * (self randomFactorAroundOne: 0.12).
	distancePenaltySeconds := model distanceKm squared * 0.05.

	rfAllowed := stealthPolicy at: #rfAllowed ifAbsent: [ false ].
	rfMaxPings := stealthPolicy at: #rfMaxPings ifAbsent: [ 2 ].
	rfPingSeconds := stealthPolicy at: #rfPingSeconds ifAbsent: [ 0.10 ].
	rfAcquireBase := stealthPolicy
		                 at: #rfAcquireBaseProbability
		                 ifAbsent: [ 0.45 ].
	rfAcquireGain := stealthPolicy
		                 at: #rfAcquireGainPerPing
		                 ifAbsent: [ 0.20 ].
	rfDetectRiskPerPing := stealthPolicy
		                       at: #rfDetectRiskPerPing
		                       ifAbsent: [ 0.015 ].
	visionFallbackSeconds := stealthPolicy
		                         at: #visionFallbackSeconds
		                         ifAbsent: [ 18.0 ].
	visionFallbackJitter := stealthPolicy
		                        at: #visionFallbackJitterRatio
		                        ifAbsent: [ 0.25 ].
	missionDropProbability := stealthPolicy
		                          at: #missionDropProbabilityIfNoAcquire
		                          ifAbsent: [ 0.25 ].

	rfPingsUsed := 0.
	rfAcquireSuccess := false.
	acquisitionDelaySeconds := 0.0.
	fallbackDelaySeconds := 0.0.

	rfAllowed ifTrue: [
			1 to: rfMaxPings do: [ :index |
					rfAcquireSuccess ifFalse: [
							rfPingsUsed := rfPingsUsed + 1.
							acquisitionDelaySeconds := acquisitionDelaySeconds
							                           + rfPingSeconds.
							random next
							< (rfAcquireBase + (index - 1 * rfAcquireGain) min: 0.98)
								ifTrue: [ rfAcquireSuccess := true ] ] ] ].

	rfAcquireSuccess ifFalse: [
			fallbackDelaySeconds := visionFallbackSeconds
			                        *
			                        (self randomFactorAroundOne:
				                         visionFallbackJitter) ].

	exposureRisk := rfPingsUsed * rfDetectRiskPerPing.
	missionContinues := rfAcquireSuccess or: [
		                    random next >= missionDropProbability ].
	handoffSuccess := rfAcquireSuccess or: [ fallbackDelaySeconds > 0.0 ].

	totalSeconds := stageFixedSeconds + baseTransitSeconds
	                + distancePenaltySeconds + acquisitionDelaySeconds
	                + fallbackDelaySeconds.
	onTime := totalSeconds <= model slaSeconds and: [ missionContinues ].

	^ Dictionary new
		  at: #totalSeconds put: totalSeconds;
		  at: #onTime put: onTime;
		  at: #missionContinues put: missionContinues;
		  at: #handoffSuccess put: handoffSuccess;
		  at: #rfPingsUsed put: rfPingsUsed;
		  at: #exposureRisk put: exposureRisk;
		  yourself
]

{ #category : 'running' }
DroneHandoffSimulation >> runOneTrialStress [
    | detect classify alert ack handoff launch stageFixedSeconds speedNoiseRatio baseTransitSeconds distancePenaltySeconds congestionSeconds overloadSeconds saturationPenaltySeconds burstProbability failureBurstSeconds randomShockSeconds totalSeconds onTime |

    detect := model tDetect * (self randomFactorAroundOne: 0.18).
    classify := model tClassify * (self randomFactorAroundOne: 0.20).
    alert := model tAlert * (self randomFactorAroundOne: 0.15).
    ack := model tAck * (self randomFactorAroundOne: 0.25).
    handoff := model tHandoff * (self randomFactorAroundOne: 0.25).
    launch := model tLaunch * (self randomFactorAroundOne: 0.20).
    stageFixedSeconds := detect + classify + alert + ack + handoff + launch.

    baseTransitSeconds := (model distanceKm / model speedKmh) * 3600.0.
    speedNoiseRatio := 0.14 + ((model distanceKm / 140.0) min: 0.25).
    baseTransitSeconds := baseTransitSeconds * (self randomFactorAroundOne: speedNoiseRatio).

    distancePenaltySeconds := ((model distanceKm squared) * 0.20)
        + (((model distanceKm - 10) max: 0.0) squared * 0.45)
        + ((((model distanceKm - 22) max: 0.0) raisedTo: 3) * 0.06).

    congestionSeconds := 0.0.
    (model distanceKm > 10 and: [ random next < (((model distanceKm - 10) / 70.0) min: 0.80 )]) ifTrue: [
        congestionSeconds := 60 + (random next * 240)
    ].

    overloadSeconds := 0.0 max: ((stageFixedSeconds + baseTransitSeconds) - (model slaSeconds * 0.50)).
    saturationPenaltySeconds := ((overloadSeconds / 10.0) raisedTo: 3) * 5.0.

    burstProbability := (((overloadSeconds / 120.0) + (((model distanceKm - 14) max: 0.0) / 90.0)) min: 0.92).
    failureBurstSeconds := 0.0.
    (random next < burstProbability) ifTrue: [
        failureBurstSeconds := 80 + (random next * 420)
    ].

    randomShockSeconds := 0.0.
    (random next < 0.18) ifTrue: [
        randomShockSeconds := 40 + (random next * 140)
    ].

    totalSeconds := stageFixedSeconds + baseTransitSeconds + distancePenaltySeconds + congestionSeconds + saturationPenaltySeconds + failureBurstSeconds + randomShockSeconds.
    onTime := totalSeconds <= model slaSeconds.

    ^ Dictionary new
        at: #totalSeconds put: totalSeconds;
        at: #onTime put: onTime;
        yourself
]

{ #category : 'accessing' }
DroneHandoffSimulation >> sampleCount [

	^ sampleCount
]

{ #category : 'initialization' }
DroneHandoffSimulation >> sampleCount: anInteger [

	sampleCount := anInteger
]

{ #category : 'running' }
DroneHandoffSimulation >> sortedTotals [
    ^ self totals asSortedCollection
]

{ #category : 'accessing' }
DroneHandoffSimulation >> stealthPolicy [

	^ stealthPolicy
]

{ #category : 'accessing' }
DroneHandoffSimulation >> stealthPolicy: anObject [

	stealthPolicy := anObject
]

{ #category : 'running' }
DroneHandoffSimulation >> summary [

	results isEmpty ifTrue: [ self run ].
	^ Dictionary new
		  at: #sampleCount put: sampleCount;
		  at: #p50 put: (self percentile: 0.50);
		  at: #p90 put: (self percentile: 0.90);
		  at: #p95 put: (self percentile: 0.95);
		  at: #onTimeRate put: self onTimeRate;
		  yourself
]

{ #category : 'initialization' }
DroneHandoffSimulation >> summaryMetrics [

	^ Dictionary new
		  at: #onTimePercent put: self onTimeRatePercent;
		  at: #missionContinuityPercent put: self missionContinuityPercent;
		  at: #handoffSuccessPercent put: self handoffSuccessPercent;
		  at: #averageRfPingsUsed put: self averageRfPingsUsed;
		  at: #averageExposureRisk put: self averageExposureRisk;
		  yourself
]

{ #category : 'running' }
DroneHandoffSimulation >> totals [

	^ results collect: [ :each | each at: #totalSeconds ]
]

{ #category : 'running' }
DroneHandoffSimulation >> vary: aDictionary at: aKey by: ratio [

	| base |
	base := (aDictionary at: aKey) asFloat.
	^ self vary: base by: ratio
]

{ #category : 'running' }
DroneHandoffSimulation >> vary: baseValue by: ratio [

	| factor |
	"Gaussin distribution centered arounf 1"
	factor := 1.0 + (((self random next * 2.0) - 1.0 )* ratio).
	^ baseValue asFloat * factor
]
