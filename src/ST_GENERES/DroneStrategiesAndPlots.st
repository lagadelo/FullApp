"DroneStrategiesAndPlots.st"

"=========================================================="
"  Drone Strategies + StrategyEvaluator enhancements + Plots"
"  - Four ready-to-use strategies
"  - StrategyEvaluator: evaluate multiple strategies and export CSV
"  - visualizeStrategyResults: simple Roassal plots (may require small API tweaks)"
"=========================================================="

"--- Base strategy class ---"
Object subclass: #DroneStrategy
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Strategies'.

DroneStrategy>>applyTo: aSimulation
    "Abstract — subclasses must implement"
    self subclassResponsibility.

"--- Reinforce weakest cluster: move available drones to the cluster with lowest fuel ---"
Object subclass: #ReinforceWeakestClusterStrategy
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Strategies'.

ReinforceWeakestClusterStrategy>>applyTo: aSimulation
    | targetCluster donorDrones |
    targetCluster := (aSimulation allAlliedDrones collect: [:d | d] detect: [:ignored | false] ifNone: [ nil ]). "placeholder guard"
    "Compute cluster with minimum fuel"
    targetCluster := (aSimulation allFleets select: [:f | f isHostile not]) flatCollect: [:f | f clusters] flatten detect: [:ignored | false] ifNone: [ nil ].
    "If we can't compute via above (depends on API), fallback to cluster with min capability"
    targetCluster := (aSimulation clusters first ifNil: [ nil ]).
    targetCluster ifNotNil: [
        "Find donor drones not in target cluster and not destroyed"
        donorDrones := (aSimulation allAlliedDrones select: [:d | (targetCluster drones includes: d) not and: [ d isDestroyed not ] ]).
        donorDrones isEmpty ifFalse: [
            "Send up to 2 donors to reinforce at the cluster center"
            (donorDrones first: (2 min: donorDrones size)) do: [:d |
                d setBehavior: (StaticPositionBehavior new initializeWithLatitude: (targetCluster clusterCenter y) longitude: (targetCluster clusterCenter x) altitude: 100)
            ].
        ].
    ].

"--- Intercept hostiles: dispatch fastest drones to intercept nearest hostiles ---"
Object subclass: #InterceptHostilesStrategy
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Drones-Strategies'.

InterceptHostilesStrategy>>applyTo: aSimulation
    | hostiles allies interceptors |
    hostiles := aSimulation allHostileDrones.
    allies := aSimulation allAlliedDrones.
    hostiles isEmpty ifTrue: [ ^ self ].
    allies isEmpty ifTrue: [ ^ self ].
    "Choose up to N fastest allied drones as interceptors"
    interceptors := (allies asSortedCollection: [:a :b | a speed > b speed]) first: (3 min: allies size).
    interceptors do: [:d |
        d setBehavior: (AttackBehavior new initializeWithWeapon: 'gun' qty: 1 prob: 0.6 impact: 8 targetSelector: [:me | (aSimulation allHostileDrones select: [:h | h isDestroyed not ]) ]) ].

"--- Concentric defense: place drones in rings around a center point ---"
Object subclass: #ConcentricDefenseStrategy
    instanceVariableNames: 'center radiusLayers spacing'
    classVariableNames: ''
    package: 'Drones-Strategies'.

ConcentricDefenseStrategy>>initializeWithCenter: aCenter radiusLayers: layers spacing: s
    center := aCenter. radiusLayers := layers. spacing := s. ^ self.

ConcentricDefenseStrategy>>applyTo: aSimulation
    | allies dronesPerRing i radius drones |
    allies := aSimulation allAlliedDrones.
    allies isEmpty ifTrue: [ ^ self ].
    dronesPerRing := 6.
    1 to: radiusLayers do: [:i |
        radius := spacing * i.
        drones := (allies atLeast: dronesPerRing ifAbsent: [ allies ]).
        1 to: drones size do: [:j |
            | angle lat lon d |
            d := drones at: j.
            angle := (2 * Float pi * (j - 1)) / drones size.
            lat := center x + (radius * (angle cos) * 0.0001).
            lon := center y + (radius * (angle sin) * 0.0001).
            d setBehavior: (StaticPositionBehavior new initializeWithLatitude: lat longitude: lon altitude: 120).
        ].
    ].

