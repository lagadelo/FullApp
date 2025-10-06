Class {
	#name : 'ScenarioSimulator',
	#superclass : 'Object',
	#instVars : [
		'simulationState',
		'results'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'examples' }
ScenarioSimulator class >> exameple2 [

^DroneSimulator new
    addDrones: (1 to: 20 collect: [:i | Drone new id: i; position: (GeoPoint x: (10 atRandom) y: (10 atRandom)); yourself]);
    setMission: (SurveillanceMission new area: (GeoPoint x: 0 y: 0) extent: 10);
    runFor: 1000.
]

{ #category : 'examples' }
ScenarioSimulator class >> example10 [ 

| simState simulator mission polygon fleet drones cluster1 cluster2
  workPoint tStep enemy enemyPath initialTime   |

"--- 1.  initialisation existant   ---"
simState := SimulationState new.

drones := {
    (Drone new moveToLatitude: 48.8566 longitude: 2.3522 altitude: 100) beAlly ; yourself.   "Paris"
    (Drone new moveToLatitude: 44.8378 longitude: -0.5792 altitude: 120) beAlly ; yourself. "Bordeaux"
    (Drone new moveToLatitude: 45.7640 longitude: 4.8357 altitude: 100) beAlly; yourself. "Lyon"
    (Drone new moveToLatitude: 40.7640 longitude: 2 altitude: 100) beHostile; yourself. "?"
} asOrderedCollection.

cluster1 := DroneCluster new initializeWithDrones: drones clusterId: 1.
cluster2 := DroneCluster example: 20.

fleet := DroneFleet new.
fleet addCluster: cluster1.
fleet addCluster: cluster2.
simState addFleet: fleet.

polygon := {
    {50.6292 . 3.0573  . 100}. "Lille"
    {48.3904 . -4.4947 . 100}. "Brest"
    {43.2965 . 5.3698 . 100}. "Marseille"
    {51.5074 . -0.1276   . 100}. "Londres"
} collect: [:a | GeoPoint with: a ].

mission := (SecurizationMission new polygon: polygon) assignToCluster: cluster1.
"mission connaît les waypoints, cluster1 mission: mission"

"--- 2. Créer le simulateur et configurer la granularité temporelle ---"
"J'utilise ici DroneSimulator qui manipule la file d'événements et un timeStep."
simulator := DroneSimulator new initializeWithState: simState.
simulator timeStep: 1. "1 unité de temps par step (ajuste si besoin)"

"--- 3. Choisir le point de travail : centroïde du polygone (workPoint) ---"
workPoint := "(mission waypoints inject: (0@0) into: [:acc :pt |
    acc + (pt asPoint)]) / (mission waypoints size)." mission polygon first.
"Si tes waypoints sont GeoPoint, adapte: workPoint := mission waypoints collect: [ :wp | wp asPoint ] etc."

"--- 4. Planifier pour chaque drone un MoveStepEvent vers workPoint ---"
initialTime := "simulator now"0. "probablement 0"

cluster1 drones do: [:drone |
    | ev |
   
     
    "Optionnel : définir perceptionRange si non défini"
    drone perceptionRange: (drone perceptionRange ifNil: [ 5.0 ]).

    ev := MoveStepEvent new
        timestamp: initialTime;
        drone: drone;
        wayPoint: workPoint;
        speed: (drone speed ifNil: [ 5.0 ]);
        yourself.
self halt.
    simulator scheduleEvent: ev after: (Set with: nil "mission"). "Ici il faudra mettre des vrais evenements, avec une mission ou les drones patrouillent donc changent de waypoints en cours de route"
].

"--- 5. Insérer un drone ennemi (hostile) qui traverse la zone ---"
"On crée un ennemi (hostile) et on lui donne une trajectoire qui croisera le polygone"
enemy := (Drone new moveToLatitude: 49.0 longitude: 0.0 altitude: 100) beHostile; yourself.
"ne pas l'ajouter au cluster allié ; il est 'intruder' dans le modèle"
 

fleet addCluster: (DroneCluster new initializeWithDrones: {enemy} clusterId: #Intruder).

"Définir un chemin de traversée (quelques points) — traversée en 1..n steps"
enemyPath := OrderedCollection with: (GeoPoint with: {52.0 . -1.0 . 100})
                              with: (GeoPoint with: {50.0 . 1.0 . 100})
                              with: (GeoPoint with: {48.0 . 2.5 . 100})
                              with: (GeoPoint with: {46.0 . 4.0 . 100}).

"Planifier un MoveStepEvent pour chaque segment de l'ennemi, en commençant à t = 2"
tStep := 2.
enemyPath withIndexDo: [:pt :i |
    | mev |
    mev := MoveStepEvent new
        timestamp: (initialTime + (i * tStep));
        drone: enemy;
        wayPoint: pt  ; "ou pt si GeoPoint compatible"
        speed: 6; "speed de l'ennemi"
        yourself.
    simulator scheduleEvent: mev after: (Set with: nil). "pas de dépendance explicitée"
].

"--- 6. Exécuter la simulation pas à pas et afficher les événements ---"
"On exécute jusqu'à un temps max (ici t = 40) ou jusqu'à vidage de la queue"
[ simulator hasEvents and: [ simulator currentTime <= 40 ] ] whileTrue: [
    simulator step.
    (Delay forMilliseconds: 10) wait. "optionnel, si tu veux voir le Transcript défiler"
].

"--- 7. Après exécution : affichage sommaire ---"
Transcript show: 'Simulation finished at t=', simulator currentTime printString; cr.
simState drones do: [:d | Transcript show: d id printString, ' pos: ', d position printString; cr ].

]

