

"============================="
"   Drone Heuristic Strategies"
"============================="

Trait << #TDroneStrategy
    traits: {};
    slots: {};
    tag: '';
    package: 'DroneSystem-Heuristics'.

TDroneStrategy >> executeOn: aSimulation
    self subclassResponsibility.


"============================="
"   Proactive Interception"
"============================="

Object << #ProactiveInterceptionStrategy
    uses: TDroneStrategy;
    slots: {};
    package: 'DroneSystem-Heuristics'.

ProactiveInterceptionStrategy >> executeOn: aSimulation
    | hostiles allies |
    hostiles := aSimulation hostiles.
    allies := aSimulation allies.
    hostiles do: [:enemy |
        (allies select: [:d | d canPerceiveDrone: enemy]) do: [:drone |
            drone setBehavior: (GoToHelpBehavior new
                initializeWithPosition: { enemy latitude. enemy longitude. enemy altitude }) ] ].


"============================="
"   Adaptive Energy Saving"
"============================="

Object << #AdaptiveEnergyStrategy
    uses: TDroneStrategy;
    slots: {};
    package: 'DroneSystem-Heuristics'.

AdaptiveEnergyStrategy >> executeOn: aSimulation
    aSimulation allies do: [:drone |
        (drone fuel < 30)
            ifTrue: [ drone setBehavior: (ReturnToBaseBehavior new initializeWithBase: { 48.8566. 2.3522. 0 }) ] ].


"============================="
"   Divide & Surround"
"============================="

Object << #DivideAndSurroundStrategy
    uses: TDroneStrategy;
    slots: {};
    package: 'DroneSystem-Heuristics'.

DivideAndSurroundStrategy >> executeOn: aSimulation
    | hostiles |
    hostiles := aSimulation hostiles.
    hostiles do: [:enemy |
        | formation |
        formation := { 
            { enemy latitude + 0.01. enemy longitude. enemy altitude }.
            { enemy latitude - 0.01. enemy longitude. enemy altitude }.
            { enemy latitude. enemy longitude + 0.01. enemy altitude }.
            { enemy latitude. enemy longitude - 0.01. enemy altitude } }.
        (aSimulation allies first: (formation size min: aSimulation allies size)) 
            with: formation do: [:drone :pos |
                drone setBehavior: (GoToHelpBehavior new initializeWithPosition: pos) ] ].


"============================="
"   Priority Defense"
"============================="

Object << #PriorityDefenseStrategy
    uses: TDroneStrategy;
    slots: {};
    package: 'DroneSystem-Heuristics'.

PriorityDefenseStrategy >> executeOn: aSimulation
    | critical |
    critical := aSimulation clusters collect: [:c | c clusterCenter ].
    aSimulation allies do: [:drone |
        | target |
        target := critical detectMin: [:center | 
            (drone distanceToLatitude: center y longitude: center x altitude: 0) ].
        drone setBehavior: (StaticPositionBehavior new
            initializeWithLatitude: target y longitude: target x altitude: 100) ].


"============================="
"   Learning-based (placeholder)"
"============================="

Object << #LearningBasedStrategy
    uses: TDroneStrategy;
    slots: {};
    package: 'DroneSystem-Heuristics'.

LearningBasedStrategy >> executeOn: aSimulation
    | rand |
    rand := Random new.
    aSimulation allies do: [:drone |
        (rand next < 0.5)
            ifTrue: [ drone setBehavior: (PatrolBehavior new 
                initializeWithWaypoints: { { 48.85. 2.35. 100 }. { 50.11. 8.68. 100 } }) ]
            ifFalse: [ drone setBehavior: (StaticPositionBehavior new 
                initializeWithLatitude: 52.52 longitude: 13.40 altitude: 120) ] ].


"============================="
"   Strategy Evaluator"
"============================="

Object << #StrategyEvaluator
    slots: {};
    package: 'DroneSystem-Heuristics'.

StrategyEvaluator class >> evaluate: aStrategy onSimulation: aSimulation forSteps: n
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

StrategyEvaluator class >> compareStrategies: strategies onSimulation: aSimulation forSteps: n
    | results |
    results := Dictionary new.
    strategies do: [:s |
        results at: s class name put: (self evaluate: s onSimulation: aSimulation forSteps: n) ].
    ^ results.

StrategyEvaluator class >> exportResults: results toCSV: filePath
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

StrategyEvaluator class >> visualizeResults: results
    | view barChart |
    view := RSCanvas new.
    barChart := RSBarPlot new.
    barChart categories: results keys asArray.
    barChart values: (results values collect: [:v | v at: #alliesAlive ]).
    barChart addTo: view.
    view open.

StrategyEvaluator class >> summarizeResults: results
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


"============================="
"   Drone Heuristic Demo"
"============================="

Object subclass: #DroneHeuristicDemo
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'DroneSystem-Demo'.

DroneHeuristicDemo class >> run
    ^ self runWithAllies: 10 hostiles: 5 steps: 200.

DroneHeuristicDemo class >> runWithAllies: nAllies hostiles: nHostiles steps: nSteps
    | sim strategies results |

    sim := DroneSimulation new.
    sim addAllies: nAllies.
    sim addHostiles: nHostiles.
    sim assignDefaultMissions.

    strategies := {
        ProactiveInterceptionStrategy new.
        AdaptiveEnergyStrategy new.
        DivideAndSurroundStrategy new.
        PriorityDefenseStrategy new.
        LearningBasedStrategy new }.

    results := StrategyEvaluator
        compareStrategies: strategies
        onSimulation: sim
        forSteps: nSteps.

    StrategyEvaluator exportResults: results toCSV: 'strategies.csv'.
    StrategyEvaluator visualizeResults: results.
    StrategyEvaluator summarizeResults: results.

    ^ results.


"============================="
"   Drone Heuristic UI"
"============================="

Object subclass: #DroneHeuristicUI
    instanceVariableNames: 'alliesField hostilesField stepsField'
    classVariableNames: ''
    package: 'DroneSystem-UI'.

DroneHeuristicUI class >> open
    ^ self new open.

DroneHeuristicUI >> open
    | builder window runButton |
    builder := SpBoxLayout newVertical.

    builder
        add: (SpLabel new label: 'Allied drones:');
        add: (alliesField := SpTextInputField new text: '10').

    builder
        add: (SpLabel new label: 'Hostile drones:');
        add: (hostilesField := SpTextInputField new text: '5').

    builder
        add: (SpLabel new label: 'Simulation steps:');
        add: (stepsField := SpTextInputField new text: '200').

    runButton := SpButton new
        label: 'Run Simulation';
        action: [ self runSimulation ].

    builder add: runButton.

    window := SpWindow new.
    window title: 'Drone Heuristic Simulator'.
    window add: builder.
    window open.

DroneHeuristicUI >> runSimulation
    | allies hostiles steps results |
    allies := alliesField text asInteger.
    hostiles := hostilesField text asInteger.
    steps := stepsField text asInteger.

    results := DroneHeuristicDemo
        runWithAllies: allies
        hostiles: hostiles
        steps: steps.

    UIManager default inform: 'Simulation finished. Results exported to strategies.csv'.