"--- Energy saving patrol: alternate active drones to save fuel ---"
Object subclass: #EnergySavingPatrolStrategy
    instanceVariableNames: 'activeRatio'
    classVariableNames: ''
    package: 'Drones-Strategies'.

EnergySavingPatrolStrategy>>initializeWithActiveRatio: ratio
    activeRatio := ratio. ^ self.

EnergySavingPatrolStrategy>>applyTo: aSimulation
    | allies activeCount alliesList |
    alliesList := aSimulation allAlliedDrones.
    alliesList isEmpty ifTrue: [ ^ self ].
    activeCount := (alliesList size * activeRatio) asInteger max: 1.
    alliesList withIndexDo: [:d :i |
        (i <= activeCount)
            ifTrue: [ d setBehavior: (PatrolBehavior new initializeWithWaypoints: { { d latitude . d longitude . d altitude } }) ]
            ifFalse: [ d setBehavior: (StaticPositionBehavior new initializeWithLatitude: d latitude longitude: d longitude altitude: d altitude) ]
    ].

"--- StrategyEvaluator enhancements ---"
StrategyEvaluator compile: '
evaluate: strategies onSimulation: aSimulation forSteps: steps
    "Takes a collection of strategy instances. For each strategy it clones the simulation (if possible), applies the strategy, runs N steps and records metrics."
    | results clone metrics saved |
    results := OrderedCollection new.
    strategies do: [:strat |
        "Attempt to clone the simulation; if not possible, run in place (warning)"
        saved := aSimulation copy ifFail: [ nil ].
        (saved notNil) ifTrue: [
            saved setAsCurrent.
            strat applyTo: saved.
            1 to: steps do: [:i | saved step ].
            metrics := self computeMetricsFor: saved.
            results add: { strat class name. metrics }.
        ] ifFalse: [
            "Fallback: run in place (destructive)"
            aSimulation setAsCurrent.
            strat applyTo: aSimulation.
            1 to: steps do: [:i | aSimulation step ].
            metrics := self computeMetricsFor: aSimulation.
            results add: { strat class name, ' (in-place)'. metrics }.
        ].
    ].
    ^ results.
'.

"CSV export for results"
StrategyEvaluator compile: '
exportResultsToCSV: results toFile: filePath
    | stream |
    stream := FileStream fileNamed: filePath.
    stream nextPutAll: ''Strategy,AllySurvivors,HostSurvivors,AllyLost,HostLost,Time''; nl.
    results do: [:row |
        | name metrics |
        name := row first.
        metrics := row second.
        stream nextPutAll: (name, ' , ', (metrics at: #allySurvivors) asString, ' , ', (metrics at: #hostSurvivors) asString, ' , ', (metrics at: #allyLost) asString, ' , ', (metrics at: #hostLost) asString, ' , ', (metrics at: #time) asString); nl.
    ].
    stream close.
'.

"Visualization of results using Roassal (bar chart)"
StrategyEvaluator compile: '
visualizeStrategyResults: results
    "Simple bar charts for ally survivors and host survivors using Roassal. May need small API tweaks depending on RS version."
    | names allyValues hostValues chart |
    names := results collect: [:r | r first].
    allyValues := results collect: [:r | (r second at: #allySurvivors) asNumber ].
    hostValues := results collect: [:r | (r second at: #hostSurvivors) asNumber ].

    "Build a simple bar chart: x axis = strategy names; two series (ally, host)"
    chart := RSChart new.
    chart addBarSeries: allyValues label: ''Allied''.
    chart addBarSeries: hostValues label: ''Hostile''.
    chart labels: names.
    chart open.
'.

"--- Notes ---"
" - The Roassal plot creation (RSChart) used above is a compact API example; in some Roassal versions the exact selectors differ (RSBarChart / RSBarPlot / RSChart addSeries: / labels:). If Chart creation fails, replace with RSDialog or export CSV and plot externally."
" - The strategy implementations are intentionally straightforward; adapt the heuristics (how many drones to send, selection criteria) to your experiment needs."
" - evaluate:onSimulation:forSteps: tries to copy the simulation before running a strategy. If your SimulationState does not support #copy, it falls back to running in-place and marks the name with ' (in-place)'. Prefer implementing deep copy for robust experiments."
"=========================================================="
" End of file "
"=========================================================="
