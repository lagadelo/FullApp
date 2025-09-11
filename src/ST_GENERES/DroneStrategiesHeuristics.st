"DroneStrategiesHeuristics.st"

"=========================================================="
"  Strategies improvements + File-in helper                "
"  - Corrected file-in helper (FileLocator replaced)      "
"  - Heuristic implementations for strategies             "
"=========================================================="

"----------------------------------------------------------"
" Utility: STFileIn - helper to file-in .st files programmatically"
"----------------------------------------------------------"
Object subclass: #STFileIn
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'System-Tools'.

STFileIn class>>fileInSt: aPath
    "Evaluate the contents of the .st file at aPath (absolute path recommended)."
    (FileStream readOnlyFileNamed: aPath) do: [:stream |
        | contents |
        contents := stream contents.
        Compiler evaluate: contents.
    ].

STFileIn class>>fileInAll: aCollectionOfPaths
    aCollectionOfPaths do: [:p | self fileInSt: p ].

"----------------------------------------------------------"
" Improved strategy heuristics (replace or complement previous strategies)"
"----------------------------------------------------------"

Object subclass: #ReinforceWeakestClusterStrategy
    instanceVariableNames: 'maxReinforcements'
    classVariableNames: ''
    package: 'Drones-Strategies'.

ReinforceWeakestClusterStrategy>>initialize
    maxReinforcements := 2.
    ^ self.

ReinforceWeakestClusterStrategy>>initializeWithMax: n
    maxReinforcements := n.
    ^ self.

ReinforceWeakestClusterStrategy>>applyTo: aSimulation
    "Heuristique : choisir le cluster allié le plus vulnérable (faible carburant moyen ou peu d'unités)
    puis affecter jusqu'à maxReinforcements drones disponibles, choisis selon proximité et réserve en carburant."
    | alliedClusters vulnScores targetCluster donorPool donors centerPt centerLat centerLon |
    alliedClusters := aSimulation allFleets
        select: [:f | f isHostile not ]
        collectMany: [:f | f clusters ].

    alliedClusters isEmpty ifTrue: [ ^ self ].

    "Compute vulnerability score: small avg fuel or few alive drones -> high score"
    vulnScores := alliedClusters collect: [:c |
        | aliveCount totalFuel avgFuel score |
        aliveCount := (c drones select: [:d | d isDestroyed not ]) size.
        totalFuel := (c drones inject: 0 into: [:sum :d | sum + (d fuel ifNil: [0]) ]).
        avgFuel := (aliveCount > 0) ifTrue: [ totalFuel / aliveCount ] ifFalse: [ 0 ].
        "score: prioritize clusters with fewer alive drones and lower average fuel"
        score := (aliveCount = 0) ifTrue: [ 1.0e6 ] ifFalse: [ (1.0 / (avgFuel + 1e-6)) * (1.0 + (1.0 / aliveCount)) ].
        { c . score }
    ].

    "Select cluster with maximal vulnerability score"
    targetCluster := (vulnScores asSortedCollection: [:a :b | (a second) > (b second)]) first first.
    targetCluster ifNil: [ ^ self ].

    "Center of target cluster"
    centerPt := targetCluster clusterCenter ifNil: [ Point x: centerLon y: centerLat ].
    centerLon := centerPt x.
    centerLat := centerPt y.

    "Donor pool: allied drones not in target cluster, not destroyed, with fuel above threshold"
    donorPool := (aSimulation allAlliedDrones select: [:d | (targetCluster drones includes: d) not and: [ d isDestroyed not and: [ d fuel > 30 ] ] ]).
    donorPool isEmpty ifTrue: [ ^ self ].

    "Sort donors by distance to target cluster center (closest first)"
    donors := donorPool asSortedCollection: [:a :b |
        (a distanceToLatitude: centerLat longitude: centerLon altitude: 0)
            < (b distanceToLatitude: centerLat longitude: centerLon altitude: 0)
    ].

    "Assign up to maxReinforcements donors to static positions at the target center"
    (donors first: (maxReinforcements min: donors size)) do: [:d |
        d setBehavior: (StaticPositionBehavior new initializeWithLatitude: centerLat longitude: centerLon altitude: 120).
    ].
    Transcript show: 'ReinforceWeakestClusterStrategy applied to cluster ', (targetCluster clusterId asString), ' donors=', (maxReinforcements min: donors size) asString; cr.
    ^ self.

"----------------------------------------------------------"
" InterceptHostilesStrategy - improved heuristic"
"----------------------------------------------------------"
Object subclass: #InterceptHostilesStrategy
    instanceVariableNames: 'maxInterceptors perHostile fuelReserve'
    classVariableNames: ''
    package: 'Drones-Strategies'.

InterceptHostilesStrategy>>initialize
    maxInterceptors := 3.
    perHostile := 1.
    fuelReserve := 30. "minimum fuel to be considered interceptor"
    ^ self.

InterceptHostilesStrategy>>initializeWithMaxInterceptors: max perHostile: ph fuelReserve: fr
    maxInterceptors := max.
    perHostile := ph.
    fuelReserve := fr.
    ^ self.

