Class {
	#name : 'DroneHeuristicDemo',
	#superclass : 'Object',
	#category : 'DroneSystem-Demo',
	#package : 'DroneSystem-Demo'
}

{ #category : 'running' }
DroneHeuristicDemo class >> run [
    ^ self runWithAllies: 10 hostiles: 5 steps: 200.


]

{ #category : 'running' }
DroneHeuristicDemo class >> runWithAllies: nAllies hostiles: nHostiles steps: nSteps [
    "Lance une simulation avec nAllies drones alliés, nHostiles drones hostiles,
    et exécute plusieurs stratégies heuristiques pour comparaison."

    | sim strategies results |

    "1. Créer la simulation"
   " sim := SimulationState new."
    sim addAllies: nAllies.
    sim addHostiles: nHostiles.
    sim assignDefaultMissions.

    "2. Définir les stratégies heuristiques à comparer"
    strategies := {
        ProactiveInterceptionStrategy new.
        AdaptiveEnergyStrategy new.
        DivideAndSurroundStrategy new.
        PriorityDefenseStrategy new.
        LearningBasedStrategy new
    }.

    "3. Évaluer les stratégies sur la simulation"
    results := StrategyEvaluator
        compareStrategies: strategies
        onSimulation: sim
        forSteps: nSteps.

    "4. Exporter les résultats"
    StrategyEvaluator exportResults: results toCSV: 'strategies.csv'.
    StrategyEvaluator visualizeResults: results.
    StrategyEvaluator summarizeResults: results.

    ^ results

]
