Class {
	#name : 'StrategyEvaluator',
	#superclass : 'Object',
	#category : 'DroneSystem-Heuristics',
	#package : 'DroneSystem-Heuristics'
}

{ #category : 'initialization' }
StrategyEvaluator class >> compareStrategies: strategies onSimulation: sim forSteps: nSteps [
    "Exécute chaque stratégie sur une copie de la simulation et renvoie un dictionnaire
     associant chaque stratégie à ses résultats."

    | results |

    results := Dictionary new.

    strategies do: [:strategy |
        | simCopy score |

        "1. Créer une copie de la simulation pour ne pas polluer les autres stratégies"
        simCopy := sim deepCopy.

        "2. Exécuter la stratégie pendant nSteps"
        score := self evaluate: strategy onSimulation: simCopy forSteps: nSteps.

        "3. Stocker le score dans le dictionnaire"
        results at: strategy class name put: score
    ].

    ^ results

]

{ #category : 'initialization' }
StrategyEvaluator class >> evaluate: aStrategy onSimulation: aSimulation forSteps: n [
    | sim results |
    sim := aSimulation deepCopy.
    aStrategy executeOn: sim.
    sim runWithEvaluations: {} steps: n.
    results := Dictionary new.
    results at: #alliesAlive put: (sim allies count: [:d | d isDestroyed not]).
    results at: #hostilesAlive put: (sim hostiles count: [:d | d isDestroyed not]).
    results at: #fuelRemaining put: (sim allies collect: [:d | d fuel]) average.
    results at: #missionsCompleted put: (sim clusters count: [:c | c currentMission notNil]).
    ^ results.


]

{ #category : 'examples' }
StrategyEvaluator class >> example [


| strategies results sim |

sim := nil.
strategies := {
    ProactiveInterceptionStrategy new.
    AdaptiveEnergyStrategy new.
    DivideAndSurroundStrategy new.
    PriorityDefenseStrategy new.
    LearningBasedStrategy new }.

results := self new
    compareStrategies: strategies
    onSimulation: sim
    forSteps: 200.

Transcript show: results.

]

{ #category : 'initialization' }
StrategyEvaluator class >> exportResults: results toCSV: filePath [
    | stream headers |
    headers := #('Strategy' 'AlliesAlive' 'HostilesAlive' 'FuelRemaining' 'MissionsCompleted').
    stream := FileStream forceNewFileNamed: filePath.
    stream nextPutAll: (headers joinSeparatedBy: ','); cr.
    results keysAndValuesDo: [:k :v |
        stream
            nextPutAll: k asString , ',' ,
                (v at: #alliesAlive) asString , ',' ,
                (v at: #hostilesAlive) asString , ',' ,
                (v at: #fuelRemaining) asString , ',' ,
                (v at: #missionsCompleted) asString; cr ].
    stream close.

]

{ #category : 'initialization' }
StrategyEvaluator class >> summarizeResults: results [
    Transcript show: '--- Résultats comparatifs ---'; cr.
    results keysAndValuesDo: [:name :metrics |
        | allies hostiles fuel missions totalAllies totalHostiles alliesPct hostilesPct missionOK |
        allies := metrics at: #alliesAlive.
        hostiles := metrics at: #hostilesAlive.
        fuel := metrics at: #fuelRemaining.
        missions := metrics at: #missionsCompleted.
        totalAllies := 100 max: (allies + (metrics at: #alliesLost ifAbsent: [0])).
        totalHostiles := 100 max: (hostiles + (metrics at: #hostilesLost ifAbsent: [0])).
        alliesPct := (allies / totalAllies * 100) rounded.
        hostilesPct := (100 - (hostiles / totalHostiles * 100)) rounded.
        missionOK := missions > 0 ifTrue: ['OK'] ifFalse: ['NOK'].
        Transcript
            show: name;
            show: ' : Alliés ', alliesPct asString, '% | Hostiles neutralisés ', hostilesPct asString, '% | Fuel moyen ', fuel asString, ' | Missions ', missionOK;
            cr ].


]

{ #category : 'initialization' }
StrategyEvaluator class >> visualizeResults: results [
    | view barChart |
    view := RSCanvas new.
    barChart := RSBarPlot new.
    barChart categories: results keys asArray.
    barChart values: (results values collect: [:v | v at: #alliesAlive ]).
    barChart addTo: view.
    view open.

]

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
