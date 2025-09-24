Class {
	#name : 'StrategyEvaluator',
	#superclass : 'Object',
	#category : 'DroneSystem-Eval',
	#package : 'DroneSystem-Eval'
}

{ #category : 'initialization' }
StrategyEvaluator >> computeMetricsFor: aSimulation [
    | allies hostiles allySurvive hostSurvive allyLost hostLost |
    allies := aSimulation allAlliedDrones.
    hostiles := aSimulation allHostileDrones.
    allySurvive := (allies select: [:a | a isDestroyed not]) size.
    hostSurvive := (hostiles select: [:h | h isDestroyed not]) size.
    allyLost := allies size - allySurvive.
    hostLost := hostiles size - hostSurvive.
    ^ Dictionary new
        at: #allySurvivors put: allySurvive;
        at: #hostSurvivors put: hostSurvive;
        at: #allyLost put: allyLost;
        at: #hostLost put: hostLost;
        at: #time put: aSimulation time;
        yourself.

]

{ #category : 'initialization' }
StrategyEvaluator >> evaluate: strategies onSimulation: aSimulation forSteps: steps [
    | results clone metrics |
    results := OrderedCollection new.
    strategies do: [:strat |
        clone := (aSimulation deepCopy) ifFail: [ nil ].
        (clone notNil) ifTrue: [
            clone setAsCurrent.
            strat applyTo: clone.
            1 to: steps do: [:i | clone step ].
            metrics := self computeMetricsFor: clone.
            results add: { strat class name. metrics }.
        ] ifFalse: [
            aSimulation setAsCurrent.
            strat applyTo: aSimulation.
            1 to: steps do: [:i | aSimulation step ].
            metrics := self computeMetricsFor: aSimulation.
            results add: { strat class name, ' (in-place)'. metrics }.
        ].
    ].
    ^ results.

]

{ #category : 'initialization' }
StrategyEvaluator >> exportResultsToCSV: results toFile: filePath [
    | stream |
    stream := WriteStream fileNamed: filePath.
    stream nextPutAll: 'Strategy,AllySurvivors,HostSurvivors,AllyLost,HostLost,Time'; nl.
    results do: [:row |
        | name metrics |
        name := row first.
        metrics := row second.
        stream nextPutAll: (name, ',', (metrics at: #allySurvivors) asString, ',', (metrics at: #hostSurvivors) asString, ',', (metrics at: #allyLost) asString, ',', (metrics at: #hostLost) asString, ',', (metrics at: #time) asString),';
'.
    ].
    stream close.
    ^ self.
]

{ #category : 'initialization' }
StrategyEvaluator >> initialize [
    simulation := nil.
    snapshots := Dictionary new.
    results := OrderedCollection new.
    ^ self.

]

{ #category : 'accessing' }
StrategyEvaluator >> results [

	^ results
]

{ #category : 'accessing' }
StrategyEvaluator >> results: anObject [

	results := anObject
]

{ #category : 'accessing' }
StrategyEvaluator >> simulation [

	^ simulation
]

{ #category : 'accessing' }
StrategyEvaluator >> simulation: anObject [

	simulation := anObject
]

{ #category : 'accessing' }
StrategyEvaluator >> snapshots [

	^ snapshots
]

{ #category : 'accessing' }
StrategyEvaluator >> snapshots: anObject [

	snapshots := anObject
]

{ #category : 'initialization' }
StrategyEvaluator >> visualizeStrategyResults: results [
    | names allyValues hostValues chart |
    names := results collect: [:r | r first].
    allyValues := results collect: [:r | (r second at: #allySurvivors) asNumber ].
    hostValues := results collect: [:r | (r second at: #hostSurvivors) asNumber ].
    chart := RSChart new.
    chart addBarSeries: allyValues label: 'Allied'.
    chart addBarSeries: hostValues label: 'Hostile'.
    chart labels: names.
    chart open.
    ^ self.

]
