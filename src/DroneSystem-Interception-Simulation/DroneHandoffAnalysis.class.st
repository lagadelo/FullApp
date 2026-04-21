Class {
	#name : 'DroneHandoffAnalysis',
	#superclass : 'Object',
	#category : 'DroneSystem-Interception-Simulation',
	#package : 'DroneSystem-Interception-Simulation'
}

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> publicationComparisonExample [
    | sim |
    sim := self
        simulationForScenario: DroneHandoffModel scenarioKneeDemo
        regime: #furtiveHybrid
        sampleCount: 10000.

    ^ sim evaluatePureVisionVsFurtiveSampleCount: 10000
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> rankTParametersByImpact [
    | curves impacts |
    curves := self sweepAllTParameters.

    impacts := curves associations collect: [ :assoc |
        | curve at1 at13 |
        curve := assoc value.

        at1 := (curve
            detect: [ :entry | entry first = 1.00 ]
            ifNone: [ nil ])
                ifNotNil: [ :entry | entry second ]
                ifNil: [ 0.0 ].

        at13 := (curve
            detect: [ :entry | entry first = 1.30 ]
            ifNone: [ nil ])
                ifNotNil: [ :entry | entry second ]
                ifNil: [ 0.0 ].

        Array with: assoc key with: (at1 - at13)
    ].

    ^ impacts asSortedCollection: [ :a :b | a second > b second ]
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> rankTParametersByImpactAtTarget: target [
    ^ self rankTParametersByImpactAtTarget: target regime: #stress
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> rankTParametersByImpactAtTarget: target regime: regimeSymbol [
    | parameters impacts |
    parameters := #(tDetect tClassify tAlert tAck tHandoff tLaunch).

    impacts := parameters collect: [ :parameter |
        | targetCurve at1 at13 |
        targetCurve := (self
            sweepTParameter: parameter
            targets: { target }
            regime: regimeSymbol) first second.

        at1 := (targetCurve
            detect: [ :entry | entry first = 1.00 ]
            ifNone: [ { 1.00. 0.0 } ]) second.

        at13 := (targetCurve
            detect: [ :entry | entry first = 1.30 ]
            ifNone: [ { 1.30. 0.0 } ]) second.

        Array with: parameter with: (at1 - at13)
    ].

    ^ impacts asSortedCollection: [ :a :b | a second > b second ]
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> simulationForScenario: aScenario regime: regimeSymbol sampleCount: anInteger [
    ^ DroneHandoffSimulation new
        model: aScenario;
        sampleCount: anInteger;
        regime: regimeSymbol;
        initializeRandom;
        yourself
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepAllTParameters [
    | parameters |
    parameters := #(tDetect tClassify tAlert tAck tHandoff tLaunch).
    ^ Dictionary newFromPairs: (parameters flatCollect: [ :parameter |
        { parameter. (self sweepTParameter: parameter) } ])
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepAllTParametersTargets [
    ^ self sweepAllTParametersTargets: #(90 95 99) regime: #stress
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepAllTParametersTargets: targets [
    ^ self sweepAllTParametersTargets: targets regime: #stress
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepAllTParametersTargets: targets regime: regimeSymbol [
    | parameters |
    parameters := #(tDetect tClassify tAlert tAck tHandoff tLaunch).
    ^ Dictionary newFromPairs: (parameters flatCollect: [ :parameter |
        { parameter. (self sweepTParameter: parameter targets: targets regime: regimeSymbol) } ])
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepKneeDemo95InRegime: regimeSymbol [
    | sim |
    sim := self
        simulationForScenario: DroneHandoffModel scenarioKneeDemo
        regime: regimeSymbol
        sampleCount: 8000.

    ^ (220 to: 80 by: -5) collect: [ :speed |
        Array
            with: speed
            with: (sim
                maxDistanceKmForSpeedKmh: speed
                targetOnTimePercent: 95
                sampleCount: 8000) ]
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepKneeDemoTargets [
    ^ self sweepKneeDemoTargetsInRegime: #stress
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepSpeedForMaxDistance [
    ^ self sweepSpeedForMaxDistanceInRegime: #stress
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepSpeedForMaxDistanceInRegime: regimeSymbol [
    | sim |
    sim := self
        simulationForScenario: DroneHandoffModel scenarioElbow
        regime: regimeSymbol
        sampleCount: 3000.

    ^ (200 to: 100 by: -10) collect: [ :speed |
        Array
            with: speed
            with: (sim
                maxDistanceKmForSpeedKmh: speed
                targetOnTimePercent: 95
                sampleCount: 3000) ]
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepSpeedForMaxDistanceTargets [
    ^ self sweepSpeedForMaxDistanceTargetsInRegime: #stress
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepSpeedForMaxDistanceTargetsInRegime: regimeSymbol [
    | sim targets |
    sim := self
        simulationForScenario: DroneHandoffModel scenarioElbow
        regime: regimeSymbol
        sampleCount: 3000.

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
DroneHandoffAnalysis class >> sweepTParameter: parameterSymbol [
    ^ self sweepTParameter: parameterSymbol regime: #stress
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepTParameter: parameterSymbol regime: regimeSymbol [
    | sim baseValue setterSymbol factors curve |
    sim := self
        simulationForScenario: DroneHandoffModel scenarioKneeDemo
        regime: regimeSymbol
        sampleCount: 6000.

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
DroneHandoffAnalysis class >> sweepTParameter: parameterSymbol targets: targets [
    ^ self sweepTParameter: parameterSymbol targets: targets regime: #stress
]

{ #category : 'sweeping' }
DroneHandoffAnalysis class >> sweepTParameter: parameterSymbol targets: targets regime: regimeSymbol [
    | sim baseValue setterSymbol factors |
    sim := self
        simulationForScenario: DroneHandoffModel scenarioKneeDemo
        regime: regimeSymbol
        sampleCount: 6000.

    baseValue := sim model perform: parameterSymbol.
    setterSymbol := (parameterSymbol asString, ':') asSymbol.
    factors := #(0.60 0.70 0.80 0.90 1.00 1.10 1.20 1.30 1.40 1.50 1.60).

    ^ [
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
