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

]