{ #category : 'examples' }
ScenarioSimulator class >> exampleAttackAndRescue [ 
    "Scenario:
    - 10 allied drones on a surveillance mission.
    - 3 hostile drones.
    - One hostile attacks an allied drone.
    - The attacked drone calls for help.
    - The other allied drones dispatch: some strike back, others hold position."

    | alliedDrones hostiles surveillanceMission cluster simulator attackedDrone attackEvent helpEvent strikeMission holdMission strikeDrones holdDrones rescueCluster |

    "Create 10 allied drones"
    alliedDrones := (1 to: 10) collect: [:i |
        Drone new
            id: i;
            position: (GeoPoint latitude: 48.85 + (0.005 * i) longitude: 2.35 altitude: 1000);
            yourself
    ].

    "Surveillance mission for all allied drones"
    surveillanceMission := SurveillanceMission new
        waypoints: {
            Waypoint latitude: 48.85 longitude: 2.35 altitude: 1000.
            Waypoint latitude: 48.86 longitude: 2.36 altitude: 1000.
            Waypoint latitude: 48.87 longitude: 2.35 altitude: 1000.
        };
        yourself.

    cluster := DroneCluster new
        drones: alliedDrones.
    surveillanceMission assignToCluster: cluster.

    "Create 3 hostile drones"
    hostiles := (1 to: 3) collect: [:i |
        Drone new
            id: (100 + i);
            position: (GeoPoint latitude: 48.88 + (0.002 * i) longitude: 2.38 altitude: 1000);
            yourself
    ].
    "Hostile cluster (for completeness, not used in mission assignment here)"
    rescueCluster := DroneCluster new
        drones: hostiles.

    "Initialize simulator with both clusters"
    simulator := DroneSimulator new
        clusters: { cluster. rescueCluster };
        yourself.

    "Choose one allied drone to be attacked"
    attackedDrone := alliedDrones anyOne.

    "Schedule an attack event at step 10"
    attackEvent := AttackBehavior new
        attacker: hostiles first;
        target: attackedDrone;
        yourself.
    simulator scheduleEvent: attackEvent at: 10.

    "Schedule a help request event from the attacked drone at step 11"
    helpEvent := ClusterAlertEvent new
        drone: attackedDrone;
        type: #helpRequest;
        yourself.
    simulator scheduleEvent: helpEvent at: 11.

    "At step 12, split the remaining drones: half strike back, half hold position"
    strikeDrones := (alliedDrones select: [:d | d ~= attackedDrone]) first: 4.
    holdDrones := (alliedDrones select: [:d | d ~= attackedDrone]) allButFirst: 4.

    strikeMission := StrikeMission new
        targets: (hostiles collect: [:h | h position]);
        yourself.
    holdMission := StaticPositionBehavior new
        positions: (holdDrones collect: [:d | d position]);
        yourself.

    "Assign new missions at step 12"
    simulator scheduleEvent: (MissionChangeEvent new
        drones: strikeDrones;
        mission: strikeMission;
        yourself) at: 12.

    simulator scheduleEvent: (MissionChangeEvent new
        drones: holdDrones;
        mission: holdMission;
        yourself) at: 12.

    "Run the simulation for 50 steps"
    1 to: 50 do: [:step | simulator step ].

]

{ #category : 'examples' }
ScenarioSimulator class >> exampleClasses [ 
| simulator polygon target ratios outcome |
simulator := ScenarioSimulator new.

polygon := {
    #(48.85 2.35 200).
    #(48.87 2.36 200).
    #(48.86 2.34 200) } collect:[:a|GeoPoint with: a]..

target := #(48.90 2.31 50).
ratios := #(0.2 0.5 0.8).

outcome := simulator runMixedMissionWithRatios: ratios polygon: polygon target: target.

Transcript show: outcome; cr.
]

{ #category : 'examples' }
ScenarioSimulator class >> exampleEnergyDepletion [ [
    | drones mission cluster simulator |
    drones := (1 to: 6) collect: [:i |
        Drone new
            id: i;
            position: (GeoPoint latitude: 48.85 + (0.01 * i) longitude: 2.35 altitude: 1000);
            energy: 100;
            yourself
    ].

    mission := PatrolMission new
        waypoints: {
            Waypoint latitude: 48.85 longitude: 2.35 altitude: 1000.
            Waypoint latitude: 48.86 longitude: 2.36 altitude: 1000.
        };
        yourself.

    cluster := DroneCluster new
        drones: drones.
    mission assignToCluster: cluster.

    simulator := DroneSimulator new
        clusters: { cluster };
        yourself.

    1 to: 200 do: [:step | simulator step ].
]
]

{ #category : 'examples' }
ScenarioSimulator class >> exampleGlobalConflict [ [
    "Global scenario:
    - Large-scale drone conflict over France.
    - Attackers from Denmark and Poland coordinate a multi-vector assault on Brest.
    - French defenders dynamically intercept, regroup, and manage resources.
    - Both sides use adaptive strategies.
    - Metrics: bombs delivered, attackers lost, defenders lost, breaches, successful interceptions."

    | brestTarget danmarkStart polandStart
      attackerDrones defenderDrones attackerCluster defenderCluster
      simulator maxSteps step
      mainForce decoys mainForcePath decoyPath
      metrics bombsDelivered attackersLost defendersLost breaches interceptions |

    "Define Brest target"
    brestTarget := GeoPoint latitude: 48.3904 longitude: -4.4861 altitude: 1200.

    "Attacker starting points"
    danmarkStart := GeoPoint latitude: 55.6761 longitude: 12.5683 altitude: 1200.
    polandStart := GeoPoint latitude: 52.2297 longitude: 21.0122 altitude: 1200.

    "Create 30 attacker drones (15 from each country)"
    attackerDrones := ((1 to: 15) collect: [:i |
        Drone new
            id: (1000 + i);
            position: danmarkStart;
            ammunition: 1;
            energy: 2000;
            status: #attacker;
            yourself
    ]) , ((1 to: 15) collect: [:i |
        Drone new
            id: (2000 + i);
            position: polandStart;
            ammunition: 1;
            energy: 2000;
            status: #attacker;
            yourself
    ]).

    attackerCluster := DroneCluster new
        drones: attackerDrones;
        responseStrategy: (HybridStrategy new
            strategies: { AllInterceptStrategy new. MaxFuelStrategy new });
        yourself.

    "Create 20 defender drones scattered over France"
    defenderDrones := (1 to: 20) collect: [:i |
        Drone new
            id: (3000 + i);
            position: (GeoPoint latitude: 48.0 + (0.8 atRandom) longitude: 2.0 + (5.0 atRandom) altitude: 1200);
            ammunition: 3;
            energy: 1500;
            status: #defender;
            yourself
    ].
    defenderCluster := DroneCluster new
        drones: defenderDrones;
        responseStrategy: (HybridStrategy new
            strategies: { ClosestDroneInterceptStrategy new. ReinforceWeakestClusterStrategy new });
        yourself.

    "Simulator with both clusters"
    simulator := DroneSimulator new
        clusters: { attackerCluster. defenderCluster };
        yourself.

    "Attackers: coordinated assault (main force and decoys)"
    mainForce := attackerDrones first: 20.
    decoys := attackerDrones allButFirst: 20.

    mainForcePath := {
        GeoPoint latitude: 50.0 longitude: 5.0 altitude: 1200.
        GeoPoint latitude: 48.8 longitude: -1.0 altitude: 1200.
        brestTarget
    }.
    decoyPath := {
        GeoPoint latitude: 48.5 longitude: 7.0 altitude: 1200.
        GeoPoint latitude: 47.5 longitude: 2.0 altitude: 1200.
        GeoPoint latitude: 48.4 longitude: -2.0 altitude: 1200.
        brestTarget
    }.

    mainForce do: [:drone |
        1 to: mainForcePath size - 1 do: [:i |
            simulator scheduleEvent: (MoveToWaypointEvent new
                drone: drone;
                waypoint: (mainForcePath at: i + 1);
                yourself) at: (i * 15).
        ].
    ].
    decoys do: [:drone |
        1 to: decoyPath size - 1 do: [:i |
            simulator scheduleEvent: (MoveToWaypointEvent new
                drone: drone;
                waypoint: (decoyPath at: i + 1);
                yourself) at: (i * 15).
        ].
    ].

    "Metrics initialization"
    metrics := Dictionary new.
    metrics at: #bombsDelivered put: 0.
    metrics at: #attackersLost put: 0.
    metrics at: #defendersLost put: 0.
    metrics at: #breaches put: 0.
    metrics at: #interceptions put: 0.

    maxSteps := 120.
    bombsDelivered := 0.
    attackersLost := 0.
    defendersLost := 0.
    breaches := 0.
    interceptions := 0.

    "Main simulation loop"
    1 to: maxSteps do: [:step |
        "Defenders dynamically intercept closest attackers"
        defenderDrones do: [:def |
            (def status = #defender and: [def ammunition > 0]) ifTrue: [
                | closestAtk |
                closestAtk := attackerDrones
                    select: [:atk | atk status = #attacker ]
                    sort: [:a1 :a2 | (def position distanceTo: a1 position) < (def position distanceTo: a2 position) ].
                closestAtk first ifNotNil: [:atk |
                    (def position distanceTo: atk position < 0.03) ifTrue: [
                        def ammunition: def ammunition - 1.
                        atk status: #lost.
                        attackersLost := attackersLost + 1.
                        interceptions := interceptions + 1.
                    ].
                ].
            ].
        ].

        "Defenders with low resources regroup at Paris"
        defenderDrones do: [:def |
            (def ammunition < 1 or: [def energy < 200]) ifTrue: [
                simulator scheduleEvent: (MoveToWaypointEvent new
                    drone: def;
                    waypoint: (GeoPoint latitude: 48.8566 longitude: 2.3522 altitude: 1200);
                    yourself) at: step + 1.
            ].
        ].

        "Attackers adaptively reroute if defenders are concentrated ahead"
        attackerDrones do: [:atk |
            | nearbyDefenders |
            (atk status = #attacker) ifTrue: [
                nearbyDefenders := defenderDrones select: [:def |
                    def status = #defender and: [
                        atk position distanceTo: def position < 0.05
                    ]
                ].
                (nearbyDefenders notEmpty) ifTrue: [
                    simulator scheduleEvent: (MoveToWaypointEvent new
                        drone: atk;
                        waypoint: (GeoPoint latitude: 48.7 longitude: -2.0 altitude: 1200);
                        yourself) at: step + 1.
                ].
            ].
        ].

        "Bombers reaching Brest"
        attackerDrones do: [:atk |
            (atk status = #attacker and: [
                atk position distanceTo: brestTarget < 0.02
            ]) ifTrue: [
                atk status: #bombed.
                bombsDelivered := bombsDelivered + atk ammunition.
                atk ammunition: 0.
            ].
        ].

        "Simulate energy consumption and losses"
        attackerDrones do: [:atk |
            atk energy: atk energy - 3.
            (atk energy <= 0 and: [atk status = #attacker]) ifTrue: [
                atk status: #lost.
                attackersLost := attackersLost + 1.
            ].
        ].
        defenderDrones do: [:def |
            def energy: def energy - 2.
            (def energy <= 0 and: [def status = #defender]) ifTrue: [
                def status: #lost.
                defendersLost := defendersLost + 1.
            ].
        ].

        "Count breaches (attackers that pass Brest)"
        attackerDrones do: [:atk |
            (atk status = #attacker and: [
                atk position longitude < -4.5
            ]) ifTrue: [
                breaches := breaches + 1.
                atk status: #breached.
            ].
        ].

        simulator step.
    ].

    "Store metrics"
    metrics at: #bombsDelivered put: bombsDelivered.
    metrics at: #attackersLost put: attackersLost.
    metrics at: #defendersLost put: defendersLost.
    metrics at: #breaches put: breaches.
    metrics at: #interceptions put: interceptions.

    "Print metrics"
    Transcript show: 'Global conflict scenario complete. Metrics:'; cr.
    metrics keysAndValuesDo: [:k :v | Transcript show: k asString, ': ', v asString; cr ].
]
]

{ #category : 'examples' }
ScenarioSimulator class >> exampleMassiveIntercept [ [
    | drones hostiles mission cluster simulator |
    drones := (1 to: 10) collect: [:i |
        Drone new
            id: i;
            position: (GeoPoint latitude: 48.85 + (0.01 * i) longitude: 2.35 altitude: 1000);
            yourself
    ].

    hostiles := (1 to: 5) collect: [:i |
        GeoPoint latitude: 48.90 + (0.01 * i) longitude: 2.40 + (0.01 * i) altitude: 1000
    ].

    mission := InterceptHostilesStrategy new
        hostiles: hostiles;
        yourself.

    cluster := DroneCluster new
        drones: drones.
    mission assignToCluster: cluster.

    simulator := DroneSimulator new
        clusters: { cluster };
        yourself.

    1 to: 100 do: [:step | simulator step ].
]
]

{ #category : 'examples' }
ScenarioSimulator class >> exampleMultiCluster [ [
    | clusters simulator drones mission cluster hostiles randomWaypoints |

    "Cluster 1: Surveillance"
    drones := (1 to: 3) collect: [:i |
        Drone new
            id: i;
            position: (GeoPoint latitude: 48.85 + (0.01 * i) longitude: 2.35 altitude: 1000);
            yourself
    ].
    mission := SurveillanceMission new
        waypoints: {
            Waypoint latitude: 48.85 longitude: 2.35 altitude: 1000.
            Waypoint latitude: 48.86 longitude: 2.36 altitude: 1000.
            Waypoint latitude: 48.87 longitude: 2.35 altitude: 1000.
        };
        yourself.
    cluster := DroneCluster new
        drones: drones.
    mission assignToCluster: cluster.

    clusters := { cluster }.

    "Cluster 2: Strike"
    drones := (1 to: 3) collect: [:i |
        Drone new
            id: (10 + i);
            position: (GeoPoint latitude: 48.80 + (0.01 * i) longitude: 2.40 altitude: 1000);
            yourself
    ].
    mission := StrikeMission new
        targets: {
            GeoPoint latitude: 48.90 longitude: 2.45 altitude: 1000.
            GeoPoint latitude: 48.91 longitude: 2.46 altitude: 1000.
        };
        yourself.
    cluster := DroneCluster new
        drones: drones.
    mission assignToCluster: cluster.

    clusters := clusters , { cluster }.

    "Cluster 3: Mixed Securization and Strike"
    drones := (1 to: 3) collect: [:i |
        Drone new
            id: (20 + i);
            position: (GeoPoint latitude: 48.82 + (0.01 * i) longitude: 2.38 altitude: 1000);
            yourself
    ].
    mission := MixedMission new
        missions: {
            SecurizationMission new
                waypoints: {
                    Waypoint latitude: 48.83 longitude: 2.39 altitude: 1000.
                    Waypoint latitude: 48.84 longitude: 2.40 altitude: 1000.
                    Waypoint latitude: 48.85 longitude: 2.41 altitude: 1000.
                };
                yourself.
            StrikeMission new
                targets: {
                    GeoPoint latitude: 48.92 longitude: 2.48 altitude: 1000.
                };
                yourself.
        };
        yourself.
    cluster := DroneCluster new
        drones: drones.
    mission assignToCluster: cluster.

    clusters := clusters , { cluster }.

    "Cluster 4: Securization (with 4 points)"
    drones := (1 to: 3) collect: [:i |
        Drone new
            id: (30 + i);
            position: (GeoPoint latitude: 48.81 + (0.01 * i) longitude: 2.37 altitude: 1000);
            yourself
    ].
    mission := SecurizationMission new
        waypoints: {
            Waypoint latitude: 48.82 longitude: 2.38 altitude: 1000.
            Waypoint latitude: 48.83 longitude: 2.39 altitude: 1000.
            Waypoint latitude: 48.84 longitude: 2.40 altitude: 1000.
            Waypoint latitude: 48.85 longitude: 2.41 altitude: 1000.
        };
        yourself.
    cluster := DroneCluster new
        drones: drones.
    mission assignToCluster: cluster.

    clusters := clusters , { cluster }.

    "Cluster 5: Hostile with pseudo-random moves"
    randomWaypoints := (1 to: 6) collect: [:i |
        Waypoint latitude: (48.80 + (0.05 atRandom)) longitude: (2.30 + (0.1 atRandom)) altitude: 1000
    ].
    drones := (1 to: 3) collect: [:i |
        Drone new
            id: (40 + i);
            position: (GeoPoint latitude: 48.80 + (0.01 * i) longitude: 2.30 altitude: 1000);
            yourself
    ].
    mission := SurveillanceMission new
        waypoints: randomWaypoints;
        yourself.
    cluster := DroneCluster new
        drones: drones.
    mission assignToCluster: cluster.

    clusters := clusters , { cluster }.

    "Run the simulation"
    simulator := DroneSimulator new
        clusters: clusters;
        yourself.

    1 to: 200 do: [:step | simulator step ].
]
]

{ #category : 'examples' }
ScenarioSimulator class >> exampleOffensiveStrikeOnBrest [ [
    "Scenario:
    - Attacker's point of view: large hostile drone fleet from Denmark and Poland.
    - Objective: bomb Brest (major military port in western France).
    - France is protected by a defensive drone fleet.
    - Hostile drones must cross France, avoid/intercept defenders, and reach Brest.
    - Metrics: number of bombers reaching Brest, bombs delivered, losses en route."

    | attackerDrones defenderDrones attackerCluster defenderCluster simulator
      brestTarget danmarkStart polandStart attackPaths maxSteps
      bombersAtTarget bombsDelivered attackersLost defendersIntercepted step metrics |

    "Define Brest target (approximate coordinates)"
    brestTarget := GeoPoint latitude: 48.3904 longitude: -4.4861 altitude: 1200.

    "Define starting points for attackers"
    danmarkStart := GeoPoint latitude: 55.6761 longitude: 12.5683 altitude: 1200.  "Copenhagen"
    polandStart := GeoPoint latitude: 52.2297 longitude: 21.0122 altitude: 1200.   "Warsaw"

    "Create 20 attacker drones from Denmark"
    attackerDrones := (1 to: 20) collect: [:i |
        Drone new
            id: (1000 + i);
            position: danmarkStart;
            ammunition: 1;  "One bomb each"
            energy: 2000;
            status: #attacker;
            yourself
    ].

    "Create 20 attacker drones from Poland"
    attackerDrones := attackerDrones , ((1 to: 20) collect: [:i |
        Drone new
            id: (2000 + i);
            position: polandStart;
            ammunition: 1;
            energy: 2000;
            status: #attacker;
            yourself
    ]).

    attackerCluster := DroneCluster new
        drones: attackerDrones.

    "Create 15 defender drones scattered over France"
    defenderDrones := (1 to: 15) collect: [:i |
        Drone new
            id: (3000 + i);
            position: (GeoPoint latitude: 48.0 + (0.8 atRandom) longitude: 2.0 + (5.0 atRandom) altitude: 1200);
            ammunition: 3;
            energy: 1500;
            status: #defender;
            yourself
    ].
    defenderCluster := DroneCluster new
        drones: defenderDrones.

    "Simulator with both clusters"
    simulator := DroneSimulator new
        clusters: { attackerCluster. defenderCluster };
        yourself.

    "Define attack paths: straight lines to Brest"
    attackPaths := attackerDrones collect: [:drone |
        {
            drone position.
            GeoPoint latitude: 50.0 longitude: 5.0 altitude: 1200.  "Belgium/NE France"
            GeoPoint latitude: 48.8 longitude: -1.0 altitude: 1200. "Brittany approach"
            brestTarget
        }
    ].

    "Schedule attacker moves along their paths"
    attackerDrones withIndexDo: [:drone :idx |
        | path |
        path := attackPaths at: idx.
        1 to: path size - 1 do: [:i |
            simulator scheduleEvent: (MoveToWaypointEvent new
                drone: drone;
                waypoint: (path at: i + 1);
                yourself) at: (i * 15).
        ].
    ].

    "Metrics initialization"
    metrics := Dictionary new.
    metrics at: #bombersAtTarget put: 0.
    metrics at: #bombsDelivered put: 0.
    metrics at: #attackersLost put: 0.
    metrics at: #defendersIntercepted put: 0.

    maxSteps := 120.
    bombersAtTarget := 0.
    bombsDelivered := 0.
    attackersLost := 0.
    defendersIntercepted := 0.

    "Main simulation loop"
    1 to: maxSteps do: [:step |
        "Check for engagements: defenders intercept attackers"
        defenderDrones do: [:def |
            (def status = #defender and: [def ammunition > 0]) ifTrue: [
                attackerDrones do: [:atk |
                    (atk status = #attacker and: [
                        def position distanceTo: atk position < 0.03
                    ]) ifTrue: [
                        def ammunition: def ammunition - 1.
                        atk status: #lost.
                        attackersLost := attackersLost + 1.
                        defendersIntercepted := defendersIntercepted + 1.
                    ].
                ].
            ].
        ].

        "Check for bombers reaching Brest"
        attackerDrones do: [:atk |
            (atk status = #attacker and: [
                atk position distanceTo: brestTarget < 0.02
            ]) ifTrue: [
                atk status: #bombed.
                bombersAtTarget := bombersAtTarget + 1.
                bombsDelivered := bombsDelivered + atk ammunition.
                atk ammunition: 0.
            ].
        ].

        "Simulate energy consumption"
        attackerDrones do: [:atk | atk energy: atk energy - 3 ].
        defenderDrones do: [:def | def energy: def energy - 2 ].

        simulator step.
    ].

    "Store metrics"
    metrics at: #bombersAtTarget put: bombersAtTarget.
    metrics at: #bombsDelivered put: bombsDelivered.
    metrics at: #attackersLost put: attackersLost.
    metrics at: #defendersIntercepted put: defendersIntercepted.

    "Print metrics"
    Transcript show: 'Offensive scenario complete. Metrics:'; cr.
    metrics keysAndValuesDo: [:k :v | Transcript show: k asString, ': ', v asString; cr ].
]
]

{ #category : 'examples' }
ScenarioSimulator class >> exampleRealisticFranceEngagement [ [
    "Realistic scenario:
    - 12 allied drones patrol a surveillance zone over France (Paris region).
    - Each drone has limited ammunition and energy.
    - 4 hostile drones enter from the north-east.
    - Hostiles attempt to cross the zone; allies must intercept.
    - Each engagement consumes ammunition.
    - Metrics: number of hostiles intercepted, ammunition spent, drones lost, zone breach events."

    | alliedDrones hostiles surveillanceWaypoints mission cluster hostileCluster simulator
      engagementEvents metrics step maxSteps zoneBreaches interceptedHostiles dronesLost ammoSpent |

    "Define Paris region surveillance waypoints (approximate lat/lon)"
    surveillanceWaypoints := {
        Waypoint latitude: 48.8566 longitude: 2.3522 altitude: 1200.  "Paris center"
        Waypoint latitude: 48.90 longitude: 2.30 altitude: 1200.
        Waypoint latitude: 48.90 longitude: 2.40 altitude: 1200.
        Waypoint latitude: 48.83 longitude: 2.30 altitude: 1200.
        Waypoint latitude: 48.83 longitude: 2.40 altitude: 1200.
        Waypoint latitude: 48.87 longitude: 2.37 altitude: 1200.
        Waypoint latitude: 48.85 longitude: 2.36 altitude: 1200.
    }.

    "Create 12 allied drones with ammo and energy"
    alliedDrones := (1 to: 12) collect: [:i |
        Drone new
            id: i;
            position: (GeoPoint latitude: 48.85 + (0.01 * (i \\ 4)) longitude: 2.35 + (0.01 * (i // 4)) altitude: 1200);
            ammunition: 4;
            energy: 1000;
            status: #active;
            yourself
    ].

    "Allied surveillance mission"
    mission := SurveillanceMission new
        waypoints: surveillanceWaypoints;
        yourself.

    cluster := DroneCluster new
        drones: alliedDrones.
    mission assignToCluster: cluster.

    "Create 4 hostile drones entering from NE"
    hostiles := (1 to: 4) collect: [:i |
        Drone new
            id: (100 + i);
            position: (GeoPoint latitude: 48.92 longitude: 2.45 + (0.01 * i) altitude: 1200);
            ammunition: 2;
            energy: 800;
            status: #hostile;
            yourself
    ].
    hostileCluster := DroneCluster new
        drones: hostiles.

    "Simulator with both clusters"
    simulator := DroneSimulator new
        clusters: { cluster. hostileCluster };
        yourself.

    "Metrics initialization"
    metrics := Dictionary new.
    metrics at: #interceptedHostiles put: 0.
    metrics at: #ammoSpent put: 0.
    metrics at: #dronesLost put: 0.
    metrics at: #zoneBreaches put: 0.

    maxSteps := 100.
    engagementEvents := OrderedCollection new.
    zoneBreaches := 0.
    interceptedHostiles := 0.
    dronesLost := 0.
    ammoSpent := 0.

    "Schedule hostiles to move through the zone"
    hostiles do: [:h |
        | path |
        path := {
            Waypoint latitude: 48.92 longitude: 2.45 altitude: 1200.
            Waypoint latitude: 48.85 longitude: 2.36 altitude: 1200.
            Waypoint latitude: 48.80 longitude: 2.30 altitude: 1200.
        }.
        1 to: path size - 1 do: [:i |
            simulator scheduleEvent: (MoveToWaypointEvent new
                drone: h;
                waypoint: (path at: i + 1);
                yourself) at: (i * 10).
        ].
    ].

    "Main simulation loop"
    1 to: maxSteps do: [:step |
        "Check for possible engagements"
        alliedDrones do: [:ad |
            (ad status = #active and: [ad ammunition > 0]) ifTrue: [
                hostiles do: [:hd |
                    (hd status = #hostile and: [
                        ad position distanceTo: hd position < 0.02
                    ]) ifTrue: [
                        "Engagement: intercept"
                        ad ammunition: ad ammunition - 1.
                        ammoSpent := ammoSpent + 1.
                        hd status: #intercepted.
                        interceptedHostiles := interceptedHostiles + 1.
                        engagementEvents add: {step. ad id. hd id}.
                    ].
                ].
            ].
        ].

        "Check for hostiles breaching the zone"
        hostiles do: [:hd |
            (hd status = #hostile and: [
                hd position latitude < 48.83
            ]) ifTrue: [
                zoneBreaches := zoneBreaches + 1.
                hd status: #breached.
            ].
        ].

        "Check for drones lost (energy depleted)"
        alliedDrones do: [:ad |
            (ad status = #active and: [ad energy <= 0]) ifTrue: [
                ad status: #lost.
                dronesLost := dronesLost + 1.
            ].
        ].

        "Simulate energy consumption"
        alliedDrones do: [:ad | ad energy: ad energy - 2 ].
        hostiles do: [:hd | hd energy: hd energy - 3 ].

        simulator step.
    ].

    "Store metrics"
    metrics at: #interceptedHostiles put: interceptedHostiles.
    metrics at: #ammoSpent put: ammoSpent.
    metrics at: #dronesLost put: dronesLost.
    metrics at: #zoneBreaches put: zoneBreaches.

    "Print metrics"
    Transcript show: 'Simulation complete. Metrics:'; cr.
    metrics keysAndValuesDo: [:k :v | Transcript show: k asString, ': ', v asString; cr ].
]
]

{ #category : 'examples' }
ScenarioSimulator class >> exampleResilienceStrategies [ [
    "Scenario:
    - 20 drones surveil a zone defined by 14 waypoints.
    - If sensing is insufficient, drones can:
      1. Raise detection range (uses more power)
      2. Increase patrol speed to reduce coverage gaps
      3. Regroup at a central or key zone for focused protection
    - Demonstrates resilience strategies in response to mission risk."

    | drones waypoints mission cluster simulator insufficientCoverageEvent regroupEvent alphaTime centralPoint |

    "Create 20 drones with default sensing and energy"
    drones := (1 to: 20) collect: [:i |
        Drone new
            id: i;
            position: (GeoPoint latitude: 48.80 + (0.01 * (i \\ 7)) longitude: 2.30 + (0.01 * (i // 7)) altitude: 1000);
            detectionRange: 100; "default"
            energy: 1000;
            yourself
    ].

    "Define 14 waypoints forming the surveillance zone"
    waypoints := #(
        (48.80 2.30) (48.81 2.31) (48.82 2.32) (48.83 2.33)
        (48.84 2.34) (48.85 2.35) (48.86 2.36) (48.87 2.37)
        (48.88 2.38) (48.89 2.39) (48.88 2.40) (48.87 2.41)
        (48.86 2.42) (48.85 2.43)
    ) collect: [:pair | Waypoint latitude: pair first longitude: pair second altitude: 1000 ].

    "Surveillance mission"
    mission := SurveillanceMission new
        waypoints: waypoints;
        yourself.

    cluster := DroneCluster new
        drones: drones.
    mission assignToCluster: cluster.

    simulator := DroneSimulator new
        clusters: { cluster };
        yourself.

    "Alpha parameter: max allowed time for a gap in coverage"
    alphaTime := 10.

    "Schedule an event at step 15 to simulate insufficient coverage detection"
    insufficientCoverageEvent := DetectionEvent new
        cluster: cluster;
        type: #insufficientCoverage;
        yourself.
    simulator scheduleEvent: insufficientCoverageEvent at: 15.

    "Strategy 1: At step 16, raise detection range (consumes more power)"
    simulator scheduleEvent: (ScheduledEvent new
        action: [ drones do: [:d | d detectionRange: 200. d energy: d energy - 50 ] ];
        yourself) at: 16.

    "Strategy 2: At step 17, increase patrol speed to reduce gap time"
    simulator scheduleEvent: (ScheduledEvent new
        action: [ drones do: [:d | d patrolSpeed: (d patrolSpeed * 1.5) ] ];
        yourself) at: 17.

    "Strategy 3: At step 18, regroup at central point or key zone"
    centralPoint := GeoPoint latitude: 48.85 longitude: 2.36 altitude: 1000.
    regroupEvent := MissionChangeEvent new
        drones: drones;
        mission: (StaticPositionBehavior new positions: { centralPoint }; yourself);
        yourself.
    simulator scheduleEvent: regroupEvent at: 18.

    "Run the simulation for 40 steps"
    1 to: 40 do: [:step | simulator step ].
]
]

{ #category : 'examples' }
ScenarioSimulator class >> exampleStrikeMission [ [
    | clusters simulator |
    clusters := (1 to: 2) collect: [:c |
        | drones mission cluster |
        drones := (1 to: 3) collect: [:i |
            Drone new
                id: (c*10 + i);
                position: (GeoPoint latitude: 48.85 + (0.01 * i) longitude: 2.35 + (0.01 * c) altitude: 1000);
                yourself
        ].
        mission := StrikeMission new
            target: {
                GeoPoint latitude: 48.90 + (0.01 * c) longitude: 2.40 + (0.01 * c) altitude: 1000
            };
            yourself.
        cluster := DroneCluster new
            drones: drones.
        mission assignToCluster: cluster.
        cluster
    ].

    simulator := DroneSimulator new
        clusters: clusters;
        yourself.

    1 to: 150 do: [:step | simulator step ].
]

]

{ #category : 'examples' }
ScenarioSimulator class >> exampleSurveillance [
      | sim     mission polygon     fleet drones cluster1 cluster2 |

    sim := SimulationState new.

    drones := {
        (Drone new moveToLatitude: 48.8566 longitude: 2.3522 altitude: 100) beHostile; yourself.   "Paris"
        (Drone new moveToLatitude: 44.8378 longitude: -0.5792 altitude: 120)beHostile; yourself.   "Bordeaux"
        (Drone new moveToLatitude: 45.7640 longitude: 4.8357 altitude: 100)beHostile; yourself. "Lyon"
    (Drone new moveToLatitude: 40.7640 longitude: 2 altitude: 100)beHostile; yourself. "?"
    } asOrderedCollection.

  
    cluster1 := DroneCluster new initializeWithDrones:  drones clusterId: 1.
cluster2 := DroneCluster example:20.
 

    fleet := DroneFleet new.
fleet addCluster: cluster1.
fleet addCluster: cluster2.
sim addFleet: fleet.
 
    polygon := {
        { 50.6292 . 3.0573  . 100 }. "Lille"
        {48.3904 . -4.4947 . 100 }. "Brest"
        { 43.2965 . 5.3698 . 100 }. "Marseille"
        {51.5074 .-0.1276   . 100 } "Londres"
    } collect:[:a|GeoPoint with: a].

    mission := (SecurizationMission new  polygon: polygon) assignToCluster: cluster1.
    "Crée une mission de surveillance sur un polygone et l’assigne immédiatement au cluster."
    
   
^sim 
"    view := DroneMapWithOWSView new
        initializeWithSimulation: sim
        centerLat: 48.85
        centerLon: 2.35
        zoom: 12.

    view open."

]

{ #category : 'examples' }
ScenarioSimulator class >> exampleSurveillancePatrol [ [
    | drones mission cluster simulator |
    drones := (1 to: 5) collect: [:i |
        Drone new
            id: i;
            position: (GeoPoint latitude: 48.85 + (0.01 * i) longitude: 2.35 altitude: 1000);
            yourself
    ].

    mission := SurveillanceMission new
        waypoints: {
            Waypoint latitude: 48.85 longitude: 2.35 altitude: 1000.
            Waypoint latitude: 48.86 longitude: 2.36 altitude: 1000.
            Waypoint latitude: 48.87 longitude: 2.35 altitude: 1000.
        };
        yourself.

    cluster := DroneCluster new
        drones: drones.
mission assignToCluster: cluster.

    simulator := DroneSimulator new
        clusters: { cluster };
        yourself.

    1 to: 100 do: [:step | simulator step ].
]
]

{ #category : 'executing' }
ScenarioSimulator >> execute [
    self subclassResponsibility.

]

{ #category : 'initialization' }
ScenarioSimulator >> exportResults: results toCSVFile: filePath [
    "results is a collection of Dictionaries with keys #ratio #alliesRemaining #hostilesRemaining #coverageSize"
    | stream |
    stream := FileStream fileNamed: filePath.
    stream nextPutAll: 'ratio,alliesRemaining,hostilesRemaining,coverageSize'; nl.
    results do: [:r |
        | ratio allies hostiles cov |
        ratio := (r at: #ratio) asString.
        allies := (r at: #alliesRemaining) asString.
        hostiles := (r at: #hostilesRemaining) asString.
        cov := (r at: #coverageSize ifAbsent: [ (r at: #coverage ifAbsent: [ '' ]) size asString ]).
        stream nextPutAll: ratio, ',', allies, ',', hostiles, ',', cov; nl.
    ].
    stream close.
    ^ filePath.
]

{ #category : 'initialization' }
ScenarioSimulator >> exportResultsToCSVFile: aFilePath [
    | rows stream |
    rows := self results ifNil: [ ^ self error: 'No results to export' ].
    stream := FileStream fileNamed: aFilePath.
    stream nextPutAll: 'ratio,alliesRemaining,hostilesRemaining,coverageSize'; nl.
    rows do: [:r |
        stream nextPutAll: (String streamContents: [:s |
            s nextPutAll: (r at: #ratio) asString, ','.
            s nextPutAll: (r at: #alliesRemaining) asString, ','.
            s nextPutAll: (r at: #hostilesRemaining) asString, ','.
            s nextPutAll: (r at: #coverageSize ifAbsent: [ (r at: #coverage ifAbsent: [ #() ]) size ]) asString ]).
        stream cr ].
    stream close.
    ^ aFilePath.
]

{ #category : 'initialization' }
ScenarioSimulator >> generateDrones: n prefix: prefix [
    ^ (1 to: n) collect: [:i |
        Drone new
            initializeWithId: (prefix , i asString)
            latitude: 48.85 + (0.01 * i)
            longitude: 2.35 + (0.01 * i)
            altitude: 200
    ].
]

{ #category : 'initialization' }
ScenarioSimulator >> initialize [
"    simulationState := SimulationState new."
    results := OrderedCollection new.
    ^ self.
]

{ #category : 'accessing' }
ScenarioSimulator >> results [

	^ results
]

{ #category : 'accessing' }
ScenarioSimulator >> results: anObject [

	results := anObject
]

{ #category : 'accessing' }
ScenarioSimulator >> rsCircleForDrone: d [
    ^ self rsCircleForDrone: d color: nil.
]

{ #category : 'accessing' }
ScenarioSimulator >> rsCircleForDrone: d color: aColor [
    | x y circle |
    x := d longitude.
    y := d latitude.
    circle := RSEllipse new.
    circle size: 6@6.
    circle translateTo: (x@y).
    aColor ifNotNil: [ circle color: aColor ] ifNil: [ circle color: (d isHostile ifTrue: [ Color red ] ifFalse: [ Color green ]) ].
    circle tooltip: (d uniqueId , ' fuel=' , d fuel asString).
    ^ circle.

]

{ #category : 'initialization' }
ScenarioSimulator >> runMixedMissionWithRatios: ratios polygon: polygon target: target [
     | allyCluster hostileCluster |
self setupBasicScenario.

    ratios do: [:r |
        | mission stateCopy result |
        stateCopy := simulationState deepCopy. "Cloner l’état initial"
        allyCluster := stateCopy allFleets first alliedClusters first..  "récupérer le cluster allié"
        
        mission := ClusterMission
            mixedOn: polygon
            target: target
            ratio: r
            forCluster: allyCluster.
        
        stateCopy runSimulationSteps: 100.
        
        result := Dictionary newFrom: {
            #ratio -> r .
            #alliesRemaining -> (allyCluster drones count: [:d | d isDestroyed not]).
            #hostilesRemaining -> (hostileCluster drones count: [:d | d isDestroyed not]).
            #coverage -> allyCluster coverage }.
        
        results add: result.
    ].

    ^ results.
]

{ #category : 'initialization' }
ScenarioSimulator >> setupBasicScenario [
    "Créer deux flottes : une alliée, une hostile, avec quelques drones"
    
    
    | allyCluster hostileCluster f |

simulationState := SimulationState new. 
allyCluster := DroneCluster new
        initializeWithDrones: (self generateDrones: 10 prefix: 'A')
        clusterId: 1
        hostile: false
        name: 'Allies'.
    
    hostileCluster := DroneCluster new
        initializeWithDrones: (self generateDrones: 8 prefix: 'H')
        clusterId: 2
        hostile: true
        name: 'Hostiles'.
    
	f := DroneFleet new.
	f addCluster:allyCluster.
	f addHostileCluster: hostileCluster.
	simulationState addFleet: f.
 ^ Array with: allyCluster with: hostileCluster .
]

{ #category : 'accessing' }
ScenarioSimulator >> simulationState [

	^ simulationState
]

{ #category : 'accessing' }
ScenarioSimulator >> simulationState: anObject [

	simulationState := anObject
]

{ #category : 'user-interface' }
ScenarioSimulator >> visualizeSimulationOnMap: aState title: aString [
    | canvas group drones latMin latMax lonMin lonMax scaleX scaleY toPoint background |
    canvas := RSCanvas new.

    drones := (aState respondsTo: #drones)
        ifTrue: [ aState drones ]
        ifFalse: [ aState allDrones ].

    "Déterminer bounding box"
    latMin := (drones collect: #latitude) min.
    latMax := (drones collect: #latitude) max.
    lonMin := (drones collect: #longitude) min.
    lonMax := (drones collect: #longitude) max.

    scaleX := 800.   "largeur carte"
    scaleY := 600.   "hauteur carte"

    toPoint := [ :lat :lon |
        ((lon - lonMin) / (lonMax - lonMin + 0.0001) * scaleX) @
        ((latMax - lat) / (latMax - latMin + 0.0001) * scaleY) ].

    "Fond simple"
    background := RSBox new
        size: scaleX@scaleY;
        color: Color veryLightGray;
        yourself.
    canvas add: background.

    "Placer les drones"
    drones do: [:d |
        | c pt |
        pt := toPoint value: d latitude value: d longitude.
        c := RSEllipse new
            size: 8@8;
            translateTo: pt;
            color: (d isHostile ifTrue: [ Color red ] ifFalse: [ Color green ]);
            tooltip: d uniqueId.
        canvas add: c ].

    "Titre et interaction"
    canvas title: (aString ifNil: [ 'Drone Map' ]).
    (canvas shapes) as: RSGroup @ RSDraggable.
    canvas @ RSCanvasController.
    canvas open.

]

{ #category : 'user-interface' }
ScenarioSimulator >> visualizeSimulationOnMapWithOSM: aState title: aString [
    | mapMorph drones polygon coverage polygonOverlay coverageOverlay |

    "Créer la carte centrée sur l’Europe"
    mapMorph := OWSMapMorph new.
    mapMorph extent: 900@700.
    mapMorph center: (OWSLatLon latitude: 48.85 longitude: 2.35).
    mapMorph zoom: 8.

    drones := (aState respondsTo: #drones)
        ifTrue: [ aState drones ]
        ifFalse: [ aState allDrones ].

    "Ajouter les drones comme marqueurs interactifs"
    drones do: [:d |
        | marker color info |
        color := d isHostile
            ifTrue: [ Color red ]
            ifFalse: [ Color green ].

        info := String streamContents: [:s |
            s nextPutAll: 'ID: '; nextPutAll: d uniqueId; cr.
            s nextPutAll: 'Lat: '; nextPutAll: d latitude asString; cr.
            s nextPutAll: 'Lon: '; nextPutAll: d longitude asString; cr.
            s nextPutAll: 'Alt: '; nextPutAll: d altitude asString; cr.
            s nextPutAll: 'Energy: '; nextPutAll: d energy asString; cr.
            s nextPutAll: 'Status: '; nextPutAll: (d isDestroyed ifTrue: [ 'Destroyed' ] ifFalse: [ 'Active' ]) ].

        marker := OWSMarker new
            position: (OWSLatLon latitude: d latitude longitude: d longitude);
            label: d uniqueId;
            color: color;
            onClick: [ UIManager default inform: info ];
            yourself.

        mapMorph addMarker: marker
    ].

    "Ajouter la zone de mission si elle existe"
    (aState respondsTo: #fleets) ifTrue: [
        aState fleets do: [:fleet |
            fleet currentMission ifNotNil: [:mission |
                (mission zoneParameters includesKey: #polygon) ifTrue: [
                    polygon := mission zoneParameters at: #polygon.
                    polygonOverlay := OWSPolygon new.
                    polygon do: [:pt |
                        polygonOverlay addPoint: (OWSLatLon latitude: (pt at: 1) longitude: (pt at: 2)) ].
                    polygonOverlay color: (Color blue alpha: 0.2).
                    polygonOverlay borderColor: Color blue.
                    mapMorph addOverlay: polygonOverlay.
                ].
            ].
        ].
    ].

    "Ajouter la couverture (convex hull)"
    (aState respondsTo: #fleets) ifTrue: [
        aState fleets do: [:fleet |
            fleet coverage ifNotNil: [:cov |
                (cov isEmpty) ifFalse: [
                    coverageOverlay := OWSPolygon new.
                    cov do: [:pt |
                        coverageOverlay addPoint: (OWSLatLon latitude: (pt at: 1) longitude: (pt at: 2)) ].
                    coverageOverlay color: (Color green alpha: 0.15).
                    coverageOverlay borderColor: Color darkGreen.
                    mapMorph addOverlay: coverageOverlay.
                ].
            ].
        ].
    ].

    mapMorph openInWindowLabeled: (aString ifNil: [ 'Drone OSM Map' ]).

]

{ #category : 'initialization' }
ScenarioSimulator >> visualizeSimulationState: aState title: aString [
    "Affiche positions drones + coverage polygons pour l'état fourni (DroneSimulation or SimulationState)"
    | canvas group shapes clusters shapesByCluster title|
    (Smalltalk at: #RSCanvas) ifNil: [ 
        self error: 'Roassal3 not loaded. Load Roassal3 before calling visualizeSimulationState:' ].

    canvas := RSCanvas new.
    shapesByCluster := Dictionary new.

    "Collecter clusters or fallback to top-level drones"
    clusters := (aState respondsTo: #fleets) ifTrue: [ aState fleets ] ifFalse: [ 
        (aState respondsTo: #clusters) ifTrue: [ aState clusters ] ifFalse: [ #() ] ].

    (clusters isEmpty) ifTrue: [
        "No clusters — draw drones from state.drones"
        (aState respondsTo: #drones) ifTrue: [
            aState drones do: [:d |
                | c |
                c := self rsCircleForDrone: d.
                canvas add: c ] ].
    ] ifFalse: [
        clusters do: [:cluster |
            | clusterShapes color |
            color := (cluster respondsTo: #isHostile and: [ cluster isHostile ]) ifTrue: [ Color red ] ifFalse: [ Color green ].
            "draw drones"
            cluster drones do: [:d |
                | s |
                s := self rsCircleForDrone: d color: color.
                canvas add: s.
                (shapesByCluster at: cluster ifAbsentPut: [ OrderedCollection new ]) add: s ].
            "draw coverage polygon if present"
            (cluster coverage notNil and: [ cluster coverage notEmpty ]) ifTrue: [
                | pts edges |
                pts := cluster coverage.
                "create edges between consecutive hull points and close polygon"
                edges := OrderedCollection new.
                1 to: (pts size) do: [:i |
                    | p1 p2 line |
                    p1 := pts at: i.
                    p2 := (i < pts size) ifTrue: [ pts at: i + 1 ] ifFalse: [ pts at: 1 ].
                    line := RSLine new from: ((p1 at: 2) @ (p1 at: 1)) to: ((p2 at: 2) @ (p2 at: 1)).
                    line color: Color gray; dashed.
                    canvas add: line.
                    edges add: line ].
            ]] ].

    "Layout & controller"
    group := (canvas shapes) as: RSGroup.
    RSGridLayout on: group.
    group @ RSDraggable.
    canvas @ RSCanvasController.

    aString ifNil:  [ title := 'Simulation View' ]ifNotNil:[title := aString] .
    canvas title: title.
    canvas open.
    ^ canvas
]