InterceptHostilesStrategy>>applyTo: aSimulation
    "Choose interceptors based on estimated interception time (distance / speed) and available fuel."
    | hostiles allies candidates hostSorted selected |
    hostiles := aSimulation allHostileDrones select: [:h | h isDestroyed not ].
    allies := aSimulation allAlliedDrones select: [:d | d isDestroyed not and: [ d fuel > fuelReserve ] ].
    (hostiles isEmpty or: [ allies isEmpty ]) ifTrue: [ ^ self ].

    "For each hostile, pick up to perHostile nearest/fastest allied drones"
    hostiles do: [:h |
        candidates := allies asSortedCollection: [:a :b |
            | ta tb |
            ta := (a distanceToLatitude: h latitude longitude: h longitude altitude: h altitude) / (a speed max: 0.1).
            tb := (b distanceToLatitude: h latitude longitude: h longitude altitude: h altitude) / (b speed max: 0.1).
            ta < tb
        ].

        selected := (candidates first: (perHostile min: candidates size)).
        selected do: [:d |
            "Interception behavior: move towards predicted intercept point (here: hostile current position) and arm attack"
            d setBehavior: (PatrolBehavior new initializeWithWaypoints: { { h latitude . h longitude . h altitude } }).
        ].
    ].
    Transcript show: 'InterceptHostilesStrategy dispatched interceptors for ', hostiles size asString, ' hostiles'; cr.
    ^ self.

"----------------------------------------------------------"
" ConcentricDefenseStrategy - improved placement"
"----------------------------------------------------------"
Object subclass: #ConcentricDefenseStrategy
    instanceVariableNames: 'center radiusLayers spacing dronesPerLayer'
    classVariableNames: ''
    package: 'Drones-Strategies'.

ConcentricDefenseStrategy>>initializeWithCenter: aCenter radiusLayers: layers spacing: s dronesPerLayer: n
    center := aCenter.
    radiusLayers := layers.
    spacing := s.
    dronesPerLayer := n.
    ^ self.

ConcentricDefenseStrategy>>applyTo: aSimulation
    | allies lat0 lon0 layer i angle totalNodes idx drones ringCount |
    allies := aSimulation allAlliedDrones.
    allies isEmpty ifTrue: [ ^ self ].

    "Interpret center: accept Point lat@lon or Array {lat. lon}"
    lat0 := (center isPoint) ifTrue: [ center x ] ifFalse: [ (center at: 1) ].
    lon0 := (center isPoint) ifTrue: [ center y ] ifFalse: [ (center at: 2) ].

    1 to: radiusLayers do: [:i |
        ringCount := dronesPerLayer * i.
        totalNodes := ringCount.
        1 to: totalNodes do: [:idx |
            angle := (2 * Float pi * (idx - 1)) / totalNodes.
            | lat lon d |
            lat := lat0 + ((spacing * i) * (angle cos) * 0.01).
            lon := lon0 + ((spacing * i) * (angle sin) * 0.01).
            d := (allies at: ((idx - 1) \\ allies size) + 1).
            d setBehavior: (StaticPositionBehavior new initializeWithLatitude: lat longitude: lon altitude: 120).
        ].
    ].
    Transcript show: 'ConcentricDefenseStrategy applied with ', radiusLayers asString, ' layers'; cr.
    ^ self.

"----------------------------------------------------------"
" EnergySavingPatrolStrategy - rotate active drones over time"
"----------------------------------------------------------"
Object subclass: #EnergySavingPatrolStrategy
    instanceVariableNames: 'activeRatio cycleLength lastAppliedAt'
    classVariableNames: ''
    package: 'Drones-Strategies'.

EnergySavingPatrolStrategy>>initializeWithActiveRatio: ratio cycleLength: cycles
    activeRatio := ratio.
    cycleLength := cycles.
    lastAppliedAt := nil.
    ^ self.

EnergySavingPatrolStrategy>>applyTo: aSimulation
    "Alternate which drones are active based on the simulation time to save energy."
    | allies activeCount alliesList t offset |
    alliesList := aSimulation allAlliedDrones.
    alliesList isEmpty ifTrue: [ ^ self ].
    t := aSimulation time.
    "Only reassign behaviors when cycle boundary reached"
    (lastAppliedAt notNil and: [ (t - lastAppliedAt) < cycleLength ]) ifTrue: [ ^ self ].
    lastAppliedAt := t.

    activeCount := (alliesList size * activeRatio) asInteger max: 1.
    alliesList withIndexDo: [:d :i |
        (i <= activeCount)
            ifTrue: [ d setBehavior: (PatrolBehavior new initializeWithWaypoints: { { d latitude . d longitude . d altitude } }) ]
            ifFalse: [ d setBehavior: (StaticPositionBehavior new initializeWithLatitude: d latitude longitude: d longitude altitude: d altitude) ]
    ].
    Transcript show: 'EnergySavingPatrolStrategy applied at time ', t asString; cr.
    ^ self.

"----------------------------------------------------------"
" End of heuristics file"
"----------------------------------------------------------"
